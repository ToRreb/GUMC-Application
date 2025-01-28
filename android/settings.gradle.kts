pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

include(":app")

val localPropertiesFile = file("local.properties")
val properties = Properties()
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        properties.load(reader)
    }
}

val flutterSdkPath = properties.getProperty("flutter.sdk")
    ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")

apply(from = "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle") 