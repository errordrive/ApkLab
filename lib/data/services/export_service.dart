import 'dart:convert';
import '../../domain/models/project.dart';
import '../../core/utils/formatters.dart';

class ExportService {
  /// Generates machine-readable JSON matching PRD Section 14
  static String exportToJson(ApkProject project) {
    final data = {
      'apk': {
        'name': project.apkInfo.name,
        'package': project.apkInfo.packageName,
        'version': project.apkInfo.versionName,
        'versionCode': project.apkInfo.versionCode,
        'size': project.apkInfo.sizeBytes,
        'sha256': project.sha256Checksum,
        'minSdk': project.apkInfo.minSdk,
        'targetSdk': project.apkInfo.targetSdk,
      },
      'analysis': {
        'classes': project.report.totalClasses,
        'methods': project.report.totalMethods,
        'dexFiles': project.report.totalDexFiles,
        'resources': project.report.totalResources,
        'nativeLibraries': project.report.totalNativeLibs,
        'dialogsDetected': project.report.dialogsDetected,
        'customDialogs': project.report.customDialogs,
        'patchCandidates': project.report.patchCandidates,
        'status': project.report.status,
      },
      'dialogs': project.dialogFindings.map((d) => {
        'id': d.id,
        'class': d.className,
        'parent': d.parentClass,
        'triggeredFrom': d.triggeredFrom,
        'method': d.triggeringMethod,
        'layout': d.layout,
        'confidence': d.confidence.name,
        'detectionLevel': d.detectionLevel,
        'callChain': d.callChain,
      }).toList(),
      'patchCandidates': project.patchCandidates.map((p) => {
        'target': p.targetName,
        'affectedClass': p.affectedClass,
        'confidence': p.detectionConfidence,
        'risk': p.risk,
        'isApplied': p.isApplied,
      }).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Generates a simple text report matching PRD Section 14
  static String exportToTxt(ApkProject project) {
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('             APK ANALYSIS REPORT');
    buffer.writeln('====================================================');
    buffer.writeln('');
    buffer.writeln('APK:            ${project.apkInfo.name}');
    buffer.writeln('Package:        ${project.apkInfo.packageName}');
    buffer.writeln('Version:        ${project.apkInfo.versionName} (${project.apkInfo.versionCode})');
    buffer.writeln('Size:           ${Formatters.formatBytes(project.apkInfo.sizeBytes)}');
    buffer.writeln('SHA-256:        ${project.sha256Checksum}');
    buffer.writeln('Min/Target SDK: ${project.apkInfo.minSdk} / ${project.apkInfo.targetSdk}');
    buffer.writeln('Status:         ${project.report.status}');
    buffer.writeln('');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('METRICS SUMMARY');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('Classes:            ${Formatters.formatNumber(project.report.totalClasses)}');
    buffer.writeln('Methods:            ${Formatters.formatNumber(project.report.totalMethods)}');
    buffer.writeln('DEX Files:          ${project.report.totalDexFiles}');
    buffer.writeln('Resources:          ${Formatters.formatNumber(project.report.totalResources)}');
    buffer.writeln('Native Libraries:   ${project.report.totalNativeLibs}');
    buffer.writeln('Dialogs Detected:   ${project.report.dialogsDetected}');
    buffer.writeln('Custom Dialogs:     ${project.report.customDialogs}');
    buffer.writeln('Patch Candidates:   ${project.report.patchCandidates}');
    buffer.writeln('');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('EXECUTIVE SUMMARY');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln(project.report.executiveSummary);
    buffer.writeln('');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('CUSTOM DIALOG FINDINGS');
    buffer.writeln('----------------------------------------------------');
    for (final d in project.dialogFindings) {
      buffer.writeln('[${d.title}]');
      buffer.writeln('  Class:         ${d.className}');
      buffer.writeln('  Parent:        ${d.parentClass}');
      buffer.writeln('  Trigger:       ${d.triggeredFrom} -> ${d.triggeringMethod}');
      buffer.writeln('  Layout:        ${d.layout}');
      buffer.writeln('  Confidence:    ${d.confidence.name.toUpperCase()}');
      buffer.writeln('  Level:         ${d.detectionLevel}');
      buffer.writeln('  Call Chain:    ${d.callChain.join(' -> ')}');
      buffer.writeln('');
    }
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('PATCH CANDIDATES');
    buffer.writeln('----------------------------------------------------');
    for (final p in project.patchCandidates) {
      buffer.writeln('- ${p.targetName} [${p.risk} RISK]');
      buffer.writeln('  Class:    ${p.affectedClass}');
      buffer.writeln('  Status:   ${p.isApplied ? 'APPLIED' : 'UNAPPLIED'}');
      buffer.writeln('  Details:  ${p.description}');
      buffer.writeln('');
    }
    buffer.writeln('====================================================');
    buffer.writeln('Generated with ApkLab Workstation at ${DateTime.now()}');
    return buffer.toString();
  }

  /// Generates a professional interactive HTML report matching PRD Section 14
  static String exportToHtml(ApkProject project) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ApkLab Report - ${project.apkInfo.name}</title>
  <style>
    body {
      background-color: #0D0F12;
      color: #F2F2F2;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      margin: 0;
      padding: 40px 20px;
    }
    .container {
      max-width: 1000px;
      margin: 0 auto;
    }
    .header {
      border-bottom: 1px solid #282D37;
      padding-bottom: 24px;
      margin-bottom: 32px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .logo {
      font-size: 24px;
      font-weight: bold;
      color: #E4363D;
    }
    .status-badge {
      background-color: #22C55E22;
      color: #22C55E;
      padding: 6px 14px;
      border-radius: 4px;
      font-weight: 600;
      font-size: 13px;
      border: 1px solid #22C55E55;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }
    .card {
      background-color: #1C2026;
      border: 1px solid #282D37;
      border-radius: 8px;
      padding: 20px;
    }
    .card-title {
      font-size: 12px;
      color: #9AA0A6;
      text-transform: uppercase;
      margin-bottom: 8px;
    }
    .card-value {
      font-size: 24px;
      font-weight: bold;
      color: #F2F2F2;
    }
    .section-title {
      font-size: 18px;
      font-weight: 600;
      margin: 32px 0 16px 0;
      border-left: 4px solid #E4363D;
      padding-left: 12px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 12px;
      background-color: #15181D;
      border-radius: 8px;
      overflow: hidden;
      border: 1px solid #282D37;
    }
    th, td {
      padding: 12px 16px;
      text-align: left;
      border-bottom: 1px solid #282D37;
      font-size: 13px;
    }
    th {
      background-color: #1C2026;
      color: #9AA0A6;
      font-weight: 600;
    }
    .call-chain {
      font-family: monospace;
      font-size: 12px;
      color: #61AFEF;
      background-color: #111419;
      padding: 4px 8px;
      border-radius: 4px;
      display: inline-block;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div>
        <div class="logo">⚡ ApkLab Static Analysis Report</div>
        <div style="color: #9AA0A6; font-size: 14px; margin-top: 4px;">Target: ${project.apkInfo.name} (${project.apkInfo.packageName})</div>
      </div>
      <div class="status-badge">STATUS: ${project.report.status}</div>
    </div>

    <div class="grid">
      <div class="card">
        <div class="card-title">Classes</div>
        <div class="card-value">${Formatters.formatNumber(project.report.totalClasses)}</div>
      </div>
      <div class="card">
        <div class="card-title">Methods</div>
        <div class="card-value">${Formatters.formatNumber(project.report.totalMethods)}</div>
      </div>
      <div class="card">
        <div class="card-title">DEX Files</div>
        <div class="card-value">${project.report.totalDexFiles}</div>
      </div>
      <div class="card">
        <div class="card-title">Dialogs Detected</div>
        <div class="card-value">${project.report.dialogsDetected}</div>
      </div>
      <div class="card">
        <div class="card-title">Custom Dialogs</div>
        <div class="card-value">${project.report.customDialogs}</div>
      </div>
      <div class="card">
        <div class="card-title">Patch Candidates</div>
        <div class="card-value">${project.report.patchCandidates}</div>
      </div>
    </div>

    <div class="section-title">Executive Summary</div>
    <div class="card" style="line-height: 1.6; color: #D1D5DB;">
      ${project.report.executiveSummary}
    </div>

    <div class="section-title">Detected Custom Dialogs</div>
    <table>
      <thead>
        <tr>
          <th>Finding</th>
          <th>Class</th>
          <th>Trigger Source</th>
          <th>Detection Level</th>
          <th>Confidence</th>
          <th>Call Chain</th>
        </tr>
      </thead>
      <tbody>
        ${project.dialogFindings.map((d) => '''
        <tr>
          <td><strong>${d.title}</strong></td>
          <td><code>${d.className}</code></td>
          <td>${d.triggeredFrom}.${d.triggeringMethod}</td>
          <td>${d.detectionLevel}</td>
          <td><span style="color: #22C55E; font-weight: 600;">${d.confidence.name.toUpperCase()}</span></td>
          <td><span class="call-chain">${d.callChain.join(' &rarr; ')}</span></td>
        </tr>
        ''').join('')}
      </tbody>
    </table>

    <div class="section-title">Potential Patch Candidates</div>
    <table>
      <thead>
        <tr>
          <th>Target</th>
          <th>Affected Class</th>
          <th>Risk</th>
          <th>Status</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        ${project.patchCandidates.map((p) => '''
        <tr>
          <td><strong>${p.targetName}</strong></td>
          <td><code>${p.affectedClass}</code></td>
          <td><span style="color: ${p.risk == 'HIGH' ? '#E4363D' : (p.risk == 'MEDIUM' ? '#EAB308' : '#22C55E')}; font-weight: 600;">${p.risk}</span></td>
          <td>${p.isApplied ? '<span style="color: #22C55E;">APPLIED</span>' : 'AVAILABLE'}</td>
          <td>${p.description}</td>
        </tr>
        ''').join('')}
      </tbody>
    </table>
    
    <div style="margin-top: 48px; text-align: center; color: #9AA0A6; font-size: 12px;">
      Report generated automatically by ApkLab Workstation &bull; ${DateTime.now().toIso8601String()}
    </div>
  </div>
</body>
</html>''';
  }
}
