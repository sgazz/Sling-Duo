# Sling Duo

An iPhone arcade prototype about two climbers connected by an elastic rope. Launch once, steer with tilt, and keep the pair climbing in rhythm.

## Play

- Drag and release to make the first sling. Your comfortable phone angle at release becomes the neutral tilt position.
- Tilt left or right to steer the airborne climber.
- Catch a platform to swap roles and automatically launch the partner.
- A miss opens a four-second window to start a rescue sling.
- Tap anywhere after game over to restart. The best score is saved locally.
- Use the speaker button to mute sound; the preference survives relaunches.

The first three jumps are forgiving. Later platforms require sideways steering, and small gold platforms appear from the seventh jump, once every five jumps. Automatic launches provide height rather than horizontal aim.

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

Run the test targets with **Product → Test** in Xcode. Unit tests cover jump transitions, rescue timing, tilt response, reachability, precision platforms, and preventing unattended climbing. A UI test checks that mute preferences persist across relaunches.

This repository is an actively tuned gameplay prototype.
