//
//  UserViewModel.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var usersCache: [String: User] = [:]
    
    private var db = Firestore.firestore()
    private var userStatusListener: ListenerRegistration?
    
    init() {
        listenToUserStatusUpdates()
    }
    
    deinit {
        userStatusListener?.remove()
        setUserOffline()
    }
    
    func setUserOnline() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = db.collection("users").document(currentUserId)
        userRef.updateData([
            "isOnline": true,
            "lastSeen": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error setting user online: \(error.localizedDescription)")
            }
        }
    }
    
    func setUserOffline() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = db.collection("users").document(currentUserId)
        userRef.updateData([
            "isOnline": false,
            "lastSeen": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error setting user offline: \(error.localizedDescription)")
            }
        }
    }
    
    private func listenToUserStatusUpdates() {
        userStatusListener = db.collection("users").addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening to user status updates: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = querySnapshot else { return }
            
            snapshot.documentChanges.forEach { diff in
                guard let updatedUser = try? diff.document.data(as: User.self) else { return }
                
                switch diff.type {
                case .added, .modified:
                    self.usersCache[updatedUser.uid] = updatedUser
                case .removed:
                    self.usersCache.removeValue(forKey: updatedUser.uid)
                }
            }
        }
    }
    
    func fetchUserProfiles(_ userIds: [String]) {
        guard !userIds.isEmpty else { return }

        let dbUsers = db.collection("users")
        let chunks = userIds.chunked(into: 10)

        for chunk in chunks {
            guard !chunk.isEmpty else { continue }
            
            dbUsers.whereField(FieldPath.documentID(), in: chunk).getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching user profiles for chunk \(chunk.joined(separator: ", ")): \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No documents found for user profile chunk \(chunk.joined(separator: ", ")).")
                    return
                }

                for document in documents {
                    do {
                        let user = try document.data(as: User.self)
                        self.usersCache[user.uid] = user
                    } catch {
                        print("Error decoding user profile for \(document.documentID): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}