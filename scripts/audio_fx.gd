extends Node
## Lightweight synthesized SFX for the playable prototype.
## No streamed copyrighted sound assets; capped voice pool for Android testing.
const SAMPLE_RATE := 22050
const POOL_SIZE := 7

var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_cursor := 0

func _ready() -> void:
    streams["fire"] = _tone(0.075, 210.0, 90.0, 0.48, 0.33)
    streams["hit"] = _tone(0.11, 500.0, 170.0, 0.60, 0.25)
    streams["pickup"] = _tone(0.36, 420.0, 850.0, 0.49, 0.05)
    streams["dash"] = _tone(0.18, 180.0, 530.0, 0.44, 0.14)
    streams["damage"] = _tone(0.24, 140.0, 60.0, 0.50, 0.44)
    streams["victory"] = _tone(0.68, 470.0, 930.0, 0.44, 0.02)
    for i in range(POOL_SIZE):
        var voice := AudioStreamPlayer.new()
        voice.name = "SFX voice %d" % i
        voice.volume_db = -7.0
        add_child(voice)
        voices.append(voice)

func _tone(duration: float, start_hz: float, end_hz: float, volume: float, noise: float) -> AudioStreamWAV:
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = SAMPLE_RATE
    wav.stereo = false
    var count := int(duration * float(SAMPLE_RATE))
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var random := RandomNumberGenerator.new()
    random.seed = 20260704 + count
    var phase := 0.0
    for i in range(count):
        var progress := float(i) / float(count)
        var hz := lerpf(start_hz, end_hz, progress)
        phase += TAU * hz / float(SAMPLE_RATE)
        var envelop := pow(1.0 - progress, 2.3) * minf(1.0, progress * 110.0)
        var tonal := sin(phase) * (1.0 - noise)
        var rough := random.randf_range(-1.0, 1.0) * noise
        var sample := clampf((tonal + rough) * volume * envelop, -1.0, 1.0)
        bytes.encode_s16(i * 2, roundi(sample * 32767.0))
    wav.data = bytes
    return wav

func trigger(kind: String) -> void:
    if not streams.has(kind) or voices.is_empty():
        return
    var voice: AudioStreamPlayer = voices[voice_cursor]
    voice_cursor = (voice_cursor + 1) % voices.size()
    voice.stop()
    voice.stream = streams[kind]
    voice.pitch_scale = 1.0
    voice.play()
