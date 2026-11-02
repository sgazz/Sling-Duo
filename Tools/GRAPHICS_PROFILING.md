# Release graphics measurements

Run on an unlocked physical iPhone in Developer Mode, paired and trusted by this
Mac; USB is recommended. The profiling build uses the separate bundle identifier
`Gazza.SlingDuo.GraphicsProfile`, so the ordinary game's saved data is preserved.

    Tools/profile_graphics.sh DEVICE_UDID /absolute/path/to/results

The script compiles Release (`-O`, no code coverage) with `GRAPHICS_PROFILE`, installs
the separate application and captures the Instruments Game Performance template.
That template's CPU/GPU/memory tracks are the source for device GPU measurements;
inspect the saved trace and exported table of contents. If the template/runtime
omits a desired GPU track, record Metal System Trace for that track rather than
substituting frame intervals for GPU time.

The opt-in harness is excluded from normal Debug and Release builds. It runs two
rounds through all nine caves: idle 2s, held aim 2s, and 3× Turbo flight 1s per cave,
plus startup and a final release checkpoint. Each selection starts a fresh route;
this is a graphics transition smoke benchmark, not completion of 150 jumps in
each cave. Routes use the game's existing randomness. Repeat longer interactive
captures before making fine-grained FPS or thermal conclusions.

`graphics-profile.csv` records process CPU time as percent of one logical core,
process `phys_footprint` in MiB, sampled peak footprint, scene update interval median
and p95, and number of app-owned base textures (-1 on baseline without that counter).
These are process footprint and callback intervals, not GPU texture residency,
render completion, GPU duration or exact presented FPS. Transition-time memory
spikes are best inspected in Instruments; the CSV phases focus on steady state.
The final released checkpoint can have zero frames because the scene is paused.

Prepare a reproducible baseline checkout (Python 3.12+):

    python3 Tools/prepare_graphics_baseline.py /private/tmp/sling-baseline-comparison
    bash /private/tmp/sling-baseline-comparison/Tools/profile_graphics.sh DEVICE_UDID /absolute/path/to/baseline-results

The script adds the same measurement hooks to the archived `2a73bfe` baseline:
`GameScene` calls frame/start hooks; `ContentView` opens gameplay under
`GRAPHICS_PROFILE`; its transition helpers are no-op preload and pause-only release,
retaining baseline behavior. Never replace baseline lifecycle with the optimized
implementation when comparing memory. The original uninstrumented baseline also
builds successfully in Release.

A locked/unavailable device does not produce valid measurements. Preserve failure
logs and label the run blocked. Simulator CSVs must be labeled simulator-only and
must not be used as physical-device CPU/GPU/FPS evidence.
