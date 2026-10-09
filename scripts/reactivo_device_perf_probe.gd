extends Node
## Android DEBUG ONLY, local/offline sampling of actual rendered frame intervals.
## Never labels emulator runs as physical hardware or supplies fake thermal data.
## Writes one bounded JSON report to user://fisura_qa_frame_pacing.json.
const REPORT_PATH := "user://fisura_qa_frame_pacing.json"
const MAX_SAMPLES := 1800
const SNAPSHOT_SECONDS := 30.0
var session_start_usec := 0
var prior_frame_usec := 0
var frame_ms: Array[float] = []
var enabled := false
var seconds_since_report := 0.0

func _ready() -> void:
    enabled = OS.get_name() == "Android" and OS.has_feature("debug")
    set_process(enabled)
    if enabled:
        session_start_usec = Time.get_ticks_usec()
        print("FISURA ANDROID DEBUG FRAME PACING active | offline file: ",REPORT_PATH)

func _process(delta: float) -> void:
    if not enabled:
        return
    var now: int = Time.get_ticks_usec()
    if prior_frame_usec > 0:
        var duration_ms: float = float(now-prior_frame_usec) / 1000.0
        # Pauses and app suspension are separated from normal frame pacing.
        if duration_ms > 0.0 and duration_ms <= 2000.0:
            frame_ms.append(duration_ms)
            if frame_ms.size() > MAX_SAMPLES:
                frame_ms.pop_front()
    prior_frame_usec = now
    seconds_since_report += delta
    if seconds_since_report >= SNAPSHOT_SECONDS:
        seconds_since_report = 0.0
        _write_report()

static func summarize(values: Array[float]) -> Dictionary:
    var ordered: Array[float] = values.duplicate()
    ordered.sort()
    if ordered.is_empty():
        return {"sample_count":0, "p50_ms":null, "p95_ms":null, "p99_ms":null,
                "avg_ms":null, "intervals_over_33ms":0}
    var total := 0.0
    var slow := 0
    for ms in ordered:
        total += ms
        if ms > 33.333:
            slow += 1
    return {
        "sample_count":ordered.size(),
        "p50_ms":_percentile(ordered,0.50),
        "p95_ms":_percentile(ordered,0.95),
        "p99_ms":_percentile(ordered,0.99),
        "avg_ms":snappedf(total/float(ordered.size()),0.001),
        "intervals_over_33ms":slow
    }

static func _percentile(sorted_ms: Array[float], fraction: float) -> float:
    var at: int = clampi(int(ceil(float(sorted_ms.size())*fraction))-1,0,sorted_ms.size()-1)
    return snappedf(sorted_ms[at],0.001)

func _write_report() -> void:
    if frame_ms.size() < 60:
        return
    var stats: Dictionary = summarize(frame_ms)
    var report := {
        "protocol":"fisura-android-debug-frame-pacing",
        "version":1,
        "capture_mode":"real_engine_process_frame_intervals",
        "engine":Engine.get_version_info().get("string","unknown"),
        "runtime_os":OS.get_name(),
        "debug_build":OS.has_feature("debug"),
        "physical_device_verified":false,
        "requires_hardware_record":"device make/model, temperature and real-device confirmation MUST be captured separately",
        "sample_window_seconds":SNAPSHOT_SECONDS,
        "rolling_max_samples":MAX_SAMPLES,
        "stats":stats,
        "engine_fps_at_last_capture":Engine.get_frames_per_second(),
        "draw_calls_frame_last_observed":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
        "gpu_frame_time_ms":"not_measured",
        "thermal_c":"not_measured",
        "quality_status":"raw QA measurements, NOT a verified phone benchmark",
        "network_used":false
    }
    var output := FileAccess.open(REPORT_PATH,FileAccess.WRITE)
    if output != null:
        output.store_string(JSON.stringify(report,"\t") + "\n")
        output.close()
        print("FISURA ANDROID FRAME PACING samples=%d p95_ms=%.2f p99_ms=%.2f" %
            [stats["sample_count"],stats["p95_ms"],stats["p99_ms"]])
