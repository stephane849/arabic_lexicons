plugins {
    // 8.6+ is the first AGP that accepts compileSdk 35, which MMD's
    // androidx.activity dependency requires. Still runs on Gradle 8.7.
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.20" apply false
}
