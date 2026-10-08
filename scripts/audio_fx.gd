extends Node
## FISURA 0.9.2 - Kenney CC0 source-pinned imported Vorbis SFX.
## Every OGG and exact original-byte SHA256 is recorded in
## res://assets/vendor/kenney_sfx/PROVENANCE.json.
## Preview mix, not a sound-design listening/mastering certificate.
const POOL_SIZE := 8
const SFX_DIR := "res://assets/vendor/kenney_sfx/"

var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_cursor := 0
var event_serial := 0

func _ready() -> void:
    var files := {
        "fire":"fire_laser.ogg",
        "mechanical":"fire_mechanical.ogg",
        "hit":"impact_metal.ogg",
        "damage":"impact_light.ogg",
        "dash":"explosion.ogg",
        "pickup":"pickup.ogg",
        "cover":"cover_enter.ogg",
        "victory":"pickup.ogg",
        "explosion":"explosion.ogg"
    }
    for key in files:
        var res: AudioStream = load(SFX_DIR + files[key]) as AudioStream
        if res == null:
            push_error("FISURA AUDIO: missing licensed sample " + str(files[key]))
        else:
            streams[key] = res
    for i in range(POOL_SIZE):
        var voice := AudioStreamPlayer.new()
        voice.name = "Pooled licensed SFX voice %d" % i
        voice.volume_db = -19.0
        add_child(voice)
        voices.append(voice)

func _play_voice(key: String, pitch: float, volume: float) -> void:
    if not streams.has(key) or voices.is_empty():
        return
    var voice: AudioStreamPlayer = voices[voice_cursor]
    voice_cursor = (voice_cursor + 1) % voices.size()
    voice.stop()
    voice.stream = streams[key]
    voice.pitch_scale = pitch
    voice.volume_db = volume
    voice.play()

func trigger(kind: String) -> void:
    event_serial += 1
    match kind:
        "fire":
            # Two distinct CC0 source layers: short sci-fi discharge +
            # restrained hard-material mechanical transient.
            _play_voice("fire", 0.87 + float(event_serial % 4) * 0.025, -14.0)
            _play_voice("mechanical", 1.1, -25.0)
        "hit":
            _play_voice("hit", 0.92 + float(event_serial % 3) * 0.06, -18.0)
        "damage":
            _play_voice("damage", 0.85, -17.0)
        "dash":
            _play_voice("dash", 1.3, -27.0)
        "pickup":
            _play_voice("pickup", 1.0, -17.0)
        "cover":
            _play_voice("cover", 0.85, -23.0)
        "vault":
            _play_voice("cover", 0.65, -21.0)
        "land":
            _play_voice("mechanical", 0.75, -22.0)
        "victory":
            _play_voice("victory", 0.82, -16.0)
        "explosion":
            _play_voice("explosion", 0.95, -14.0)
