import java.util.Properties // Import the Properties class
import org.gradle.api.GradleException // Import the GradleException class

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

include(":app")

// Load local.properties
val localPropertiesFile = file("local.properties")
val properties = Properties()

if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        properties.load(reader)
    }
}

// Retrieve Flutter SDK path
val flutterSdkPath: String = properties.getProperty("flutter.sdk")
    ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")

// Apply Flutter plugin loader
apply(from = "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle")
