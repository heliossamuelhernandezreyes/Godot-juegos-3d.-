extends SceneTree
## PCM integrity and conservative peak checks; this is NOT a listening test.
const AUDIO = preload("res://scripts/audio_fx.gd")
func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var source = AUDIO.new()
    root.add_child(source)
    if source.voices.size() > 6 or source.voices.size() < 2:
        _fail("Android audio pool is unbounded")
        return
    for kind in ["fire", "hit", "dash", "damage", "pickup", "victory"]:
        if not source.streams.has(kind):
            _fail("Missing sample: " + kind)
            return
        var wav: AudioStreamWAV = source.streams[kind]
        if wav.mix_rate != 24000 or wav.format != AudioStreamWAV.FORMAT_16_BITS:
            _fail("Unexpected PCM format " + kind)
            return
        var pcm: PackedByteArray = wav.data
        if pcm.size() < 480 or pcm.size() > 45000:
            _fail("Invalid SFX size: " + kind)
            return
        var peak := 0
        var sum_abs := 0.0
        for i in range(0, pcm.size(), 2):
            var x := absi(pcm.decode_s16(i))
            peak = maxi(peak, x)
            sum_abs += float(x)
        var mean := sum_abs / float(pcm.size() / 2)
        if peak > 28000 or mean < 140.0:
            _fail("Clipped/inaudible SFX " + kind + " peak=" + str(peak) + " mean=" + str(mean))
            return
    source.trigger("fire")
    source.trigger("dash")
    print("REACTIVO AUDIO BUDGET PASS voices=",source.voices.size()," pcm=16-bit 24kHz unclipped")
    quit(0)

func _fail(reason: String) -> void:
    printerr("REACTIVO AUDIO BUDGET FAIL: " + reason)
    quit(1)
