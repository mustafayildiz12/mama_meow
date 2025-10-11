import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}



val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yildiz.mama_meow"
    compileSdk = 36
    buildToolsVersion = "36.0.0"
     ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21

         //? https://github.com/MaikuB/flutter_local_notifications/issues/2389
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Match Kotlin JVM target to Java 21
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yildiz.mama_meow"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 16
        versionName = flutter.versionName
    }

     signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
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

dependencies {
    // ...
    implementation("com.google.android.material:material:1.12.0")

        //? https://github.com/MaikuB/flutter_local_notifications/issues/2389
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

