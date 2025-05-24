//
//  AuthenticationViewModel.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = Auth.auth().currentUser != nil
    @Published var userDisplayName: String? = Auth.auth().currentUser?.displayName
    @Published var errorMessage: String?

    init() {
        self.isAuthenticated = Auth.auth().currentUser != nil
        self.userDisplayName = Auth.auth().currentUser?.displayName
    }

    func signInWithGoogle() {
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Firebase client ID not found."
            print("Error: Firebase client ID not found.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Could not find root view controller."
            print("Error: Could not find root view controller for GIDSignIn.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self else { return }

            if let error {
                self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                print("Google Sign-In error: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google Sign-In failed: Could not retrieve ID token."
                print("Google Sign-In error: ID token or user not found.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error {
                    self.errorMessage = "Firebase Authentication failed: \(error.localizedDescription)"
                    print("Firebase Auth error: \(error.localizedDescription)")
                    return
                }
                self.isAuthenticated = true
                self.userDisplayName = authResult?.user.displayName
                print("Successfully signed in with Google and Firebase. User: \(self.userDisplayName ?? "N/A")")
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.isAuthenticated = false
            self.userDisplayName = nil
            print("Successfully signed out.")
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
            print("Error signing out: %@", signOutError)
        }
    }
}
