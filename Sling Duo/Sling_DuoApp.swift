//
//  Sling_DuoApp.swift
//  Sling Duo
//
//  Created by Gazza on 25. 10. 2026..
//

import SwiftUI
import UIKit

@main
struct Sling_DuoApp: App {
    @UIApplicationDelegateAdaptor(OrientationDelegate.self) private var orientationDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Tilt is gameplay input; the interface must never follow device rotation.
final class OrientationDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}
