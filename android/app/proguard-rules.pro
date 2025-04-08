# Keep Razorpay classes
-keepclassmembers class com.razorpay.** { *; }
-keep class com.razorpay.** { *; }

# Google Pay related classes
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.gms.** { *; }

# Missing ProGuard annotations
-dontwarn proguard.annotation.**

# To prevent obfuscation of methods
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Support libraries
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# JavaX annotations used by Razorpay
-dontwarn javax.annotation.**