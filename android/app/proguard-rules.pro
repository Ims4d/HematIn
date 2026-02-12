# Keep generic type information (VERY IMPORTANT)
-keepattributes Signature
-keepattributes *Annotation*

# Keep flutter local notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Gson classes
-keep class com.google.gson.** { *; }

# Keep TypeToken (important for generic deserialization)
-keep class * extends com.google.gson.reflect.TypeToken
