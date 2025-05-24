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
import FirebaseFirestore

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = Auth.auth().currentUser != nil
    @Published var userDisplayName: String? = Auth.auth().currentUser?.displayName
    @Published var errorMessage: String?
    @Published var userPhotoURL: URL? = Auth.auth().currentUser?.photoURL

    private var db = Firestore.firestore()

    init() {
        self.isAuthenticated = Auth.auth().currentUser != nil
        self.userDisplayName = Auth.auth().currentUser?.displayName
        self.userPhotoURL = Auth.auth().currentUser?.photoURL
    }

    func signInWithGoogle(completion: (() -> Void)? = nil) {
        errorMessage = nil
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Firebase client ID not found."
            print("Error: Firebase client ID not found.")
            completion?()
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Could not find root view controller."
            print("Error: Could not find root view controller for GIDSignIn.")
            completion?()
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self else {
                completion?()
                return
            }

            if let error {
                self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                print("Google Sign-In error: \(error.localizedDescription)")
                completion?()
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google Sign-In failed: Could not retrieve ID token."
                print("Google Sign-In error: ID token or user not found.")
                completion?()
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                // Defer calling completion until the end of this block
                defer { completion?() }

                if let error {
                    self.errorMessage = "Firebase Authentication failed: \(error.localizedDescription)"
                    print("Firebase Auth error: \(error.localizedDescription)")
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    self.errorMessage = "Firebase authentication successful, but user object is nil."
                    print("Firebase auth user object is nil.")
                    return
                }
                
                self.saveOrUpdateUserInFirestore(firebaseUser: firebaseUser)

                self.isAuthenticated = true
                self.userDisplayName = firebaseUser.displayName
                self.userPhotoURL = firebaseUser.photoURL
                
                print("Successfully signed in with Google and Firebase. User: \(self.userDisplayName ?? "N/A")")
                print("Firebase User Info:")
                print("UID: \(firebaseUser.uid)")
                print("Email: \(firebaseUser.email ?? "N/A")")
                print("Display Name: \(firebaseUser.displayName ?? "N/A")")
                print("Photo URL: \(firebaseUser.photoURL?.absoluteString ?? "N/A")")
                print("Provider ID: \(firebaseUser.providerID)")
            }
        }
    }

    private func saveOrUpdateUserInFirestore(firebaseUser: FirebaseAuth.User) {
        let userRef = db.collection("users").document(firebaseUser.uid)
        let userData = User(
            uid: firebaseUser.uid,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString,
            isOnline: true,
            lastSeen: Timestamp(date: Date())
        )

        do {
            try userRef.setData(from: userData, merge: true) { error in
                if let error {
                    print("Error saving/updating user to Firestore: \(error.localizedDescription)")
                } else {
                    print("User data saved/updated in Firestore successfully.")
                }
            }
        } catch {
            print("Error encoding user data for Firestore: \(error.localizedDescription)")
        }
    }

    func signOut() {
        if let currentUserId = Auth.auth().currentUser?.uid {
            let userRef = db.collection("users").document(currentUserId)
            userRef.updateData([
                "isOnline": false,
                "lastSeen": Timestamp(date: Date())
            ])
        }
        
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.isAuthenticated = false
            self.userDisplayName = nil
            self.userPhotoURL = nil
            print("Successfully signed out.")
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
            print("Error signing out: %@", signOutError)
        }
    }
}
