# ApkLab

## Product summary
1. Tech Stack

Frontend

Flutter + Dart

Material 3

Responsive UI for phones and tablets

Clean Architecture

BLoC/Riverpod for state management


Native Android Layer

Kotlin

Android SDK

Android NDK where native performance is required

Dart FFI for communication with native C/C++ modules


APK Analysis Engine

JADX — DEX → Java/Kotlin-like source analysis

Baksmali/Smali — DEX ↔ Smali analysis

Custom DEX parser/indexer

APK/ZIP parser

AndroidManifest parser

Resource/ARSC analyzer

String/resource reference analyzer

Class/method/field indexer

Call/reference analysis engine


APK Modification Engine

Smali patching

DEX rebuilding

Resource rebuilding

APK packaging

Zip alignment

APK signing

Integrity verification


Local Storage

SQLite/Drift

Local APK analysis workspace

Project-based storage

Analysis-result caching


Background Processing

Dart Isolates

Kotlin background services

Coroutine-based processing

Cancelable analysis jobs



---

2. App Details

APK Import

The user selects an APK and the application performs a complete analysis pipeline:

APK
 ↓
Validation
 ↓
Extraction
 ↓
Manifest Analysis
 ↓
DEX Analysis
 ↓
JADX Analysis
 ↓
Smali/Baksmali Analysis
 ↓
Resource Analysis
 ↓
String Analysis
 ↓
Class & Method Indexing
 ↓
Dialog Detection
 ↓
Call/Reference Analysis
 ↓
Dependency Analysis
 ↓
Patch Candidate Detection
 ↓
REPORT GENERATED


---

APK Information

Display:

APK name

Package name

Version name

Version code

APK size

Minimum SDK

Target SDK

Compile SDK where detectable

Supported architectures

DEX count

Native libraries

Certificate/signature information

APK signing scheme

Permissions



---

3. APK Analyzer

AndroidManifest Analyzer

Analyze:

Activities

Services

Broadcast Receivers

Content Providers

Permissions

Intent filters

Exported components

Deep links

Metadata

Application configuration

SDK information



---

DEX Analyzer

Analyze:

DEX files

Packages

Classes

Interfaces

Methods

Fields

Strings

Annotations

References

Class hierarchy

Method relationships

Obfuscated identifiers

Potentially interesting code patterns


Example:

classes.dex
 ├── com.example.MainActivity
 ├── com.example.ui.CustomDialog
 ├── com.example.network.ApiManager
 └── com.example.utils.SecurityUtils


---

4. JADX Integration

Provide an integrated JADX-style source explorer.

Features:

Java/Kotlin-like source view

Class browser

Package browser

Method navigation

Field navigation

Search

Find references

Find callers

Find usages

String search

Resource references

Cross-navigation between classes

Source ↔ Smali navigation where possible


Example:

com.example.ui.CustomDialog

class CustomDialog extends Dialog {

    ...
    
    void showWarning() {
        show();
    }
}


---

5. Smali/Baksmali Integration

Provide a Smali explorer with:

DEX → Smali conversion

Syntax highlighting

Line numbers

Method navigation

Search

Instruction search

Cross-reference navigation

Smali patch preview

Before/after comparison


Detect patterns such as:

new-instance
invoke-direct
invoke-virtual
invoke-static
invoke-interface

and Android dialog-related calls such as:

Dialog
AlertDialog
DialogFragment
show()
dismiss()
setContentView()


---

6. Custom Dialog Detection Engine

This will be one of the core features of the application.

The engine should not rely only on exact class-name matching, because APKs may use custom names or obfuscation.

Detection levels

Level 1 — Known Android APIs

Search for known dialog-related classes and APIs:

Landroid/app/Dialog;
Landroid/app/AlertDialog;
Landroid/app/DialogFragment;
Landroidx/appcompat/app/AlertDialog;
Landroidx/fragment/app/DialogFragment;

Also detect relevant methods such as:

show()
dismiss()
setContentView()


---

Level 2 — Class Structure Detection

Identify classes that:

extend Dialog
extend AlertDialog
extend DialogFragment

or implement equivalent custom dialog behavior.


---

Level 3 — Smali Pattern Detection

Detect combinations such as:

new-instance
↓
Dialog constructor
↓
setContentView
↓
show


---

Level 4 — Call Graph Analysis

Trace:

Activity
   ↓
Method
   ↓
Dialog Creation
   ↓
Dialog Configuration
   ↓
Dialog.show()

This helps identify where and why a dialog is displayed.


---

Level 5 — Resource Correlation

Connect:

Dialog Class
      ↕
Layout XML
      ↕
Strings
      ↕
Drawables
      ↕
Activity / Fragment


---

7. Custom Dialog Report

Every detected dialog should generate a detailed finding.

Example:

CUSTOM DIALOG #03

Class:
com.example.popup.CustomWarning

Parent:
android.app.Dialog

Triggered From:
MainActivity

Method:
checkVersion()

Layout:
R.layout.dialog_warning

Show Call:
Dialog.show()

Related Strings:
"Warning"
"Continue"

Confidence:
HIGH

The system should also show:

