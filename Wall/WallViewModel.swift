//
//  WallViewModel.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class WallViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var newMessage: String = ""
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    init() {
        fetchPosts()
    }

    deinit {
        listenerRegistration?.remove()
    }

    func fetchPosts() {
        listenerRegistration?.remove() // Remove previous listener
        listenerRegistration = db.collection("posts")
                                  .order(by: "timestamp", descending: false) // Ascending order as requested.
                                  .addSnapshotListener { querySnapshot, error in
            if let error {
                self.errorMessage = "Error fetching posts: \(error.localizedDescription)"
                print("Error fetching posts: \(error.localizedDescription)")
                return
            }

            guard let documents = querySnapshot?.documents else {
                self.errorMessage = "No posts found."
                print("No documents in posts collection")
                self.posts = []
                return
            }

            self.posts = documents.compactMap { document -> Post? in
                try? document.data(as: Post.self)
            }
            self.errorMessage = nil // Clear any previous error messages
        }
    }

    func addPost() {
        guard !newMessage.isEmpty else {
            errorMessage = "Message cannot be empty."
            return
        }

        guard let user = Auth.auth().currentUser,
              let userName = user.displayName else {
            errorMessage = "User not authenticated or display name is missing."
            return
        }
        let userId = user.uid

        let post = Post(message: newMessage,
                        userName: userName,
                        userId: userId,
                        timestamp: Timestamp(date: Date()))

        do {
            _ = try db.collection("posts").addDocument(from: post) { error in
                if let error {
                    self.errorMessage = "Error adding post: \(error.localizedDescription)"
                } else {
                    self.newMessage = "" // Clear the input field
                    self.errorMessage = nil
                }
            }
        } catch {
            self.errorMessage = "Error encoding post for Firestore: \(error.localizedDescription)"
        }
    }

    func formattedDate(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a" // e.g., "8:22 PM"
        return dateFormatter.string(from: date)
    }
}
