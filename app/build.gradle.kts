plugins {
    id("com.android.application")
    kotlin("android")
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.20"
}

android {
    namespace = "com.apklab.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.apklab.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// Generate a debug signing keystore at build time and bundle it as an asset.
// CI machines have keytool (JDK). The app signs patched APKs with this key.
val genKeystore by tasks.registering(Exec::class) {
    val outFile = file("src/main/assets/apklab.keystore")
    outputs.file(outFile)
    doFirst { outFile.parentFile.mkdirs() }
    commandLine(
        "keytool", "-genkeypair",
        "-keystore", outFile.absolutePath,
        "-alias", "apklab", "-keyalg", "RSA", "-keysize", "2048",
        "-validity", "10950", "-storepass", "android", "-keypass", "android",
        "-storetype", "PKCS12",
        "-dname", "CN=ApkLab Debug, OU=ApkLab, O=ApkLab"
    )
    onlyIf { !outFile.exists() }
}
tasks.named("preBuild") { dependsOn(genKeystore) }

dependencies {
    implementation(project(":engine"))
    val composeBom = platform("androidx.compose:compose-bom:2024.09.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-ktx:1.9.2")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    debugImplementation("androidx.compose.ui:ui-tooling")
}
