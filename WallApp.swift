//
//  WallApp.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseCore
// REMOVE: import GoogleSignIn
// ADD: // TODO: FIX BUILD - Uncomment the line above and ensure GoogleSignIn is linked to the Wall target.

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }

  func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // REMOVE: return GIDSignIn.sharedInstance.handle(url)
    // ADD: // TODO: FIX BUILD - Uncomment the line above once GoogleSignIn is linked.
    // ADD: print("GoogleSignIn URL handling disabled. Please link GoogleSignIn module.")
    return false
  }
}

@main
struct WallApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
          .onOpenURL { url in
              // REMOVE: GIDSignIn.sharedInstance.handle(url)
              // ADD: // TODO: FIX BUILD - Uncomment the line above once GoogleSignIn is linked.
              // ADD: print("GoogleSignIn onOpenURL handling disabled. Please link GoogleSignIn module.")
          }
      }
    }
  }
}