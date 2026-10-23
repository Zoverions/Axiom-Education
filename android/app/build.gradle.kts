import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseSigningRequiredKeys =
    listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val releaseStorePath = keystoreProperties.getProperty("storeFile")?.trim()
val releaseStoreFile =
    releaseStorePath?.takeIf { it.isNotEmpty() }?.let { file(it) }
val releaseSigningReady =
    keystorePropertiesFile.isFile &&
        releaseSigningRequiredKeys.all { key ->
            keystoreProperties.getProperty(key)?.isNotBlank() == true
        } &&
        releaseStoreFile?.isFile == true
val releaseTaskRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }

if (releaseTaskRequested && !releaseSigningReady) {
    throw GradleException(
        "Android release signing requires complete, non-blank keyAlias, keyPassword, " +
            "storeFile, and storePassword values in android/key.properties, and storeFile " +
            "must resolve to an existing keystore. No fallback signing key is allowed.",
    )
}

android {
    namespace = "com.zoverions.ontarioedai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.zoverions.ontarioedai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = requireNotNull(releaseStoreFile)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfigs.findByName("release")?.let { signingConfig = it }
        }
    }
}

flutter {
    source = "../.."
}
