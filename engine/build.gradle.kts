plugins {
    kotlin("jvm")
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation("org.smali:dexlib2:2.5.2")
    implementation("com.android.tools.build:apksig:8.5.2")
    implementation("net.dongliu:apk-parser:2.6.10")
    testImplementation("junit:junit:4.13.2")
}

tasks.withType<Test> {
    useJUnit()
}
