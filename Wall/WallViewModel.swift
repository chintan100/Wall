//
//  WallViewModel.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

class WallViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var newMessage: String = ""
    @Published var errorMessage: String?
    @Published var isAddingPost: Bool = false
    @Published var isLoadingMore = false
    private var lastDocumentSnapshot: DocumentSnapshot?
    @Published var hasMorePosts = true
    @Published var isMyPostsFilterActive: Bool = false
    
    private var userViewModel: UserViewModel?

    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private let postsLimit = 10
    private var isSettingUpFirstPage: Bool = false
    private var userIdsToFetchFromSnapshot: Set<String> = []

    init() {
        fetchPosts()
    }

    deinit {
        listenerRegistration?.remove()
    }

    func setUserViewModel(_ userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
    }

    func toggleMyPostsFilter(userViewModel: UserViewModel) {
        isMyPostsFilterActive.toggle()
        userViewModel.usersCache = [:]
        fetchPosts()
    }

    func fetchPosts() {
        listenerRegistration?.remove()

        self.posts = []
        self.lastDocumentSnapshot = nil
        self.hasMorePosts = true
        self.errorMessage = nil
        self.isSettingUpFirstPage = true
        self.userIdsToFetchFromSnapshot = []

        var query: Query = db.collection("posts")

        if isMyPostsFilterActive, let currentUserID = Auth.auth().currentUser?.uid {
            query = query.whereField("userId", isEqualTo: currentUserID)
        }

        let initialQuery = query
            .order(by: "timestamp", descending: true)
            .limit(to: postsLimit)

        listenerRegistration = initialQuery.addSnapshotListener { querySnapshot, error in
            if let error {
                self.errorMessage = "Error fetching posts: \(error.localizedDescription)"
                print("Error fetching posts: \(error.localizedDescription)")
                self.isSettingUpFirstPage = false
                return
            }

            guard let snapshot = querySnapshot else {
                self.errorMessage = "No snapshot data received."
                print("No snapshot data in posts listener")
                self.isSettingUpFirstPage = false
                return
            }

            snapshot.documentChanges.forEach { diff in
                guard let changedPost = try? diff.document.data(as: Post.self) else {
                    print("Failed to decode post from document change")
                    return
                }
                if let userViewModel = self.userViewModel, !userViewModel.usersCache.keys.contains(changedPost.userId) {
                     self.userIdsToFetchFromSnapshot.insert(changedPost.userId)
                }
                
                switch diff.type {
                case .added:
                    if !self.posts.contains(where: { $0.id == changedPost.id }) {
                        self.posts.append(changedPost)
                    }
                case .modified:
                    if let index = self.posts.firstIndex(where: { $0.id == changedPost.id }) {
                        self.posts[index] = changedPost
                    } else {
                        print("Received .modified for a post not in the list: \(changedPost.id ?? "unknown_id")")
                    }
                case .removed:
                    self.posts.removeAll(where: { $0.id == changedPost.id })
                }
            }

            self.posts.sort(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
            
            if !self.userIdsToFetchFromSnapshot.isEmpty, let userViewModel = self.userViewModel {
                userViewModel.fetchUserProfiles(Array(self.userIdsToFetchFromSnapshot))
            }
            
            if self.isSettingUpFirstPage {
                self.lastDocumentSnapshot = snapshot.documents.last
                self.hasMorePosts = snapshot.documents.count == self.postsLimit
                self.isSettingUpFirstPage = false
            }
            
            self.errorMessage = nil
        }
    }

    func fetchMorePosts() {
        guard !isLoadingMore, hasMorePosts, let lastSnapshot = lastDocumentSnapshot else {
            if !hasMorePosts {
                print("No more posts to fetch.")
            }
            if isLoadingMore {
                print("Already loading more posts.")
            }
            return
        }

        isLoadingMore = true
        errorMessage = nil

        var query: Query = db.collection("posts")

        if isMyPostsFilterActive, let currentUserID = Auth.auth().currentUser?.uid {
            query = query.whereField("userId", isEqualTo: currentUserID)
        }

        let paginatedQuery = query
            .order(by: "timestamp", descending: true)
            .start(afterDocument: lastSnapshot)
            .limit(to: postsLimit)

        paginatedQuery.getDocuments { querySnapshot, error in
            defer { self.isLoadingMore = false }

            if let error {
                self.errorMessage = "Error fetching more posts: \(error.localizedDescription)"
                print("Error fetching more posts: \(error.localizedDescription)")
                return
            }

            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                self.hasMorePosts = false
                print("No more documents in pagination.")
                return
            }

            let newPosts = documents.compactMap { document -> Post? in
                try? document.data(as: Post.self)
            }
            let newUserIds = Set(newPosts.map { $0.userId })
            let userIdsToFetch = newUserIds.filter { self.userViewModel?.usersCache.keys.contains($0) == false }
            if !userIdsToFetch.isEmpty {
                self.userViewModel?.fetchUserProfiles(Array(userIdsToFetch))
            }

            self.posts.append(contentsOf: newPosts)
            self.lastDocumentSnapshot = documents.last
            self.hasMorePosts = documents.count == self.postsLimit
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
                self.isAddingPost = false
                if let error {
                    self.errorMessage = "Error adding post: \(error.localizedDescription)"
                } else {
                    self.newMessage = ""
                    self.errorMessage = nil
                }
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
        
        if let index = self.posts.firstIndex(where: { $0.id == postId }) {
            _ = withAnimation {
                self.posts.remove(at: index)
            }
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
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