Source location

DEX file

Class name

Method name

Calling class

Calling method

Dialog layout

Related resources

Trigger condition

Call chain

Detection confidence



---

8. Dialog Relationship Graph

Create a visual relationship graph:

MainActivity
      ↓
checkVersion()
      ↓
CustomWarning
      ↓
setContentView()
      ↓
Dialog.show()

This allows the user to understand the dialog's origin quickly.


---

9. Patch Engine

Provide controlled patching capabilities for identified code.

Possible operations:

Disable a specific dialog invocation

Modify a dialog-triggering condition

Replace a dialog behavior

Remove a dialog invocation

Remove related resources when dependency analysis indicates they are unused

Patch Smali

Rebuild the modified APK

Sign the resulting APK


The application should always create an original-project backup before modification.


---

10. Dependency Analysis

Before removing a class/resource, check:

Class references

Method references

Resource references

Manifest references

Constructor usage

Reflection-related references where detectable

Native references where detectable

String references

Call graph dependencies


If the application cannot confidently determine whether removing something is safe, show:

REQUIRES MANUAL REVIEW

instead of silently deleting it.


---

11. Analysis Progress System

While analysis is running, show a real-time progress screen:

APK ANALYSIS

✓ APK Validation
✓ APK Extraction
✓ Manifest Analysis
✓ DEX Discovery
✓ DEX Indexing
✓ JADX Analysis
✓ Smali Analysis
● Dialog Detection
○ Resource Analysis
○ Dependency Analysis
○ Report Generation

Overall Progress: 76%

Include:

Current operation

Percentage

Processed files

Current DEX

Analysis logs

Cancel button

Error/warning indicators



---

12. Automatic Analysis Report

Once the analysis finishes, the application should automatically generate a complete technical report.

Report Summary

APK ANALYSIS REPORT

APK:
example.apk

Package:
com.example.app

Version:
2.4.1

Size:
87.4 MB

Status:
COMPLETED

Classes:
14,823

Methods:
91,442

DEX Files:
6

Resources:
9,821

Native Libraries:
8

Dialogs Detected:
12

Custom Dialogs:
7

Potential Patch Candidates:
5


---

13. Report Sections

Executive Summary

Short overview of the APK and the most important findings.

APK Information

Name

Package

Version

Size

SDK

Architectures

Signing information


Manifest Analysis

Activities

Services

Receivers

Providers

Permissions

Intent filters


DEX Analysis

DEX count

Classes

Methods

Fields

Packages

Obfuscation indicators


JADX Findings

Important classes and methods discovered through source analysis.

Smali Findings

Relevant Smali files, methods, and instructions.

Custom Dialog Findings

Detailed list of every detected dialog.

Resource Findings

Layouts

Strings

Drawables

Dialog-related resources

Resource references


Native Library Findings

.so files

Architectures

Library names

Basic metadata


Dependency Analysis

Relationships between classes, methods and resources.

Patch Candidates

Potentially modifiable targets identified by the analyzer.

Analysis Logs

Detailed processing information and warnings.


---

14. Report Export

Support multiple report formats:

HTML

Interactive professional report.

PDF

Printable technical report.

JSON

Machine-readable analysis result.

Example:

{
  "apk": {
    "name": "example.apk",
    "package": "com.example.app"
  },
  "analysis": {
    "classes": 14823,
    "methods": 91442,
    "dexFiles": 6
  },
  "dialogs": [
    {
      "class": "com.example.popup.CustomWarning",
      "confidence": "high"
    }
  ]
}

TXT

Simple technical report.


---

15. Report Viewer

After analysis:

✓ ANALYSIS COMPLETE

APK: example.apk

┌──────────┐ ┌──────────┐ ┌──────────┐
│ 14.8K    │ │ 91.4K    │ │ 12       │
│ Classes  │ │ Methods  │ │ Dialogs  │
└──────────┘ └──────────┘ └──────────┘

Custom Dialogs:       7
Potential Issues:    14
Patch Candidates:     5

[ VIEW FULL REPORT ]

[ EXPORT PDF ]

[ EXPORT HTML ]

[ EXPORT JSON ]

[ OPEN ANALYZER ]


---

16. Flutter App Architecture

Flutter UI
     │
     ├── Dashboard
     ├── APK Import
     ├── Analysis Screen
     ├── Code Explorer
     ├── Dialog Scanner
     ├── Findings
     ├── Patch Center
     ├── Report Viewer
     └── Settings
            │
            ↓
       Dart Service Layer
            │
            ↓
       Native Android Bridge
            │
     ┌──────┴────────┐
     ↓               ↓
 Kotlin Layer    Native Engine
     │               │
     ├── JADX        ├── DEX Parser
     ├── Baksmali    ├── Binary Analysis
     ├── APK Build   └── Performance Tasks
     └── APK Sign


---

17. Project Management

Every analyzed APK becomes a local project:

Projects
 └── example.apk
      ├── Original APK
      ├── Extracted Files
      ├── DEX Data
      ├── Smali
      ├── Analysis Database
      ├── Findings
      ├── Reports
      ├── Patch History
      └── Modified APKs

