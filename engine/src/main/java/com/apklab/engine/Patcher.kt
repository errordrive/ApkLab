package com.apklab.engine

import org.jf.dexlib2.DexFileFactory
import org.jf.dexlib2.Opcode
import org.jf.dexlib2.iface.ClassDef
import org.jf.dexlib2.iface.DexFile
import org.jf.dexlib2.iface.Method
import org.jf.dexlib2.iface.instruction.ReferenceInstruction
import org.jf.dexlib2.iface.reference.MethodReference
import org.jf.dexlib2.immutable.ImmutableClassDef
import org.jf.dexlib2.immutable.ImmutableMethod
import org.jf.dexlib2.immutable.ImmutableMethodImplementation
import org.jf.dexlib2.immutable.instruction.ImmutableInstruction10x
import java.io.File

/**
 * Rebuilds a DEX with injected-dialog methods gutted (body -> return-void)
 * and hook invoke instructions replaced with NOP.
 *
 * Returns a [DexFile] view over the original; [writeDex] serializes it via
 * DexPool, which accepts any DexFile implementation (same approach as a
 * baksmali/smali round-trip).
 */
object Patcher {

    /**
     * Rebuilds the dex with [gutTargets] gutted, [hookKeys] nopped globally,
     * and [scopedNops] nopped only inside their specific caller methods.
     *
     * Returns the ORIGINAL [dexFile] instance when nothing changed, so the
     * caller can skip the expensive DexPool rewrite entirely (identity check
     * with ===). This is what makes 100MB+ APKs patchable in reasonable time:
     * only dex files that actually contain targets get rewritten.
     */
    fun patchDex(
        dexFile: DexFile,
        gutTargets: List<MethodTarget>,
        hookKeys: Set<Pair<String, String>>,
        scopedNops: Set<ScopedNop> = emptySet()
    ): DexFile {
        val gutKeys: Set<Triple<String, String, String>> = gutTargets
            .map { Triple(it.declaringClass, it.name, it.descriptor) }
            .toSet()

        if (gutKeys.isEmpty() && hookKeys.isEmpty() && scopedNops.isEmpty()) return dexFile

        var anyChanged = false
        val newClasses: Set<ClassDef> = dexFile.classes.map { classDef ->
            var changed = false
            val newMethods = classDef.methods.map { method ->
                var m = method
                val desc = Detector.methodDescriptor(method)
                if (Triple(classDef.type, method.name, desc) in gutKeys) {
                    m = gutMethod(method)
                    changed = true
                }
                val nopped = nopHooks(m, classDef.type, hookKeys, scopedNops)
                if (nopped !== m) changed = true
                nopped
            }
            if (changed) {
                anyChanged = true
                ImmutableClassDef(
                    classDef.type, classDef.accessFlags, classDef.superclass,
                    classDef.interfaces, classDef.sourceFile, classDef.annotations,
                    classDef.fields, newMethods
                )
            } else {
                classDef
            }
        }.toSet()

        if (!anyChanged) return dexFile

        return object : DexFile {
            override fun getClasses(): Set<ClassDef> = newClasses
            override fun getOpcodes() = dexFile.opcodes
        }
    }

    /** Convenience: derive gut targets + hook keys from detections (single-dex use). */
    fun patchDex(dexFile: DexFile, detections: List<Detection>): DexFile {
        val gut = detections.flatMap { it.methodsToGut }
        val hooks = detections
            .flatMap { d -> d.hookSites.map { it.target.declaringClass to it.target.name } }
            .toSet()
        val scoped = detections.flatMap { it.scopedNops }.toSet()
        return patchDex(dexFile, gut, hooks, scoped)
    }

    fun writeDex(dexFile: DexFile, outFile: File) {
        DexFileFactory.writeDexFile(outFile.absolutePath, dexFile)
    }

    private fun gutMethod(method: Method): Method {
        val impl = ImmutableMethodImplementation(
            method.implementation!!.registerCount,
            listOf(ImmutableInstruction10x(Opcode.RETURN_VOID)),
            emptyList(),
            emptyList()
        )
        return ImmutableMethod(
            method.definingClass, method.name, method.parameters,
            method.returnType, method.accessFlags, method.annotations,
            method.hiddenApiRestrictions, impl
        )
    }

    private fun nopHooks(
        method: Method,
        callerClass: String,
        hookKeys: Set<Pair<String, String>>,
        scopedNops: Set<ScopedNop>
    ): Method {
        val impl = method.implementation ?: return method
        if (hookKeys.isEmpty() && scopedNops.isEmpty()) return method
        val insns = impl.instructions.toList()
        var changed = false
        val newInsns = insns.mapIndexed { i, insn ->
            var out = insn
            if (insn is ReferenceInstruction && insn.reference is MethodReference) {
                val mr = insn.reference as MethodReference
                // Tier A: global hook to a gutted (void) method.
                val globalHit = mr.returnType == "V" &&
                    (mr.definingClass to mr.name) in hookKeys
                // Tier B/C: scoped startup nop — only inside the recorded caller.
                val scopedHit = scopedNops.any {
                    it.callerClass == callerClass && it.callerMethod == method.name &&
                        it.targetClass == mr.definingClass && it.targetMethod == mr.name
                }
                if (globalHit || scopedHit) {
                    val next = insns.getOrNull(i + 1)
                    if (next == null || !next.opcode.name.startsWith("MOVE_RESULT")) {
                        out = ImmutableInstruction10x(Opcode.NOP)
                        changed = true
                    }
                }
            }
            out
        }
        if (!changed) return method
        val newImpl = ImmutableMethodImplementation(
            impl.registerCount, newInsns,
            impl.tryBlocks.toList(), impl.debugItems.toList()
        )
        return ImmutableMethod(
            method.definingClass, method.name, method.parameters,
            method.returnType, method.accessFlags, method.annotations,
            method.hiddenApiRestrictions, newImpl
        )
    }
}
