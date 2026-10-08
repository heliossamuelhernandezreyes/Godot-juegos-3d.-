extends Node
## FISURA 0.9.1 transient SFX. Procedural placeholder: no shrill sweeping sine gunshot.
## ARCONT audio policy: bounded voice pool, deterministic signed PCM, no clipping.
const SAMPLE_RATE := 24000
const POOL_SIZE := 6

var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_cursor := 0
var event_serial := 0

func _ready() -> void:
    streams["fire"] = _render("fire", 0.18, 711)
    streams["hit"] = _render("hit", 0.15, 919)
    streams["pickup"] = _render("pickup", 0.36, 113)
    streams["dash"] = _render("dash", 0.24, 553)
    streams["damage"] = _render("damage", 0.32, 338)
    streams["victory"] = _render("victory", 0.76, 404)
    for i in range(POOL_SIZE):
        var voice := AudioStreamPlayer.new()
        voice.name = "SFX voice %d" % i
        voice.volume_db = -12.0
        add_child(voice)
        voices.append(voice)

func _render(kind: String, duration: float, seed_value: int) -> AudioStreamWAV:
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = SAMPLE_RATE
    wav.stereo = false
    var count := int(duration * float(SAMPLE_RATE))
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var noise_gen := RandomNumberGenerator.new()
    noise_gen.seed = seed_value
    var low_noise := 0.0
    var sub_phase := 0.0
    var last_sample := 0.0
    for i in range(count):
        var time := float(i) / float(SAMPLE_RATE)
        var t := float(i) / float(count)
        var white := noise_gen.randf_range(-1.0, 1.0)
        low_noise = lerpf(low_noise, white, 0.065)
        var high_noise := white - low_noise
        var hz := 90.0 + 90.0 * pow(1.0 - t, 3.0)
        sub_phase += TAU * hz / float(SAMPLE_RATE)
        var sub := sin(sub_phase)
        var click := high_noise * pow(1.0 - t, 18.0)
        var thump := sub * pow(1.0 - t, 4.0)
        var sample := 0.0
        match kind:
            "fire":
                # 10ms mechanical crack, short low-calibre pressure body, quiet vent tail.
                sample = click * 0.48 + thump * 0.38 + low_noise * pow(1.0-t, 3.0) * 0.14
            "hit":
                sample = click * 0.24 + thump * 0.30 + low_noise * pow(1.0-t, 6.0) * 0.12
            "dash":
                var swoosh := sin(t * PI) * sin(t * PI)
                sample = low_noise * swoosh * 0.50 + high_noise * swoosh * 0.07
            "damage":
                sample = thump * 0.34 + low_noise * pow(1.0-t, 2.0) * 0.16
            "pickup":
                var soft := sin(TAU * (392.0 + 220.0 * t) * time) * 0.60
                soft += sin(TAU * 587.33 * time) * 0.25
                sample = soft * sin(t * PI) * 0.24
            "victory":
                var chord := sin(TAU * 261.63 * time) + sin(TAU * 329.63 * time) + sin(TAU * 392.0 * time)
                sample = chord * sin(t * PI) * 0.115
        # 2ms onset smoothing, sample-to-sample low-pass and conservative peak.
        sample *= minf(1.0, time * 500.0)
        sample = lerpf(last_sample, sample, 0.78)
        last_sample = sample
        bytes.encode_s16(i * 2, roundi(clampf(sample, -0.82, 0.82) * 32767.0))
    wav.data = bytes
    return wav

func trigger(kind: String) -> void:
    if not streams.has(kind) or voices.is_empty():
        return
    var voice: AudioStreamPlayer = voices[voice_cursor]
    voice_cursor = (voice_cursor + 1) % voices.size()
    voice.stop()
    voice.stream = streams[kind]
    event_serial += 1
    voice.pitch_scale = 0.96 + float(event_serial % 5) * 0.02 if kind == "fire" else 1.0
    voice.play()
