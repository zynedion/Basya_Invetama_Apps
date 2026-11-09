import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadPropertiesFile = rootProject.file("key.properties")
val uploadProperties = Properties().apply {
    if (uploadPropertiesFile.isFile) {
        uploadPropertiesFile.inputStream().use { load(it) }
    }
}
val validateUploadSigning = tasks.register("validateUploadSigning") {
    doLast {
        check(uploadPropertiesFile.isFile) {
            "Release requires android/key.properties. See docs/release/google-play.md."
        }
        listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach { key ->
            check(!uploadProperties.getProperty(key).isNullOrBlank()) {
                "Missing $key in android/key.properties."
            }
        }
        check(rootProject.file(uploadProperties.getProperty("storeFile")).isFile) {
            "Upload keystore not found. storeFile is relative to android/ or absolute."
        }
    }
}
tasks.configureEach {
    if (name == "preReleaseBuild") dependsOn(validateUploadSigning)
}

android {
    namespace = "id.basyainvestama.app"
    compileSdk = maxOf(36, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "id.basyainvestama.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = maxOf(36, flutter.targetSdkVersion)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = uploadProperties.getProperty("keyAlias")
            keyPassword = uploadProperties.getProperty("keyPassword")
            storePassword = uploadProperties.getProperty("storePassword")
            storeFile = uploadProperties.getProperty("storeFile")
                ?.takeIf { it.isNotBlank() }?.let { rootProject.file(it) }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
