import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Ortak release anahtari. Sahadaki tabletler bu anahtarla imzali; OTA
// guncellemesinin kurulabilmesi icin HER makinede ayni anahtar kullanilmali
// (her makinenin kendi debug anahtari farkli oldugu icin kurulum reddediliyordu).
// Dosyalar git'e girmez; paylasimi git disindan yapilir.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}

// Anahtar yoksa release derlemesi bilerek durur: yanlis anahtarla uretilen bir
// APK sahadaki tabletlere kurulamaz ve bunu ancak tablette fark ederdik.
gradle.taskGraph.whenReady {
    if (!keystorePropertiesFile.exists() && allTasks.any { it.name.contains("Release") }) {
        throw GradleException(
            "android/key.properties bulunamadi. Release APK yalnizca ortak " +
                "anahtarla (nimo-release.jks) imzalanabilir.",
        )
    }
}

android {
    namespace = "com.nimo.nimo_arizabakim"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nimo.nimo_arizabakim"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Sahadaki tabletler (Lenovo TB336ZU) arm64-v8a. Uc mimarinin kodunu
    // birlikte tasimak APK'yi buyutup OTA indirmesini yavaslatiyordu; x86_64
    // yalnizca emulatorlerde kullanilir. (ndk.abiFilters Flutter'in kendi hedef
    // listesiyle ezildigi icin paketleme asamasinda dislaniyor; duz
    // `flutter build apk --release` ile de calisir.)
    packaging {
        jniLibs {
            excludes += listOf("lib/armeabi-v7a/**", "lib/x86_64/**")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}
