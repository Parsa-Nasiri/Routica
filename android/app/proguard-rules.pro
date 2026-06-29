# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.api.client.googleapis.auth.oauth2.** { *; }
-keep class com.google.api.client.googleapis.extensions.android.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-keep class com.github.jasminb.jsonapi.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
