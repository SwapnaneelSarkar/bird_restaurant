# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep Play Integrity API classes
-keep class com.google.android.play.integrity.** { *; }

# Keep Play Integrity API classes (modern replacement for Play Core)
-keep class com.google.android.play.integrity.** { *; }

# Keep Play Core classes that Flutter needs for deferred components and split compatibility
# These are required for Flutter's engine to function properly
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep Play Core classes needed for Android 15 compatibility
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.integrity.** { *; }

# Suppress warnings for Play Core classes that may have compatibility issues
-dontwarn com.google.android.play.core.common.PlayCoreDialogWrapperActivity
-dontwarn com.google.android.play.core.broadcast.**
-dontwarn com.google.android.play.core.receiver.**

# Additional keep rules for Flutter's deferred components system
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Android 15 compatibility - suppress specific Play Core warnings
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Additional missing classes from newer Play libraries
-dontwarn com.google.android.play.core.common.IntentSenderForResultStarter
-dontwarn com.google.android.play.core.listener.StateUpdatedListener

# Specific missing class for Flutter's deferred components
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Flutter specific classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep multidex classes
-keep class androidx.multidex.** { *; }

# Keep Android support classes
-keep class androidx.** { *; }
-keep class android.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}

# Keep custom application classes
-keep class com.birdpartner.app.** { *; }

