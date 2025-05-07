plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.messenger_clone"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.messenger_clone"
        minSdk = 21
        targetSdk = 35
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.20")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.15.2")
    implementation("org.conscrypt:conscrypt-android:2.5.2")
    implementation("javax.xml.parsers:jaxp-api:1.4.2")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.9.22"))

}

flutter {
    source = "../.."
}