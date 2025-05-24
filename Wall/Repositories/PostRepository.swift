//
//  PostRepository.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol PostRepositoryProtocol {
    func fetchPosts(limit: Int, startAfter: DocumentSnapshot?, filterByCurrentUser: Bool) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?)
    func addPost(message: String) async throws
    func deletePost(_ post: Post) async throws
    func listenToPosts(limit: Int, filterByCurrentUser: Bool, completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration?
    func listenToPostsInRange(fromTimestamp: Timestamp, filterByUser: String?, completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration?
}

class PostRepository: PostRepositoryProtocol {
    private let firebaseService: FirebaseServiceProtocol
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }
    
    func fetchPosts(limit: Int, startAfter: DocumentSnapshot?, filterByCurrentUser: Bool) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?) {
        let filterUserId = filterByCurrentUser ? Auth.auth().currentUser?.uid : nil
        return try await firebaseService.fetchPosts(limit: limit, startAfter: startAfter, filterByUser: filterUserId)
    }
    
    func addPost(message: String) async throws {
        guard let user = Auth.auth().currentUser,
              let userName = user.displayName else {
            throw PostError.userNotAuthenticated
        }
        
        let post = Post(
            message: message,
            userName: userName,
            userId: user.uid,
            timestamp: Timestamp(date: Date())
        )
        
        try await firebaseService.addPost(post)
    }
    
    func deletePost(_ post: Post) async throws {
        guard let postId = post.id else {
            throw PostError.invalidPostId
        }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw PostError.userNotAuthenticated
        }
        
        guard post.userId == currentUserId else {
            throw PostError.unauthorizedAccess
        }
        
        try await firebaseService.deletePost(id: postId)
    }
    
    func listenToPosts(limit: Int, filterByCurrentUser: Bool, completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration? {
        let filterUserId = filterByCurrentUser ? Auth.auth().currentUser?.uid : nil
        
        return firebaseService.listenToPosts(limit: limit, filterByUser: filterUserId) { result in
            switch result {
            case .success(let snapshot):
                let posts = snapshot.documents.compactMap { document -> Post? in
                    try? document.data(as: Post.self)
                }
                completion(.success(posts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func listenToPostsInRange(fromTimestamp: Timestamp, filterByUser: String?, completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration? {
        return firebaseService.listenToPostsInRange(fromTimestamp: fromTimestamp, filterByUser: filterByUser) { result in
            switch result {
            case .success(let snapshot):
                let posts = snapshot.documents.compactMap { document -> Post? in
                    try? document.data(as: Post.self)
                }
                completion(.success(posts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

enum PostError: LocalizedError {
    case userNotAuthenticated
    case invalidPostId
    case unauthorizedAccess
    case emptyMessage
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated or display name is missing."
        case .invalidPostId:
            return "Post ID is missing."
        case .unauthorizedAccess:
            return "You can only delete your own posts."
        case .emptyMessage:
            return "Message cannot be empty."
        }
    }
}
