extends SceneTree
## Synthetic sanity check; NEVER represent these numbers as Android measurements.
const PROBE: Script = preload("res://scripts/reactivo_device_perf_probe.gd")

func _initialize() -> void:
    call_deferred("_validate")

func _validate() -> void:
    var zeros: Array[float] = []
    var empty: Dictionary = PROBE.summarize(zeros)
    if empty["sample_count"] != 0 or empty["p50_ms"] != null:
        _fail("empty telemetry not correctly represented as unmeasured")
        return
    var samples: Array[float] = []
    for i in range(95):
        samples.append(16.0)
    for i in range(5):
        samples.append(42.0)
    var summary: Dictionary = PROBE.summarize(samples)
    if summary["sample_count"] != 100:
        _fail("sample count inaccurate")
        return
    if not is_equal_approx(summary["p50_ms"],16.0):
        _fail("incorrect p50 nearest-rank latency")
        return
    if not is_equal_approx(summary["p95_ms"],16.0):
        _fail("incorrect p95 nearest-rank latency")
        return
    if not is_equal_approx(summary["p99_ms"],42.0):
        _fail("incorrect p99 nearest-rank latency")
        return
    if summary["intervals_over_33ms"] != 5 or absf(float(summary["avg_ms"])-17.3) > 0.001:
        _fail("incorrect long-frame/mean counts")
        return
    var probe: Node = Node.new()
    probe.set_script(PROBE)
    root.add_child(probe)
    if probe.enabled or probe.is_processing():
        _fail("QA data logger should be disabled in CI desktop / non-Android platform")
        return
    print("FISURA DEBUG FRAME PACING MATH PASS synthetic_only=true debug_linux_probe=disabled")
    quit(0)

func _fail(reason: String) -> void:
    printerr("FISURA DEBUG FRAME PACING MATH FAIL ",reason)
    quit(1)
