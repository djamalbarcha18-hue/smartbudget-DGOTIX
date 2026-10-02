# ML Kit text recognition (offline receipt reading): only the Latin model is
# bundled; the plugin also references the Chinese, Devanagari, Japanese and
# Korean recognizers, which are not shipped. Tell R8 they are absent on
# purpose instead of failing the release build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
