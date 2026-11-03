# Release graphics measurements

Use an unlocked physical iPhone in Developer Mode, paired/trusted by this Mac;
USB is recommended. The separate bundle ID `Gazza.SlingDuo.GraphicsProfile`
preserves the ordinary game's data.

    Tools/profile_graphics.sh DEVICE_UDID /absolute/path/to/results

The script builds Release (`-O`, no code coverage) with `GRAPHICS_PROFILE`,
installs the app and launches its bundle ID through Metal System Trace. It records 115 seconds with 130-second retention. Signed
build products use a temporary directory outside Documents; Finder/iCloud
metadata in Documents can interfere with signing. Set `SLING_PROFILE_DERIVED_DATA`
to reuse an existing temporary build directory.

On the tested iPhone 11, Game Performance retained only a GPU tail or no app GPU
events, even with a longer global window. Metal System Trace provided continuous
GPU execution events. Do not infer coverage from schema names alone: validate
actual row counts, time spans, target process and cave/phase markers.

## Scenario and measurements

The opt-in harness is excluded from ordinary builds. Two rounds visit all nine
caves: idle 2s, held aim 2s, 3× Turbo flight 1s, then a release checkpoint. This is
a transition smoke benchmark, not 150 catches per cave. Routes remain random.
Phase rows also record UTC and monotonic start times. The parser aligns UTC with
the trace start-date and rejects clock disagreement above 2 ms. The profiling
scene disables auto-lock while present and restores the idle timer
when removed. The phone must initially be unlocked; no lock/passcode is bypassed.

`graphics-profile.csv` records process user+system CPU time (% of one logical
core), `phys_footprint` MiB, sampled phase peak, scene callback interval median/p95,
and app-owned base texture count (-1 when unavailable in the baseline). These
are not GPU duration, exact presented FPS or GPU texture residency. Expect 55
records and at least ten frames in every gameplay phase; the paused final release
checkpoint can have zero frames. Inspect traces for transition-time peaks.

The script exports `metal-gpu-intervals` to `trace-gpu.xml` and trace metadata to
`trace-toc.xml`, then summarizes the first complete round:

    python3 Tools/summarize_gpu_trace.py baseline PREFIX graphics-profile.csv OUTPUT_DIR

`PREFIX-toc.xml` and `PREFIX-gpu.xml` must exist. Phase UTC clocks come from CSV;
old captures without clocks can use a `PREFIX-signposts.xml` fallback. Adding the
Points of Interest instrument to Metal System Trace stalled preparation on the
tested setup, so the validated path uses direct CSV clocks instead.

The parser requires all 27 first-round phase timestamps and sufficient GPU frames
in every phase. It resolves XML references, filters the game process and Active
GPU work, and computes the union of SpriteKit Vertex/Fragment execution intervals
per frame. CPU-to-GPU waiting/latency and compositor work are excluded from that
metric. App GPU active percent separately includes other commands of the app.
The parser rejects partial capture instead of manufacturing comparisons.

## Baseline

With Python 3.12+:

    python3 Tools/prepare_graphics_baseline.py /private/tmp/sling-baseline-comparison
    bash /private/tmp/sling-baseline-comparison/Tools/profile_graphics.sh DEVICE_UDID /absolute/path/to/baseline-results

This archives `2a73bfe` and adds the same measurement-only hooks. Its preload is a
no-op and its release only pauses, retaining baseline cache/node behavior. Never
substitute the optimized lifecycle into the baseline when comparing memory.

## Interpretation

A locked device can cancel or prevent capture. Preserve errors but exclude failed
runs. Match workloads and templates, check thermal state, repeat paired runs and
report uncertainty. Simulator CSVs cannot establish physical-device CPU/GPU/FPS
results. Unequal GPU coverage (e.g. all caves versus a last-cave tail) must not be
used to calculate gains. Raw traces can include compositor/system metadata;
commit only app-specific summaries when sharing results.
