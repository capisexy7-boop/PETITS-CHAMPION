plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStoreFile = providers.environmentVariable("PETITS_CHAMPIONS_STORE_FILE").orNull
val releaseStorePassword =
    providers.environmentVariable("PETITS_CHAMPIONS_STORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("PETITS_CHAMPIONS_KEY_ALIAS").orNull
val releaseKeyPassword =
    providers.environmentVariable("PETITS_CHAMPIONS_KEY_PASSWORD").orNull
val releaseSigningConfigured = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

if (!releaseSigningConfigured &&
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
) {
    throw GradleException(
        "Release signing is not configured. Set PETITS_CHAMPIONS_STORE_FILE, " +
            "PETITS_CHAMPIONS_STORE_PASSWORD, PETITS_CHAMPIONS_KEY_ALIAS, and " +
            "PETITS_CHAMPIONS_KEY_PASSWORD in the build environment."
    )
}

android {
    namespace = "com.sanfo.petitschampions"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    if (releaseSigningConfigured) {
        signingConfigs {
            create("release") {
                storeFile = file(requireNotNull(releaseStoreFile))
                storePassword = requireNotNull(releaseStorePassword)
                keyAlias = requireNotNull(releaseKeyAlias)
                keyPassword = requireNotNull(releaseKeyPassword)
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sanfo.petitschampions"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
