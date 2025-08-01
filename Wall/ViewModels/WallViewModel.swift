//
//  WallViewModel.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class WallViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var newMessage: String = ""
    @Published var errorMessage: String?
    @Published var isAddingPost: Bool = false
    @Published var isLoadingMore = false
    @Published var hasMorePosts = true
    @Published var isMyPostsFilterActive: Bool = false
    @Published var isLoadingPosts = false
    
    private let postRepository: PostRepositoryProtocol
    private var listenerRegistration: ListenerRegistration?
    private var lastDocumentSnapshot: DocumentSnapshot?
    private let postsLimit = 10
    
    init(postRepository: PostRepositoryProtocol = PostRepository()) {
        self.postRepository = postRepository
        fetchPosts()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func toggleMyPostsFilter() {
        isMyPostsFilterActive.toggle()
        fetchPosts()
    }
    
    func fetchPosts() {
        listenerRegistration?.remove()
        if posts.isEmpty {
            isLoadingPosts = true
        }
        lastDocumentSnapshot = nil
        hasMorePosts = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await postRepository.fetchPosts(
                    limit: postsLimit,
                    startAfter: nil,
                    filterByCurrentUser: isMyPostsFilterActive
                )
                
                self.posts = result.posts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                self.lastDocumentSnapshot = result.lastDocument
                self.hasMorePosts = result.posts.count == postsLimit
                self.isLoadingPosts = false
                
                self.setupRealtimeListener()
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingPosts = false
            }
        }
    }
    
    private func setupRealtimeListener() {
        listenerRegistration = postRepository.listenToPosts(
            limit: postsLimit,
            filterByCurrentUser: isMyPostsFilterActive
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                switch result {
                case .success(let fetchedPosts):
                    // Only update if we have new posts that aren't already in our list
                    let sortedPosts = fetchedPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    let newPosts = sortedPosts.filter { newPost in
                        !(self?.posts.contains(where: { $0.id == newPost.id }) ?? false)
                    }
                    
                    if !newPosts.isEmpty {
                        self?.posts = sortedPosts
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func fetchMorePosts() {
        guard !isLoadingMore, hasMorePosts, let lastSnapshot = lastDocumentSnapshot else { return }
        
        isLoadingMore = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await postRepository.fetchPosts(
                    limit: postsLimit,
                    startAfter: lastSnapshot,
                    filterByCurrentUser: isMyPostsFilterActive
                )
                
                self.posts.append(contentsOf: result.posts)
                self.lastDocumentSnapshot = result.lastDocument
                self.hasMorePosts = result.posts.count == postsLimit
                
                self.expandListenerRange()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            
            self.isLoadingMore = false
        }
    }
    
    private func expandListenerRange() {
        guard let oldestPost = posts.last else { return }
        
        listenerRegistration?.remove()
        
        // Listen to all posts from the oldest loaded post to newest
        let filterUserId = isMyPostsFilterActive ? Auth.auth().currentUser?.uid : nil
        
        listenerRegistration = postRepository.listenToPostsInRange(
            fromTimestamp: oldestPost.timestamp,
            filterByUser: filterUserId
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                switch result {
                case .success(let fetchedPosts):
                    // Replace all posts with the updated list
                    self?.posts = fetchedPosts.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addPost() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = PostError.emptyMessage.localizedDescription
            return
        }
        
        isAddingPost = true
        
        Task {
            do {
                try await postRepository.addPost(message: newMessage)
                self.newMessage = ""
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            
            self.isAddingPost = false
        }
    }
    
    func deletePost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            _ = withAnimation {
                posts.remove(at: index)
            }
        }
        
        Task {
            do {
                try await postRepository.deletePost(post)
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func canDeletePost(_ post: Post) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
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
