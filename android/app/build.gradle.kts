plugins {
id("com.android.application")
id("kotlin-android")
// Flutter Gradle Plugin must be applied last
id("dev.flutter.flutter-gradle-plugin")
}

android {
// مشخص کردن namespace متناسب با پروژه
namespace = "com.example.vpnferdosi"
compileSdk = flutter.compileSdkVersion

ndkVersion = "27.0.12077973"

compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

kotlinOptions {
    jvmTarget = JavaVersion.VERSION_11.toString()
}

defaultConfig {
    // Application ID یکتا برای برنامه VPN فردوسی
    applicationId = "com.example.vpn_ferdosi"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}

buildTypes {
    release {
        // برای ساخت Release می‌توانید امضای مخصوص خود را تنظیم کنید
        signingConfig = signingConfigs.getByName("debug")
    }
}

}

flutter {
source = "../.."
}
