import SpriteKit

// Three forgiving introductory jumps, followed by routes that require steering.
struct ClimbDifficulty {
    let minimumWidth: CGFloat
    let maximumWidth: CGFloat
    let minimumGap: CGFloat
    let maximumGap: CGFloat
    let horizontalReach: CGFloat

    init(score: Int) {
        let progress = CGFloat(min(27, max(0, score - 3))) / 27
        minimumWidth = 126 - progress * 32
        maximumWidth = 136 - progress * 26
        minimumGap = 145 + progress * 15
        maximumGap = 155 + progress * 30
        horizontalReach = 110 + progress * 25
    }
}

final class LedgeSpawner {
    private let sceneWidth: CGFloat

    init(sceneWidth: CGFloat) { self.sceneWidth = sceneWidth }

    func startingLedge(y: CGFloat) -> LedgeNode {
        LedgeNode(center: CGPoint(x: sceneWidth / 2, y: y))
    }

    func nextLedge(above ledge: LedgeNode, score: Int) -> LedgeNode {
        let difficulty = ClimbDifficulty(score: score)
        let restJump = score > 0 && score % 5 == 4
        let precisionJump = score >= 6 && score % 5 == 1
        let desiredWidth: CGFloat
        if score < 3 {
            desiredWidth = 160
        } else if precisionJump {
            let progress = CGFloat(min(27, max(0, score - 3))) / 27
            desiredWidth = CGFloat.random(in: (72 - progress * 10)...(80 - progress * 10))
        } else if restJump {
            desiredWidth = min(136, difficulty.maximumWidth + 8)
        } else {
            desiredWidth = CGFloat.random(in: difficulty.minimumWidth...difficulty.maximumWidth)
        }
        // Compact screens also need room for a genuine sideways jump.
        let widthLimit = score < 3 ? sceneWidth - 40 : sceneWidth * 0.34
        let width = min(desiredWidth, max(32, widthLimit))
        let margin = width / 2 + 20
        let left = min(margin, sceneWidth / 2)
        let right = max(left, sceneWidth - margin)
        let x: CGFloat
        let gap: CGFloat
        if score < 3 {
            x = min(right, max(left, sceneWidth / 2 + (score % 2 == 0 ? -35 : 35)))
            gap = 145
        } else {
            // Exclude the whole neutral vertical grab corridor, including forgiveness.
            let safetyGap = max(8, min(18, sceneWidth * 0.035))
            let routeShift = precisionJump ? min(80, sceneWidth * 0.2) : min(100, sceneWidth * 0.23)
            let minimumShift = max(width * 0.55 + safetyGap, routeShift)
            let reach = precisionJump ? min(95, difficulty.horizontalReach) : difficulty.horizontalReach
            let maximumShift = max(minimumShift, reach)
            let leftLow = max(left, ledge.position.x - maximumShift)
            let leftHigh = min(right, ledge.position.x - minimumShift)
            let rightLow = max(left, ledge.position.x + minimumShift)
            let rightHigh = min(right, ledge.position.x + maximumShift)
            let canGoLeft = leftLow <= leftHigh
            let canGoRight = rightLow <= rightHigh
            if canGoLeft && (!canGoRight || Bool.random()) {
                x = CGFloat.random(in: leftLow...leftHigh)
            } else if canGoRight {
                x = CGFloat.random(in: rightLow...rightHigh)
            } else {
                // Only relevant to viewports narrower than the supported phone layout.
                x = abs(left - ledge.position.x) > abs(right - ledge.position.x) ? left : right
            }
            if precisionJump {
                gap = CGFloat.random(in: 145...155)
            } else {
                gap = restJump ? 145 : CGFloat.random(in: difficulty.minimumGap...difficulty.maximumGap)
            }
        }
        return LedgeNode(center: CGPoint(x: x, y: ledge.position.y + gap),
                         size: CGSize(width: width, height: GameConstants.ledgeSize.height),
                         isPrecision: precisionJump)
    }
}
