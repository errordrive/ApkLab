import '../../domain/models/apk_info.dart';
import '../../domain/models/manifest_info.dart';
import '../../domain/models/dex_info.dart';
import '../../domain/models/jadx_source.dart';
import '../../domain/models/smali_info.dart';
import '../../domain/models/dialog_finding.dart';
import '../../domain/models/dependency_info.dart';
import '../../domain/models/patch_candidate.dart';
import '../../domain/models/analysis_report.dart';
import '../../domain/models/analysis_log.dart';
import '../../domain/models/project.dart';

class SampleProjects {
  static ApkProject get antiAdwareProject {
    const apkInfo = ApkInfo(
      name: 'example.apk',
      packageName: 'com.example.app',
      versionName: '2.4.1',
      versionCode: 241,
      sizeBytes: 91643904, // 87.4 MB
      minSdk: 23,
      targetSdk: 34,
      compileSdk: 34,
      supportedArchitectures: ['arm64-v8a', 'armeabi-v7a', 'x86_64'],
      dexCount: 6,
      nativeLibraries: [
        'libnative-crypto.so',
        'libsubstrate.so',
        'libart-hook.so',
        'libengine.so',
        'libsecutils.so',
        'libunity.so',
        'libmonobrow.so',
        'libcrashlytics.so'
      ],
      certificateInfo: 'CN=Example Developer, OU=Mobile Security, O=AppLab Corp, C=US (SHA256: 8F:9D:2A:44:11...)',
      signingScheme: 'v1 + v2 + v3 (APK Signature Scheme v3 enabled)',
      permissions: [
        'android.permission.INTERNET',
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.SYSTEM_ALERT_WINDOW',
        'android.permission.WAKE_LOCK',
        'android.permission.FOREGROUND_SERVICE',
      ],
      sha256Checksum: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );

    const manifestInfo = ManifestInfo(
      activities: [
        ComponentInfo(name: 'com.example.MainActivity', isExported: true, intentFilters: ['android.intent.action.MAIN', 'android.intent.category.LAUNCHER']),
        ComponentInfo(name: 'com.example.ui.SettingsActivity', isExported: false),
        ComponentInfo(name: 'com.example.ui.AdPromptActivity', isExported: true, intentFilters: ['android.intent.action.VIEW']),
        ComponentInfo(name: 'com.example.ui.UpgradeNoticeActivity', isExported: false),
      ],
      services: [
        ComponentInfo(name: 'com.example.network.BackgroundSyncService', isExported: false),
        ComponentInfo(name: 'com.example.analytics.PushDispatcherService', isExported: false),
      ],
      receivers: [
        ComponentInfo(name: 'com.example.receivers.BootReceiver', isExported: true, intentFilters: ['android.intent.action.BOOT_COMPLETED']),
        ComponentInfo(name: 'com.example.receivers.NetworkChangeReceiver', isExported: false),
      ],
      providers: [
        ComponentInfo(name: 'com.example.data.AppFileProvider', isExported: false, permission: 'com.example.app.FILE_PROVIDER'),
      ],
      permissions: [
        'android.permission.INTERNET',
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.SYSTEM_ALERT_WINDOW',
      ],
      deepLinks: ['https://example.com/app/promo', 'app://example.com/verify'],
      metadata: {
        'com.google.android.gms.version': '12451000',
        'firebase_analytics_collection_enabled': 'false',
        'io.flutter.embedding.android.NormalTheme': '@style/NormalTheme',
      },
      appConfig: {
        'allowBackup': false,
        'supportsRtl': true,
        'extractNativeLibs': false,
        'networkSecurityConfig': '@xml/network_security_config',
      },
    );

    final dexList = [
      const DexInfo(
        dexName: 'classes.dex',
        classesCount: 3420,
        methodsCount: 22100,
        fieldsCount: 8900,
        stringsCount: 14500,
        packages: ['com.example', 'com.example.ui', 'com.example.network', 'com.example.utils'],
        classes: [
          DexClass(
            name: 'com.example.MainActivity',
            packageName: 'com.example',
            superClass: 'androidx.appcompat.app.AppCompatActivity',
            interfaces: ['com.example.ui.DialogCallback'],
            methods: [
              DexMethod(name: 'onCreate', returnType: 'void', parameterTypes: ['android.os.Bundle'], modifiers: ['public']),
              DexMethod(name: 'checkVersion', returnType: 'void', parameterTypes: [], modifiers: ['private']),
              DexMethod(name: 'displayWarningDialog', returnType: 'void', parameterTypes: [], modifiers: ['public']),
            ],
            fields: [
              DexField(name: 'TAG', type: 'java.lang.String', modifiers: ['private', 'static', 'final']),
              DexField(name: 'mCustomDialog', type: 'com.example.popup.CustomWarning', modifiers: ['private']),
            ],
          ),
          DexClass(
            name: 'com.example.popup.CustomWarning',
            packageName: 'com.example.popup',
            superClass: 'android.app.Dialog',
            interfaces: ['android.content.DialogInterface'],
            isDialogRelated: true,
            methods: [
              DexMethod(name: '<init>', returnType: 'void', parameterTypes: ['android.content.Context'], modifiers: ['public']),
              DexMethod(name: 'showWarning', returnType: 'void', parameterTypes: [], modifiers: ['public']),
              DexMethod(name: 'dismiss', returnType: 'void', parameterTypes: [], modifiers: ['public']),
            ],
            fields: [
              DexField(name: 'btnContinue', type: 'android.widget.Button', modifiers: ['private']),
              DexField(name: 'warningText', type: 'java.lang.String', modifiers: ['private']),
            ],
          ),
          DexClass(
            name: 'com.example.network.ApiManager',
            packageName: 'com.example.network',
            superClass: 'java.lang.Object',
            interfaces: [],
            methods: [
              DexMethod(name: 'fetchRemoteConfig', returnType: 'void', parameterTypes: [], modifiers: ['public', 'static']),
              DexMethod(name: 'validateToken', returnType: 'boolean', parameterTypes: ['java.lang.String'], modifiers: ['public']),
            ],
            fields: [
              DexField(name: 'BASE_URL', type: 'java.lang.String', modifiers: ['private', 'static', 'final']),
            ],
          ),
          DexClass(
            name: 'com.example.utils.SecurityUtils',
            packageName: 'com.example.utils',
            superClass: 'java.lang.Object',
            interfaces: [],
            methods: [
              DexMethod(name: 'verifySignature', returnType: 'boolean', parameterTypes: ['android.content.Context'], modifiers: ['public', 'static']),
              DexMethod(name: 'isRooted', returnType: 'boolean', parameterTypes: [], modifiers: ['public', 'static']),
            ],
            fields: [],
          ),
          DexClass(
            name: 'com.example.a.b.c',
            packageName: 'com.example.a.b',
            superClass: 'java.lang.Object',
            interfaces: [],
            isObfuscated: true,
            methods: [
              DexMethod(name: 'a', returnType: 'java.lang.String', parameterTypes: ['int'], modifiers: ['public'], isObfuscated: true),
              DexMethod(name: 'b', returnType: 'void', parameterTypes: [], modifiers: ['public'], isObfuscated: true),
            ],
            fields: [
              DexField(name: 'a', type: 'int', modifiers: ['private'], isObfuscated: true),
            ],
          ),
        ],
      ),
      const DexInfo(
        dexName: 'classes2.dex',
        classesCount: 2980,
        methodsCount: 18400,
        fieldsCount: 7100,
        stringsCount: 11200,
        packages: ['androidx.appcompat', 'androidx.fragment', 'com.google.android.material'],
        classes: [],
      ),
      const DexInfo(
        dexName: 'classes3.dex',
        classesCount: 2850,
        methodsCount: 17800,
        fieldsCount: 6800,
        stringsCount: 10400,
        packages: ['com.google.android.gms', 'com.google.firebase'],
        classes: [],
      ),
      const DexInfo(
        dexName: 'classes4.dex',
        classesCount: 2100,
        methodsCount: 13900,
        fieldsCount: 5200,
        stringsCount: 8900,
        packages: ['okhttp3', 'okio', 'retrofit2'],
        classes: [],
      ),
      const DexInfo(
        dexName: 'classes5.dex',
        classesCount: 1950,
        methodsCount: 11200,
        fieldsCount: 4600,
        stringsCount: 7300,
        packages: ['kotlin', 'kotlinx.coroutines'],
        classes: [],
      ),
      const DexInfo(
        dexName: 'classes6.dex',
        classesCount: 1523,
        methodsCount: 8042,
        fieldsCount: 3100,
        stringsCount: 5800,
        packages: ['androidx.core', 'androidx.lifecycle'],
        classes: [],
      ),
    ];

    final jadxSources = [
      const JadxSource(
        className: 'com.example.popup.CustomWarning',
        packageName: 'com.example.popup',
        sourceCode: '''package com.example.popup;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import com.example.R;

public class CustomWarning extends Dialog {
    private Button mContinueBtn;
    private TextView mWarningText;

    public CustomWarning(Context context) {
        super(context);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.dialog_warning);
        setTitle("Warning");

        mContinueBtn = findViewById(R.id.btn_continue);
        mWarningText = findViewById(R.id.tv_warning_msg);

        mContinueBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
    }

    public void showWarning() {
        // Triggers display of forced warning modal
        show();
    }
}''',
        methods: ['<init>', 'onCreate', 'showWarning'],
        fields: ['mContinueBtn', 'mWarningText'],
        callers: ['com.example.MainActivity.checkVersion()', 'com.example.MainActivity.displayWarningDialog()'],
        references: ['android.app.Dialog', 'R.layout.dialog_warning', 'R.id.btn_continue'],
        usages: ['MainActivity.java:78', 'MainActivity.java:114'],
      ),
      const JadxSource(
        className: 'com.example.MainActivity',
        packageName: 'com.example',
        sourceCode: '''package com.example;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import com.example.popup.CustomWarning;
import com.example.network.ApiManager;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";
    private CustomWarning mCustomDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        checkVersion();
    }

    private void checkVersion() {
        // Verifies client version and triggers modal if out of date
        if (ApiManager.isUpdateRequired()) {
            mCustomDialog = new CustomWarning(this);
            mCustomDialog.showWarning();
        }
    }

    public void displayWarningDialog() {
        if (mCustomDialog != null) {
            mCustomDialog.show();
        }
    }
}''',
        methods: ['onCreate', 'checkVersion', 'displayWarningDialog'],
        fields: ['TAG', 'mCustomDialog'],
        callers: ['Android OS Runtime'],
        references: ['com.example.popup.CustomWarning', 'com.example.network.ApiManager'],
        usages: ['AndroidManifest.xml'],
      ),
      const JadxSource(
        className: 'com.example.network.ApiManager',
        packageName: 'com.example.network',
        sourceCode: '''package com.example.network;

public class ApiManager {
    private static final String BASE_URL = "https://api.example.com/v2";

    public static boolean isUpdateRequired() {
        // Telemetry check for forced update
        return true;
    }
}''',
        methods: ['isUpdateRequired'],
        fields: ['BASE_URL'],
        callers: ['com.example.MainActivity.checkVersion()'],
        references: [],
        usages: ['MainActivity.java:23'],
      ),
      const JadxSource(
        className: 'com.example.utils.SecurityUtils',
        packageName: 'com.example.utils',
        sourceCode: '''package com.example.utils;

import android.content.Context;

public class SecurityUtils {
    public static boolean verifySignature(Context context) {
        // Verifies original app certificate
        return true;
    }

    public static boolean isRooted() {
        return false;
    }
}''',
        methods: ['verifySignature', 'isRooted'],
        fields: [],
        callers: ['com.example.MainActivity.onCreate()'],
        references: ['android.content.Context'],
        usages: ['MainActivity.java:16'],
      ),
    ];

    final smaliFiles = [
      const SmaliInfo(
        className: 'Lcom/example/popup/CustomWarning;',
        instructionsCount: 42,
        methods: ['<init>(Landroid/content/Context;)V', 'onCreate(Landroid/os/Bundle;)V', 'showWarning()V'],
        dialogInvocations: ['invoke-virtual {p0}, Lcom/example/popup/CustomWarning;->show()V'],
        smaliCode: '''.class public Lcom/example/popup/CustomWarning;
.super Landroid/app/Dialog;
.source "CustomWarning.java"

# instance fields
.field private mContinueBtn:Landroid/widget/Button;
.field private mWarningText:Landroid/widget/TextView;

# direct methods
.method public constructor <init>(Landroid/content/Context;)V
    .registers 2
    .param p1, "context"    # Landroid/content/Context;

    .line 15
    invoke-direct {p0, p1}, Landroid/app/Dialog;-><init>(Landroid/content/Context;)V

    .line 16
    return-void
.end method

# virtual methods
.method public showWarning()V
    .registers 1

    .line 38
    # INVOCATION TARGET FOR DIALOG SUPPRESSION
    invoke-virtual {p0}, Lcom/example/popup/CustomWarning;->show()V

    .line 39
    return-void
.end method''',
        patchedCode: '''.class public Lcom/example/popup/CustomWarning;
.super Landroid/app/Dialog;
.source "CustomWarning.java"

# instance fields
.field private mContinueBtn:Landroid/widget/Button;
.field private mWarningText:Landroid/widget/TextView;

# direct methods
.method public constructor <init>(Landroid/content/Context;)V
    .registers 2
    .param p1, "context"    # Landroid/content/Context;

    .line 15
    invoke-direct {p0, p1}, Landroid/app/Dialog;-><init>(Landroid/content/Context;)V

    .line 16
    return-void
.end method

# virtual methods
.method public showWarning()V
    .registers 1

    .line 38
    # PATCHED: Suppress dialog invocation by immediate return
    # invoke-virtual {p0}, Lcom/example/popup/CustomWarning;->show()V
    return-void
.end method''',
        modifiedLines: [25, 26],
      ),
      const SmaliInfo(
        className: 'Lcom/example/MainActivity;',
        instructionsCount: 88,
        methods: ['onCreate(Landroid/os/Bundle;)V', 'checkVersion()V', 'displayWarningDialog()V'],
        dialogInvocations: [
          'new-instance v0, Lcom/example/popup/CustomWarning;',
          'invoke-virtual {v0}, Lcom/example/popup/CustomWarning;->showWarning()V'
        ],
        smaliCode: '''.class public Lcom/example/MainActivity;
.super Landroidx/appcompat/app/AppCompatActivity;
.source "MainActivity.java"

.method private checkVersion()V
    .registers 3

    .line 22
    invoke-static {}, Lcom/example/network/ApiManager;->isUpdateRequired()Z
    move-result v0
    if-eqz v0, :cond_update_done

    .line 23
    new-instance v1, Lcom/example/popup/CustomWarning;
    invoke-direct {v1, p0}, Lcom/example/popup/CustomWarning;-><init>(Landroid/content/Context;)V
    iput-object v1, p0, Lcom/example/MainActivity;->mCustomDialog:Lcom/example/popup/CustomWarning;

    .line 24
    invoke-virtual {v1}, Lcom/example/popup/CustomWarning;->showWarning()V

    :cond_update_done
    return-void
.end method''',
      ),
    ];

    final dialogFindings = [
      const DialogFinding(
        id: 'dialog_credit_01',
        title: 'INJECTED CREDIT DIALOG (Modder Popup)',
        className: 'com.example.mod.ModderCreditDialog',
        parentClass: 'Landroid/app/dialogbox;',
        triggeredFrom: 'MainActivity',
        triggeringMethod: 'onCreate()',
        layout: 'R.layout.dialogbox_credit',
        showCall: 'Landroid/app/dialogbox;->show()V',
        relatedStrings: [
          'Modded by APKHacker99',
          'Credits & Support: t.me/apkhacks',
          'Join Telegram Channel for more mods',
          'Dismiss',
        ],
        confidence: DetectionConfidence.high,
        detectionLevel: 'Level 2 — Injected Modder Credit ("Landroid/app/dialogbox")',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/dialogbox_credit.xml'],
        triggerCondition: 'Injected into MainActivity.onCreate() lifecycle hook',
        callChain: ['MainActivity', 'onCreate()', 'ModderCreditDialog', 'show()V'],
        riskLevel: 'SAFE TO REMOVE',
        isInjectedCreditDialog: true,
        creditAuthor: 'APKHacker99 (t.me/apkhacks)',
        injectionReason: 'Reverse-engineer credit dialogue injected into MainActivity to promote modder channel',
      ),
      const DialogFinding(
        id: 'dialog_01',
        title: 'CUSTOM DIALOG #01',
        className: 'com.example.ui.RateUsDialog',
        parentClass: 'android.app.AlertDialog',
        triggeredFrom: 'MainActivity',
        triggeringMethod: 'onSessionCountReached()',
        layout: 'R.layout.dialog_rate_us',
        showCall: 'AlertDialog.show()',
        relatedStrings: ['Rate Us', '5 Stars', 'Later'],
        confidence: DetectionConfidence.high,
        detectionLevel: 'Level 1 — Known Android APIs',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/dialog_rate_us.xml', 'res/values/strings.xml'],
        triggerCondition: 'sessionCount >= 3 && !hasRated',
        callChain: ['MainActivity', 'onSessionCountReached()', 'RateUsDialog', 'AlertDialog.show()'],
        riskLevel: 'LOW',
      ),
      const DialogFinding(
        id: 'dialog_02',
        title: 'CUSTOM DIALOG #02',
        className: 'com.example.ui.PromoOverlayDialog',
        parentClass: 'android.app.Dialog',
        triggeredFrom: 'AdPromptActivity',
        triggeringMethod: 'renderPromoOffer()',
        layout: 'R.layout.dialog_promo_interstitial',
        showCall: 'Dialog.show()',
        relatedStrings: ['Limited Offer', 'Upgrade Now', 'No Thanks'],
        confidence: DetectionConfidence.high,
        detectionLevel: 'Level 2 — Class Structure Detection',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/dialog_promo_interstitial.xml', 'res/drawable/banner_promo.png'],
        triggerCondition: 'isUserPremium == false',
        callChain: ['AdPromptActivity', 'renderPromoOffer()', 'PromoOverlayDialog', 'Dialog.show()'],
        riskLevel: 'MEDIUM',
      ),
      const DialogFinding(
        id: 'dialog_03',
        title: 'CUSTOM DIALOG #03',
        className: 'com.example.popup.CustomWarning',
        parentClass: 'android.app.Dialog',
        triggeredFrom: 'MainActivity',
        triggeringMethod: 'checkVersion()',
        layout: 'R.layout.dialog_warning',
        showCall: 'Dialog.show()',
        relatedStrings: ['Warning', 'Continue'],
        confidence: DetectionConfidence.high,
        detectionLevel: 'Level 3 — Smali Pattern Detection',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/dialog_warning.xml', 'res/values/strings.xml', 'res/drawable/ic_warning.xml'],
        triggerCondition: 'ApiManager.isUpdateRequired() == true',
        callChain: ['MainActivity', 'checkVersion()', 'CustomWarning', 'setContentView()', 'Dialog.show()'],
        riskLevel: 'MEDIUM',
      ),
      const DialogFinding(
        id: 'dialog_04',
        title: 'CUSTOM DIALOG #04',
        className: 'com.example.security.RootWarningDialog',
        parentClass: 'androidx.fragment.app.DialogFragment',
        triggeredFrom: 'MainActivity',
        triggeringMethod: 'verifyIntegrity()',
        layout: 'R.layout.dialog_security_alert',
        showCall: 'DialogFragment.show()',
        relatedStrings: ['Security Alert', 'Device Unsafe', 'Exit App'],
        confidence: DetectionConfidence.high,
        detectionLevel: 'Level 4 — Call Graph Analysis',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/dialog_security_alert.xml'],
        triggerCondition: 'SecurityUtils.isRooted() == true',
        callChain: ['MainActivity', 'verifyIntegrity()', 'RootWarningDialog', 'DialogFragment.show()'],
        riskLevel: 'HIGH',
      ),
      const DialogFinding(
        id: 'dialog_05',
        title: 'CUSTOM DIALOG #05',
        className: 'com.example.ui.FeedbackPromptDialog',
        parentClass: 'android.app.Dialog',
        triggeredFrom: 'SettingsActivity',
        triggeringMethod: 'openFeedback()',
        layout: 'R.layout.dialog_feedback',
        showCall: 'Dialog.show()',
        relatedStrings: ['Send Feedback', 'Submit'],
        confidence: DetectionConfidence.medium,
        detectionLevel: 'Level 5 — Resource Correlation',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/dialog_feedback.xml'],
        triggerCondition: 'user clicks feedback item',
        callChain: ['SettingsActivity', 'openFeedback()', 'FeedbackPromptDialog', 'Dialog.show()'],
        riskLevel: 'LOW',
      ),
      const DialogFinding(
        id: 'dialog_06',
        title: 'CUSTOM DIALOG #06',
        className: 'com.example.sync.SyncWaitDialog',
        parentClass: 'android.app.ProgressDialog',
        triggeredFrom: 'BackgroundSyncService',
        triggeringMethod: 'onPreExecute()',
        layout: 'R.layout.dialog_progress_spinner',
        showCall: 'ProgressDialog.show()',
        relatedStrings: ['Syncing...', 'Please wait'],
        confidence: DetectionConfidence.high,
        detectionLevel: 'Level 1 — Known Android APIs',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/dialog_progress_spinner.xml'],
        triggerCondition: 'syncInProgress == true',
        callChain: ['BackgroundSyncService', 'onPreExecute()', 'ProgressDialog.show()'],
        riskLevel: 'LOW',
      ),
      const DialogFinding(
        id: 'dialog_07',
        title: 'CUSTOM DIALOG #07',
        className: 'com.example.a.b.c.CustomNotice',
        parentClass: 'android.app.Dialog',
        triggeredFrom: 'com.example.a.b.c',
        triggeringMethod: 'a()',
        layout: 'R.layout.custom_notice_obf',
        showCall: 'Dialog.show()',
        relatedStrings: ['Notice', 'OK'],
        confidence: DetectionConfidence.medium,
        detectionLevel: 'Level 3 — Smali Pattern Detection',
        dexFile: 'classes.dex',
        relatedResources: ['res/layout/custom_notice_obf.xml'],
        triggerCondition: 'obfuscated telemetry event',
        callChain: ['com.example.a.b.c', 'a()', 'CustomNotice', 'Dialog.show()'],
        riskLevel: 'HIGH',
      ),
    ];

    final dependencies = [
      const DependencyInfo(
        targetComponent: 'com.example.popup.CustomWarning',
        totalDependencies: 5,
        safeToRemoveCount: 3,
        manualReviewCount: 2,
        dependencies: [
          DependencyItem(source: 'MainActivity.java:78', target: 'CustomWarning.<init>', type: 'Class Reference', confidence: 'HIGH'),
          DependencyItem(source: 'MainActivity.java:79', target: 'CustomWarning.showWarning()', type: 'Method Call', confidence: 'HIGH'),
          DependencyItem(source: 'res/layout/dialog_warning.xml', target: 'R.layout.dialog_warning', type: 'Resource Reference', confidence: 'HIGH'),
          DependencyItem(
            source: 'com.example.utils.DynamicLoader.java:45',
            target: 'Class.forName("com.example.popup.CustomWarning")',
            type: 'Reflection',
            requiresManualReview: true,
            reviewReason: 'Dynamic reflection reference detected. Removal could throw ClassNotFoundException.',
            confidence: 'MEDIUM',
          ),
          DependencyItem(
            source: 'libnative-crypto.so',
            target: 'Java_com_example_popup_CustomWarning_nativeHash',
            type: 'Native JNI Reference',
            requiresManualReview: true,
            reviewReason: 'JNI exported symbol matches class name. Native binary may call back into this class.',
            confidence: 'MEDIUM',
          ),
        ],
      ),
      const DependencyInfo(
        targetComponent: 'com.example.ui.PromoOverlayDialog',
        totalDependencies: 3,
        safeToRemoveCount: 3,
        manualReviewCount: 0,
        dependencies: [
          DependencyItem(source: 'AdPromptActivity.java:55', target: 'PromoOverlayDialog.show()', type: 'Method Call', confidence: 'HIGH'),
          DependencyItem(source: 'res/layout/dialog_promo_interstitial.xml', target: 'R.layout.dialog_promo_interstitial', type: 'Resource Reference', confidence: 'HIGH'),
          DependencyItem(source: 'res/drawable/banner_promo.png', target: 'R.drawable.banner_promo', type: 'Resource Reference', confidence: 'HIGH'),
        ],
      ),
    ];

    final patchCandidates = [
      const PatchCandidate(
        id: 'patch_credit_01',
        targetName: 'Kill Injected Credit Dialogue',
        detectionConfidence: 'HIGH CONFIDENCE',
        affectedClass: 'com.example.mod.ModderCreditDialog',
        dependenciesCount: 1,
        resourcesCount: 1,
        risk: 'SAFE TO REMOVE (INJECTED CREDIT)',
        description: 'Neutralizes modder/reverse-engineer credit dialogue popup invoked in MainActivity. Preserves all authentic app dialogues.',
        originalSmali: '''.method public show()V
    .registers 1
    invoke-super {p0}, Landroid/app/dialogbox;->show()V
    return-void
.end method''',
        proposedSmali: '''.method public show()V
    .registers 1
    # PATCHED: Injected modder credit popup killed
    return-void
.end method''',
      ),
      const PatchCandidate(
        id: 'patch_01',
        targetName: 'CustomWarningDialog',
        detectionConfidence: 'HIGH CONFIDENCE',
        affectedClass: 'com.example.popup.CustomWarning',
        dependenciesCount: 2,
        resourcesCount: 3,
        risk: 'MEDIUM',
        description: 'Bypasses the forced warning dialog invoked on startup by short-circuiting showWarning() in Smali.',
        originalSmali: '''.method public showWarning()V
    .registers 1
    invoke-virtual {p0}, Lcom/example/popup/CustomWarning;->show()V
    return-void
.end method''',
        proposedSmali: '''.method public showWarning()V
    .registers 1
    # PATCHED: Suppress dialog invocation
    return-void
.end method''',
      ),
      const PatchCandidate(
        id: 'patch_02',
        targetName: 'PromoOverlayDialog',
        detectionConfidence: 'HIGH CONFIDENCE',
        affectedClass: 'com.example.ui.PromoOverlayDialog',
        dependenciesCount: 3,
        resourcesCount: 2,
        risk: 'LOW',
        description: 'Disables interstitial promotional popup triggered when opening main views.',
        originalSmali: '''.method public show()V
    .registers 1
    invoke-super {p0}, Landroid/app/Dialog;->show()V
    return-void
.end method''',
        proposedSmali: '''.method public show()V
    .registers 1
    # PATCHED: Suppress interstitial promo
    return-void
.end method''',
      ),
      const PatchCandidate(
        id: 'patch_03',
        targetName: 'RateUsDialog',
        detectionConfidence: 'HIGH CONFIDENCE',
        affectedClass: 'com.example.ui.RateUsDialog',
        dependenciesCount: 1,
        resourcesCount: 1,
        risk: 'LOW',
        description: 'Neutralizes recurring 5-star rating prompt.',
        originalSmali: '''.method public show()V
    .registers 1
    invoke-super {p0}, Landroid/app/AlertDialog;->show()V
    return-void
.end method''',
        proposedSmali: '''.method public show()V
    .registers 1
    return-void
.end method''',
      ),
      const PatchCandidate(
        id: 'patch_04',
        targetName: 'RootCheckBypass',
        detectionConfidence: 'MEDIUM CONFIDENCE',
        affectedClass: 'com.example.utils.SecurityUtils',
        dependenciesCount: 4,
        resourcesCount: 0,
        risk: 'HIGH',
        description: 'Forces isRooted() method to return false (0x0) to prevent termination on rooted environments.',
        originalSmali: '''.method public static isRooted()Z
    .registers 1
    # original checks /system/bin/su
    invoke-static {}, Lcom/example/utils/SecurityUtils;->checkSuBinary()Z
    move-result v0
    return v0
.end method''',
        proposedSmali: '''.method public static isRooted()Z
    .registers 1
    # PATCHED: Always report unrooted
    const/4 v0, 0x0
    return v0
.end method''',
      ),
      const PatchCandidate(
        id: 'patch_05',
        targetName: 'TelemetryNoticeSuppress',
        detectionConfidence: 'MEDIUM CONFIDENCE',
        affectedClass: 'com.example.a.b.c.CustomNotice',
        dependenciesCount: 2,
        resourcesCount: 1,
        risk: 'MEDIUM',
        description: 'Removes obfuscated background notice popup trigger.',
        originalSmali: '''.method public a()V
    .registers 1
    invoke-virtual {p0}, Lcom/example/a/b/c/CustomNotice;->show()V
    return-void
.end method''',
        proposedSmali: '''.method public a()V
    .registers 1
    return-void
.end method''',
      ),
    ];

    final report = AnalysisReport(
      id: 'report_antiadware',
      apkName: 'example.apk',
      packageName: 'com.example.app',
      version: '2.4.1',
      sizeBytes: 91643904, // 87.4 MB
      status: 'COMPLETED',
      totalClasses: 14823,
      totalMethods: 91442,
      totalDexFiles: 6,
      totalResources: 9821,
      totalNativeLibs: 8,
      dialogsDetected: 12,
      customDialogs: 7,
      potentialIssues: 14,
      patchCandidates: 5,
      executiveSummary: 'Static analysis completed for example.apk (87.4 MB, 6 DEX files). Found 14,823 classes and 91,442 methods. Detected 12 total dialog invocations including 7 custom dialog implementations. 5 candidate patch targets were identified with low-to-medium risk. 2 dependencies require manual review due to dynamic reflection and native JNI linkage.',
      createdAt: DateTime(2026, 9, 20, 10, 30),
    );

    final logs = [
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 1), stage: 'APK Validation', message: 'Verifying ZIP headers and signature blocks...', level: LogLevel.info, progressPercent: 10),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 4), stage: 'APK Validation', message: 'ZIP structure valid. No zip-slip paths detected. SHA-256: e3b0c4...', level: LogLevel.success, progressPercent: 15),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 8), stage: 'APK Extraction', message: 'Extracted 1,248 files into sandboxed project workspace.', level: LogLevel.info, progressPercent: 25, processedFiles: 1248),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 12), stage: 'Manifest Analysis', message: 'Parsed 4 Activities, 2 Services, 2 Receivers, 1 Provider, 5 Permissions.', level: LogLevel.success, progressPercent: 35),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 18), stage: 'DEX Discovery', message: 'Discovered 6 DEX files (classes.dex to classes6.dex).', level: LogLevel.info, progressPercent: 45, currentDex: 'classes.dex'),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 26), stage: 'DEX Indexing', message: 'Indexed 14,823 classes, 91,442 methods across 6 DEX files.', level: LogLevel.success, progressPercent: 55),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 35), stage: 'JADX Analysis', message: 'Generated decompiled Java source representations for key classes.', level: LogLevel.info, progressPercent: 65),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 44), stage: 'Smali Analysis', message: 'Disassembled DEX bytecode to Smali instructions with xrefs.', level: LogLevel.info, progressPercent: 75),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 28, 52), stage: 'Dialog Detection', message: 'Scanned Level 1-5 patterns: Identified 7 custom dialogs.', level: LogLevel.success, progressPercent: 85),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 29, 2), stage: 'Resource Analysis', message: 'Correlated 9,821 resources with class references.', level: LogLevel.info, progressPercent: 90),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 29, 10), stage: 'Dependency Analysis', message: 'Flagged 2 items as "REQUIRES MANUAL REVIEW" (Reflection & JNI).', level: LogLevel.warning, progressPercent: 95),
      AnalysisLog(timestamp: DateTime(2026, 9, 20, 10, 29, 15), stage: 'Report Generation', message: 'Full analysis report compiled successfully.', level: LogLevel.success, progressPercent: 100),
    ];

    return ApkProject(
      id: 'project_antiadware',
      name: 'example.apk',
      apkPath: '/projects/example.apk/Original/example.apk',
      createdAt: DateTime(2026, 9, 20, 10, 28),
      lastModified: DateTime(2026, 9, 20, 10, 30),
      isOriginalUntouched: true,
      sha256Checksum: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      apkInfo: apkInfo,
      manifestInfo: manifestInfo,
      dexList: dexList,
      jadxSources: jadxSources,
      smaliFiles: smaliFiles,
      dialogFindings: dialogFindings,
      dependencies: dependencies,
      patchCandidates: patchCandidates,
      report: report,
      logs: logs,
      patchHistory: [
        PatchHistoryEntry(
          id: 'hist_01',
          timestamp: DateTime(2026, 9, 20, 10, 32),
          target: 'CustomWarningDialog',
          action: 'Patch Smali - Suppress Dialog',
          details: 'Replaced invoke-virtual show() with immediate return in Lcom/example/popup/CustomWarning;->showWarning()V',
          isRevertible: true,
        ),
      ],
      modifiedApkPaths: ['/projects/example.apk/Modified/example_patched_signed.apk'],
    );
  }

  static ApkProject get gameProject {
    const apkInfo = ApkInfo(
      name: 'game.apk',
      packageName: 'com.playgames.runner',
      versionName: '1.4.0',
      versionCode: 140,
      sizeBytes: 44236800, // 42.1 MB
      minSdk: 21,
      targetSdk: 33,
      compileSdk: 33,
      supportedArchitectures: ['arm64-v8a', 'armeabi-v7a'],
      dexCount: 3,
      nativeLibraries: ['libunity.so', 'libil2cpp.so', 'libmain.so'],
      certificateInfo: 'CN=Play Games Studio, O=PlayGames Ltd (SHA256: 4A:12:33...)',
      signingScheme: 'v2 + v3',
      permissions: [
        'android.permission.INTERNET',
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.VIBRATE',
      ],
      sha256Checksum: 'a7c8b21234fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852c991',
    );

    const manifestInfo = ManifestInfo(
      activities: [
        ComponentInfo(name: 'com.playgames.runner.UnityPlayerActivity', isExported: true, intentFilters: ['android.intent.action.MAIN']),
      ],
      services: [],
      receivers: [],
      providers: [],
      permissions: ['android.permission.INTERNET', 'android.permission.VIBRATE'],
      deepLinks: [],
      metadata: {'unity.splash-mode': '0'},
      appConfig: {'allowBackup': true},
    );

    final report = AnalysisReport(
      id: 'report_game',
      apkName: 'game.apk',
      packageName: 'com.playgames.runner',
      version: '1.4.0',
      sizeBytes: 44236800,
      status: 'COMPLETED',
      totalClasses: 8240,
      totalMethods: 54120,
      totalDexFiles: 3,
      totalResources: 4320,
      totalNativeLibs: 3,
      dialogsDetected: 4,
      customDialogs: 3,
      potentialIssues: 5,
      patchCandidates: 2,
      executiveSummary: 'Static analysis completed for game.apk. 3 DEX files identified. 4 dialogs detected including 3 custom dialogs. 2 patch candidates available.',
      createdAt: DateTime(2026, 9, 20, 9, 15),
    );

    return ApkProject(
      id: 'project_game',
      name: 'game.apk',
      apkPath: '/projects/game.apk/Original/game.apk',
      createdAt: DateTime(2026, 9, 20, 9, 10),
      lastModified: DateTime(2026, 9, 20, 9, 15),
      isOriginalUntouched: true,
      sha256Checksum: 'a7c8b21234fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852c991',
      apkInfo: apkInfo,
      manifestInfo: manifestInfo,
      dexList: [
        const DexInfo(
          dexName: 'classes.dex',
          classesCount: 4200,
          methodsCount: 28000,
          fieldsCount: 11000,
          stringsCount: 18000,
          packages: ['com.playgames', 'com.unity3d'],
          classes: [],
        ),
        const DexInfo(
          dexName: 'classes2.dex',
          classesCount: 2400,
          methodsCount: 16000,
          fieldsCount: 7000,
          stringsCount: 9000,
          packages: ['androidx.core'],
          classes: [],
        ),
        const DexInfo(
          dexName: 'classes3.dex',
          classesCount: 1640,
          methodsCount: 10120,
          fieldsCount: 4200,
          stringsCount: 6500,
          packages: ['com.google.android.play'],
          classes: [],
        ),
      ],
      jadxSources: [],
      smaliFiles: [],
      dialogFindings: [
        const DialogFinding(
          id: 'dialog_g1',
          title: 'CUSTOM DIALOG #01',
          className: 'com.playgames.ui.ReviveDialog',
          parentClass: 'android.app.Dialog',
          triggeredFrom: 'UnityPlayerActivity',
          triggeringMethod: 'onPlayerDeath()',
          layout: 'R.layout.dialog_revive',
          showCall: 'Dialog.show()',
          relatedStrings: ['Watch Ad to Revive', 'Give Up'],
          confidence: DetectionConfidence.high,
          detectionLevel: 'Level 2 — Class Structure Detection',
          dexFile: 'classes.dex',
          relatedResources: ['res/layout/dialog_revive.xml'],
          triggerCondition: 'playerLives == 0',
          callChain: ['UnityPlayerActivity', 'onPlayerDeath()', 'ReviveDialog', 'Dialog.show()'],
        ),
      ],
      dependencies: [],
      patchCandidates: [
        const PatchCandidate(
          id: 'patch_g1',
          targetName: 'ReviveDialogAdSkip',
          detectionConfidence: 'HIGH CONFIDENCE',
          affectedClass: 'com.playgames.ui.ReviveDialog',
          dependenciesCount: 1,
          resourcesCount: 1,
          risk: 'LOW',
          description: 'Auto-grants extra life without displaying ad prompt.',
          originalSmali: 'invoke-virtual {p0}, Lcom/playgames/ui/ReviveDialog;->show()V',
          proposedSmali: '# Bypassed',
        ),
      ],
      report: report,
      logs: [],
    );
  }
}