This allows the user to close the application and continue the analysis later.


---

18. Security & Stability Requirements

Never execute imported APK code during static analysis.

Treat every imported APK as untrusted.

Isolate extraction/analysis workspace.

Validate ZIP/APK structures.

Protect against malicious archive paths.

Keep original APK untouched.

Maintain SHA-256 checksum of the original APK.

Create backups before modifications.

Validate modified APK after rebuilding.

Show clear warnings for uncertain analysis results.

Prevent the application from silently modifying an APK.



---

19. App UI Style

Design Direction

Professional mobile reverse-engineering IDE

Theme

Background:  #0D0F12
Surface:     #15181D
Cards:       #1C2026
Primary:     #E4363D
Text:        #F2F2F2
Secondary:   #9AA0A6

Main Navigation

APK Analyzer

📦 Projects
🔍 Analyzer
🧩 Classes
📝 Smali
☕ JADX
💬 Dialog Scanner
🔗 References
🛠 Patch Center
📊 Reports
📜 Logs
⚙ Settings


---

20. Main Dashboard

┌─────────────────────────────────┐
│ APK Analyzer              ⚙     │
├─────────────────────────────────┤
│                                 │
│        + ANALYZE APK            │
│                                 │
├─────────────────────────────────┤
│ Recent Projects                 │
│                                 │
│ example.apk                     │
│ 12 Dialogs • 6 DEX             │
│ Analysis Completed              │
│                       [Report]   │
│                                 │
│ game.apk                        │
│ 4 Dialogs • 3 DEX              │
│ Analysis Completed              │
│                       [Report]   │
└─────────────────────────────────┘


---

21. Code Explorer

Features:

Syntax highlighting

Line numbers

Search

Find/replace

Class navigation

Method navigation

Reference navigation

Java/Kotlin-like source

Smali

Before/after patch comparison

Highlight modified lines



---

22. Patch Center

PATCH CENTER

Target:
CustomWarningDialog

Detection:
HIGH CONFIDENCE

Affected Class:
com.example.popup.CustomWarning

Dependencies:
2

Resources:
3

Risk:
MEDIUM

[ INSPECT ]

[ PREVIEW PATCH ]

[ APPLY PATCH ]

Every modification should be recorded in the project's patch history.


---

23. Final Product Workflow

IMPORT APK
                     ↓
              APK VALIDATION
                     ↓
              DEEP ANALYSIS
                     ↓
 ┌───────────────────────────────────┐
 │ Manifest                          │
 │ DEX                               │
 │ JADX                              │
 │ Smali                             │
 │ Resources                         │
 │ Native Libraries                  │
 │ Strings                           │
 │ Dialog Detection                  │
 │ Call Graph                        │
 │ Dependency Analysis               │
 └───────────────────────────────────┘
                     ↓
              ANALYSIS COMPLETE
                     ↓
             AUTOMATIC REPORT
                     ↓
       ┌─────────────┼─────────────┐
       ↓             ↓             ↓
    HTML/PDF       JSON          TXT
       ↓
    FINDINGS
       ↓
  SELECT TARGET
       ↓
    INSPECT
       ↓
  PATCH PREVIEW
       ↓
  APPLY PATCH
       ↓
  REBUILD APK
       ↓
   SIGN APK
       ↓
 VERIFY OUTPUT
       ↓
   EXPORT APK

Final Product Goal

The final application should function as a professional mobile APK static-analysis and controlled patching workstation, combining Flutter UI + native Android tooling + JADX + Baksmali/Smali + DEX analysis + custom pattern detection + dependency analysis + automatic technical reporting + APK rebuilding/signing in one application.ame 

## Target platform
Mobile application

## Target audience
Primary users who need a focused, dependable workflow for this product category.

## Problem statement
Define the most expensive or frustrating workflow the first release should improve.

## Success metrics
- A user can complete the primary workflow without assistance.
- The first release has measurable activation and completion events.
- The product remains understandable to maintainers after launch.

## Constraints
Build this as a static-analysis-first workstation: never execute imported APK code, treat every APK as untrusted, sandbox the extraction workspace, validate ZIP structure and reject malicious paths (zip-slip), and keep the original APK untouched with a stored SHA-256 checksum. Run all heavy work (JADX, Baksmali, indexing) off the UI thread via isolates and cancelable background jobs, and cache results in SQLite/Drift so projects can resume without re-analysis. Be honest about uncertainty: every detection carries a confidence level, and anything the dependency analysis can't verify (reflection, native references, dynamic loading) must be flagged "Requires Manual Review" rather than auto-removed. Patching must be explicit and reversible, meaning a mandatory backup, a before/after preview, a recorded patch history, and validation after rebuild and signing, with no silent modification ever. On mobile, expect memory and storage limits with large multi-DEX APKs (80 MB+), so use streaming, lazy loading, and paginated class/method views, and note that re-signing changes the app's signature, so modified APKs can't update the original install and may fail signature-dependent checks. Keep scope to legitimate use such as security research, debugging, and modifying apps you own or have permission to modify, and stay within the licenses of JADX and Smali/Baksmali and applicable law.
