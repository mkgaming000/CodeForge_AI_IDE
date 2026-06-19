# CodeForge ProGuard rules.
#
# Most plugins used here are pure-Dart or use standard Flutter plugin
# registration, which the Flutter Gradle plugin already keeps automatically.
# These extra rules cover classes accessed via reflection that ProGuard
# might otherwise strip in a minified release build (minifyEnabled true).

# flutter_secure_storage uses Android Keystore APIs via reflection.
-keep class androidx.security.crypto.** { *; }

# permission_handler registers a PluginRegistry.RequestPermissionsResultListener.
-keep class com.baseflow.permissionhandler.** { *; }

# file_picker invokes platform Intents reflectively for document picking.
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep Gson-style model classes used by any plugin's JSON (de)serialization.
-keepattributes Signature
-keepattributes *Annotation*

# Keep all native method names — required for any plugin using JNI.
-keepclasseswithmembernames class * {
    native <methods>;
}
