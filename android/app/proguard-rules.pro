# Add Google ML Kit keep rules to prevent R8 from removing these classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep ML Kit text recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep all Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Google Sign-In classes
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Firestore classes
-keep class com.google.cloud.firestore.** { *; }
-dontwarn com.google.cloud.firestore.**
