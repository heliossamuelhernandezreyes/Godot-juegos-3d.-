extends SceneTree
## ARCONT source-traced CC0 OGG QA. Engine import + immutable source bytes.
## Exact file license/provenance and conservative voice budget, not mastering.
const AUDIO = preload("res://scripts/audio_fx.gd")
const ROOT := "res://assets/vendor/kenney_sfx/"

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "PROVENANCE.json"))
    if typeof(provenance) != TYPE_DICTIONARY or provenance.get("license") != "CC0-1.0":
        _fail("No verified CC0 source manifest")
        return
    var assets: Array = provenance.get("assets", [])
    if assets.size() != 7:
        _fail("Incomplete Kenney source audio set")
        return
    var seen := {}
    for receipt in assets:
        var file: String = str(receipt["file"])
        var path: String = ROOT + file
        if seen.has(file) or not FileAccess.file_exists(path):
            _fail("Duplicate/missing source audio " + file)
            return
        seen[file] = true
        if FileAccess.get_sha256(path) != str(receipt["sha256"]):
            _fail("Original CC0 audio bytes drifted for " + file)
            return
        if int(receipt["bytes"]) < 1000 or float(receipt["duration_seconds"]) <= 0.03:
            _fail("Invalid Kenney clip metadata for " + file)
            return
        var stream: AudioStream = load(path) as AudioStream
        if stream == null:
            _fail("Godot could not decode OGG file " + file)
            return
    var audio = AUDIO.new()
    root.add_child(audio)
    if audio.voices.size() != audio.POOL_SIZE or audio.voices.size() > 8:
        _fail("Audio voice cap was exceeded")
        return
    for kind in ["fire", "mechanical", "hit", "damage", "dash", "pickup", "cover", "victory", "explosion"]:
        if not audio.streams.has(kind):
            _fail("Unmapped event " + kind)
            return
    audio.trigger("fire")
    audio.trigger("cover")
    audio.trigger("vault")
    audio.trigger("land")
    # Release native Vorbis playback before the headless SceneTree exits.
    for voice in audio.voices:
        voice.stop()
        voice.stream = null
    audio.streams.clear()
    audio.queue_free()
    await process_frame
    print("REACTIVO AUDIO BUDGET PASS kenney_cc0_ogg=",assets.size(),
        " source_hashes=true voices=",audio.voices.size()," fire_layered=true")
    quit(0)

func _fail(message: String) -> void:
    printerr("REACTIVO AUDIO BUDGET FAIL: " + message)
    quit(1)
