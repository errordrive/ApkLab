# ProGuard / R8 rules for ApkLab
# Preserve com.android.apksig and all reflection-based ASN.1 and PKCS#7 encoders
-keep class com.android.apksig.** { *; }
-keep interface com.android.apksig.** { *; }
-keep enum com.android.apksig.** { *; }
-keepclassmembers class com.android.apksig.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions
-dontwarn com.android.apksig.**

# Preserve BouncyCastle and Java security providers
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Preserve native pipeline classes
-keep class com.example.apklab.** { *; }

-dontoptimize
