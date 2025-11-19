# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep your model classes
-keep class com.maazkhan07.jobsinquwait.models.** { *; }

# Keep Gson stuff
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# Keep Retrofit stuff
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Keep OkHttp stuff
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Keep Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Keep your API models
-keep class com.maazkhan07.jobsinquwait.api.** { *; }

# Keep your services
-keep class com.maazkhan07.jobsinquwait.services.** { *; }

# Keep your repositories
-keep class com.maazkhan07.jobsinquwait.repositories.** { *; }

# Keep your utils
-keep class com.maazkhan07.jobsinquwait.utils.** { *; }

# Keep your widgets
-keep class com.maazkhan07.jobsinquwait.widgets.** { *; }

# Keep your pages
-keep class com.maazkhan07.jobsinquwait.pages.** { *; }

# Keep your main activity
-keep class com.maazkhan07.jobsinquwait.MainActivity { *; } 