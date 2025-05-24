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
    @Published var isAddingPost: Bool = false

    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    init() {
        fetchPosts()
    }

    deinit {
        listenerRegistration?.remove()
    }

    func fetchPosts() {
        listenerRegistration?.remove()
        listenerRegistration = db.collection("posts")
                                  .order(by: "timestamp", descending: true)
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
            self.errorMessage = nil
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

        isAddingPost = true

        let post = Post(message: newMessage,
                        userName: userName,
                        userId: userId,
                        timestamp: Timestamp(date: Date()))

        do {
            _ = try db.collection("posts").addDocument(from: post) { error in
                // Uncomment the following lines to simulate a delay before updating the UI.
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isAddingPost = false
                    if let error {
                        self.errorMessage = "Error adding post: \(error.localizedDescription)"
                    } else {
                        self.newMessage = ""
                        self.errorMessage = nil
                    }
//                }
            }
        } catch {
            self.isAddingPost = false
            self.errorMessage = "Error encoding post for Firestore: \(error.localizedDescription)"
        }
    }
    
    func deletePost(_ post: Post) {
        guard let postId = post.id else {
            errorMessage = "Post ID is missing."
            return
        }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            return
        }
        
        guard post.userId == currentUserId else {
            errorMessage = "You can only delete your own posts."
            return
        }
        
        db.collection("posts").document(postId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.errorMessage = "Error deleting post: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    func canDeletePost(_ post: Post) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }
        return post.userId == currentUserId
    }

    func formattedDate(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
}
