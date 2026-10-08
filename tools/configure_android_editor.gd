extends SceneTree
## Configure CI-only EditorSettings without committing any device SDK paths.
func _initialize() -> void:
    var sdk := OS.get_environment("ANDROID_HOME")
    var jdk := OS.get_environment("JAVA_HOME")
    if sdk.is_empty() or jdk.is_empty():
        printerr("ANDROID CI FAIL: missing SDK / JDK environment variables")
        quit(1)
        return
    var settings: EditorSettings = EditorInterface.get_editor_settings()
    settings.set_setting("export/android/android_sdk_path", sdk)
    settings.set_setting("export/android/java_sdk_path", jdk)
    print("ANDROID CI CONFIGURED sdk=",sdk," java=",jdk)
    quit(0)
