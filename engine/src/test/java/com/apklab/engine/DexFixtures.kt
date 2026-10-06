package com.apklab.engine

import org.jf.dexlib2.HiddenApiRestriction
import org.jf.dexlib2.Opcode
import org.jf.dexlib2.Opcodes
import org.jf.dexlib2.iface.Annotation
import org.jf.dexlib2.iface.ClassDef
import org.jf.dexlib2.iface.DexFile
import org.jf.dexlib2.iface.instruction.Instruction
import org.jf.dexlib2.immutable.ImmutableClassDef
import org.jf.dexlib2.immutable.ImmutableMethod
import org.jf.dexlib2.immutable.ImmutableMethodImplementation
import org.jf.dexlib2.immutable.ImmutableMethodParameter
import org.jf.dexlib2.immutable.instruction.ImmutableInstruction10x
import org.jf.dexlib2.immutable.instruction.ImmutableInstruction21c
import org.jf.dexlib2.immutable.instruction.ImmutableInstruction35c
import org.jf.dexlib2.immutable.reference.ImmutableMethodReference
import org.jf.dexlib2.immutable.reference.ImmutableStringReference
import org.jf.dexlib2.immutable.reference.ImmutableTypeReference

/**
 * Builds synthetic DEX fixtures as immutable DexFile views — no javac/d8 needed.
 */
object DexFixtures {

    data class TestMethod(
        val name: String,
        val params: List<String> = emptyList(),
        val ret: String = "V",
        val access: Int = 0x9, // public static
        val impl: ImmutableMethodImplementation
    )

    data class TestClass(val type: String, val methods: List<TestMethod>)

    fun implOf(vararg insns: Instruction, regs: Int = 4): ImmutableMethodImplementation =
        ImmutableMethodImplementation(regs, insns.toList(), emptyList(), emptyList())

    fun newInstance(type: String, reg: Int = 0): Instruction =
        ImmutableInstruction21c(Opcode.NEW_INSTANCE, reg, ImmutableTypeReference(type))

    fun checkCast(type: String, reg: Int = 0): Instruction =
        ImmutableInstruction21c(Opcode.CHECK_CAST, reg, ImmutableTypeReference(type))

    fun constString(s: String, reg: Int = 0): Instruction =
        ImmutableInstruction21c(Opcode.CONST_STRING, reg, ImmutableStringReference(s))

    private fun methodRef(
        defCls: String, name: String, ret: String, params: List<String>
    ): ImmutableMethodReference =
        ImmutableMethodReference(
            defCls, name,
            params.map { ImmutableMethodParameter(it, emptySet<Annotation>(), null) },
            ret
        )

    fun invokeStatic(
        defCls: String, name: String, ret: String = "V",
        params: List<String> = emptyList(), reg: Int = 0
    ): Instruction = ImmutableInstruction35c(
        Opcode.INVOKE_STATIC, 1, reg, 0, 0, 0, 0,
        methodRef(defCls, name, ret, params)
    )

    fun invokeVirtual(
        defCls: String, name: String, ret: String = "V",
        params: List<String> = emptyList(), reg: Int = 0
    ): Instruction = ImmutableInstruction35c(
        Opcode.INVOKE_VIRTUAL, 1, reg, 0, 0, 0, 0,
        methodRef(defCls, name, ret, params)
    )

    fun returnVoid(): Instruction = ImmutableInstruction10x(Opcode.RETURN_VOID)

    /** Realistic injected-dialog method body (mirrors the UpdateDialogue pattern). */
    fun evilShowMethod(): TestMethod = TestMethod(
        name = "checkAndShow",
        params = listOf("Landroid/app/Activity;"),
        impl = implOf(
            newInstance("Landroid/app/Dialog;"),
            invokeVirtual("Landroid/app/Dialog;", "show"),
            constString("https://pastebin.com/raw/abc123"),
            checkCast("Ljava/net/HttpURLConnection;"),
            invokeVirtual("Lorg/json/JSONObject;", "optBoolean", "Z", listOf("Ljava/lang/String;")),
            returnVoid()
        )
    )

    /** Plain offline dialog helper — Tier 1 only, no network signals. */
    fun offlineDialogMethod(name: String = "showWelcome"): TestMethod = TestMethod(
        name = name,
        params = listOf("Landroid/app/Activity;"),
        impl = implOf(
            newInstance("Landroid/app/Dialog;"),
            invokeVirtual("Landroid/app/Dialog;", "setContentView", "V", listOf("I")),
            invokeVirtual("Landroid/app/Dialog;", "show"),
            returnVoid()
        )
    )

    /** Offline dialog built via AlertDialog (the pattern from the user's script). */
    fun alertDialogMethod(name: String = "showAlert"): TestMethod = TestMethod(
        name = name,
        params = listOf("Landroid/app/Activity;"),
        impl = implOf(
            newInstance("Landroidx/appcompat/app/AlertDialog;"),
            invokeVirtual("Landroidx/appcompat/app/AlertDialog;", "setTitle", "V", listOf("Ljava/lang/CharSequence;")),
            invokeVirtual("Landroidx/appcompat/app/AlertDialog;", "show"),
            returnVoid()
        )
    )

    /** MainActivity.onCreate that calls a dialog helper (startup hook). */
    fun mainOnCreateCalling(helperCls: String, helperMethod: String): TestMethod = TestMethod(
        name = "onCreate",
        params = listOf("Landroid/os/Bundle;"),
        access = 0x1,
        impl = implOf(
            invokeStatic(helperCls, helperMethod, "V", listOf("Landroid/app/Activity;")),
            returnVoid()
        )
    )

    /** MainActivity.onCreate with an inline dialog (no helper). */
    fun mainOnCreateInlineDialog(): TestMethod = TestMethod(
        name = "onCreate",
        params = listOf("Landroid/os/Bundle;"),
        access = 0x1,
        impl = implOf(
            newInstance("Landroid/app/Dialog;"),
            invokeVirtual("Landroid/app/Dialog;", "setContentView", "V", listOf("I")),
            invokeVirtual("Landroid/app/Dialog;", "show"),
            returnVoid()
        )
    )

    fun buildDex(classes: List<TestClass>): DexFile {
        val classDefs: Set<ClassDef> = classes.map { tc ->
            ImmutableClassDef(
                tc.type, 0x1, "Ljava/lang/Object;", emptyList(),
                null, emptySet<Annotation>(), emptyList(),
                tc.methods.map { tm ->
                    ImmutableMethod(
                        tc.type, tm.name,
                        tm.params.map { ImmutableMethodParameter(it, emptySet<Annotation>(), null) },
                        tm.ret, tm.access,
                        emptySet<Annotation>(),
                        emptySet<HiddenApiRestriction>(),
                        tm.impl
                    )
                }
            )
        }.toSet()
        return object : DexFile {
            override fun getClasses(): Set<ClassDef> = classDefs
            override fun getOpcodes() = Opcodes.getDefault()
        }
    }
}
