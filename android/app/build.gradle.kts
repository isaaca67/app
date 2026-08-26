import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lee la configuración de firma desde `android/key.properties` (local)
// o desde variables de entorno (CI en la nube con GitHub Actions).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun secret(key: String, env: String): String? {
    return keystoreProperties.getProperty(key) ?: System.getenv(env)
}

android {
    namespace = "com.cov.app.v2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cov.app.v2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFileEnv = System.getenv("KEYSTORE_FILE")
            keyAlias = secret("keyAlias", "KEY_ALIAS")
            keyPassword = secret("keyPassword", "KEY_PASSWORD")
            storePassword = secret("storePassword", "KEYSTORE_PASSWORD")
            storeFile = keystoreProperties.getProperty("storeFile")
                ?.let { file(it) }
                ?: storeFileEnv?.let { file(it) }
        }
    }

    buildTypes {
        release {
            // Firma de producción. Local: android/key.properties.
            // CI: variables de entorno con el keystore en base64.
            signingConfig = if (signingConfigs.getByName("release").storeFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
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