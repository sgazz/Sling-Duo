# Sling Duo

An iPhone arcade prototype about two climbers connected by an elastic rope. Launch once, steer with tilt, and keep the pair climbing in rhythm.

## Escape and Endless

Each run begins as Escape: reach platform 150 to exit the cave. The three chapters are The Depths (0–49), The Climb (50–99), and Daylight Ahead (100–150). At the exit the duo celebrates and the result shows score, active real time, and longest combo. Play Again starts a fresh Escape; Keep Climbing continues the same run as Endless after the resume countdown. Pauses, countdowns and the victory screen do not add to the run timer.

Height, score, combo and fastest Escape records are stored separately for normal and Turbo runs. Once Turbo is used, the remainder of that run stays in the Turbo record category even if the switch is disabled.

## Play

- Drag and release to make the first sling. Your comfortable phone angle at release becomes the neutral tilt position.
- Tilt left or right to steer the airborne climber, or choose Controls: Slide in the pause menu. In Slide mode, touch anywhere during flight and drag horizontally relative to that touch; release to brake. The choice survives relaunches.
- Catch a platform to swap roles and automatically launch the partner.
- The first manual pull starts a four-second deadline. It continues through release, flight and repeated misses; only a successful catch restores it. After an automatic jump misses, the same rescue deadline starts.
- Tap anywhere after game over to restart. The best score is saved locally.
- Pause with the pause button; Continue gives a three-second countdown. Returning from the background also requires Continue.
- HEIGHT counts catches; SCORE awards one point per catch and two for moving platforms. Descending catches in the central 30% of a platform earn +1 PERFECT. Every fifth consecutive catch earns +2 COMBO. A miss or a trick platform breaks the streak; trick platforms always give zero points.
- Use the speaker button to mute sound; the preference survives relaunches.

The first three jumps are forgiving. Later platforms require sideways steering, and small gold platforms appear from the seventh jump, once every five jumps. Automatic launches provide height rather than horizontal aim. The route is visible ahead to fill the viewport. After height 100, occasional gold platforms move slowly sideways and award double points; precision platforms never move. Each moving 2× platform has an alternative 0-point trick platform at the same height. Both can be caught; choosing the trick continues the climb without awarding points.

Experimental Turbo is available in the pause menu (Off by default). Every five active seconds it adds 5% to simulation speed, reaching 3× after 200 seconds. Pauses and resume countdown do not advance it. Restarting a run or toggling the mode resets the ramp. Rescue deadlines remain real-time.

## Run

Open `Sling Duo.xcodeproj`, select the **Sling Duo** scheme, choose your signing team, and run on an iPhone. The app targets iOS 17.6 or newer; development and builds currently use Xcode 27.1.

A physical iPhone is needed to evaluate tilt, haptics, and silent-switch behavior. Simulator builds are useful for visual checks and automated tests.

## Code

- `GameScene.swift`: game flow, touch handling, Core Motion, camera, and feedback.
- `JumpMechanics.swift`: jump states, calibrated tilt response, shared physics, automatic launch solver, and camera behavior.
- `LedgeSpawner.swift` / `LedgeNode.swift`: progressive routes, precision platforms, and swept grab detection.
- `ClimberNode.swift` / `RubberRopeSystem.swift`: characters and rope presentation.
- `GameAudio.swift` / `Sounds/`: short synthesized effects using ambient audio playback.

## Tests

Run the test targets with **Product → Test** in Xcode. Unit tests cover jump transitions, rescue timing, tilt response, reachability, precision platforms, and preventing unattended climbing. UI tests cover pause/resume, background interruption, and mute preference persistence.

This repository is an actively tuned gameplay prototype.
