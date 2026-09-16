# Flutter ProGuard Rules

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep standard library classes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable

# Drift/SQLite specific rules if needed
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# Google Play Core rules to fix R8 missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Google Sign-in & Play Services Auth (protect from R8 stripping)
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-dontwarn com.google.android.gms.**

# Geolocator / Geocoding (Baseflow) & Play Services Location — neither plugin
# ships its own consumer proguard rules, so without these the release build
# (minifyEnabled/shrinkResources, unlike debug) can silently break location
# fixes/reverse-geocoding that work fine in a debug run.
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.baseflow.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

