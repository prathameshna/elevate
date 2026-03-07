# Aggressive ProGuard settings for smaller APK

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Remove unused resources
-keepnames class * extends android.view.View
-keepnames class * extends android.app.Fragment

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimize
-optimizationpasses 5
-dontusemixedcaseclassnames

# Fix R8 compilation for Play Core
-dontwarn com.google.android.play.core.**
