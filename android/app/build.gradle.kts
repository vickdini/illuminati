import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.illuminati.illuminati"
    // Android 16. Google Play requires new apps and updates to target it.
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Never change: Google Play identifies the app by it.
        applicationId = "com.illuminati.illuminati"
        // Android 7.0. Google Play's automatic protection requires at least 24.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing key, from android/key.properties (written by the GitHub
    // workflow from repository secrets). Without it, release builds are signed
    // with the debug key, which works but can't update an install made with a
    // different key.
    val keyProperties = Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }
    val hasReleaseKey = keyProperties.getProperty("storeFile") != null

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    // Google Play builds (ILLUMINATI_STORE=play, set by the GitHub workflow):
    // Play updates the app itself and doesn't allow apps to install updates,
    // so src/play/AndroidManifest.xml removes the updater's install permission
    // and file provider. (The Dart updater is off too: Play builds don't get
    // --dart-define=APP_VERSION.)
    if (System.getenv("ILLUMINATI_STORE") == "play") {
        sourceSets.getByName("release").manifest.srcFile("src/play/AndroidManifest.xml")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FileProvider, for handing app updates to the system installer.
    implementation("androidx.core:core:1.13.1")
}
