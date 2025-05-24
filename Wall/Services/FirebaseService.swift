//
//  FirebaseService.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

protocol FirebaseServiceProtocol {
    func fetchPosts(limit: Int, startAfter: DocumentSnapshot?, filterByUser: String?) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?)
    func addPost(_ post: Post) async throws
    func deletePost(id: String) async throws
    func listenToPosts(limit: Int, filterByUser: String?, completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration
    func listenToPostsInRange(fromTimestamp: Timestamp, filterByUser: String?, completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration
    func fetchUsers(userIds: [String]) async throws -> [User]
    func updateUserStatus(userId: String, isOnline: Bool) async throws
    func listenToUserUpdates(completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration
}

class FirebaseService: FirebaseServiceProtocol {
    private let db = Firestore.firestore()
    
    func fetchPosts(limit: Int, startAfter: DocumentSnapshot? = nil, filterByUser: String? = nil) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?) {
        var query: Query = db.collection("posts").order(by: "timestamp", descending: true)
        
        if let filterByUser = filterByUser {
            query = query.whereField("userId", isEqualTo: filterByUser)
        }
        
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        query = query.limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        let posts = try snapshot.documents.compactMap { try $0.data(as: Post.self) }
        
        return (posts: posts, lastDocument: snapshot.documents.last)
    }
    
    func addPost(_ post: Post) async throws {
        _ = try db.collection("posts").addDocument(from: post)
    }
    
    func deletePost(id: String) async throws {
        try await db.collection("posts").document(id).delete()
    }
    
    func listenToPosts(limit: Int, filterByUser: String? = nil, completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration {
        var query: Query = db.collection("posts").order(by: "timestamp", descending: true).limit(to: limit)
        
        if let filterByUser = filterByUser {
            query = query.whereField("userId", isEqualTo: filterByUser)
        }
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                completion(.success(snapshot))
            }
        }
    }
    
    func listenToPostsInRange(fromTimestamp: Timestamp, filterByUser: String?, completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration {
        var query: Query = db.collection("posts")
            .whereField("timestamp", isGreaterThanOrEqualTo: fromTimestamp)
            .order(by: "timestamp", descending: true)
        
        if let filterByUser = filterByUser {
            query = query.whereField("userId", isEqualTo: filterByUser)
        }
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                completion(.success(snapshot))
            }
        }
    }
    
    func fetchUsers(userIds: [String]) async throws -> [User] {
        let chunks = userIds.chunked(into: 10)
        var allUsers: [User] = []
        
        for chunk in chunks {
            let snapshot = try await db.collection("users").whereField(FieldPath.documentID(), in: chunk).getDocuments()
            let users = try snapshot.documents.compactMap { try $0.data(as: User.self) }
            allUsers.append(contentsOf: users)
        }
        
        return allUsers
    }
    
    func updateUserStatus(userId: String, isOnline: Bool) async throws {
        try await db.collection("users").document(userId).updateData([
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: Date())
        ])
    }
    
    func listenToUserUpdates(completion: @escaping (Result<QuerySnapshot, Error>) -> Void) -> ListenerRegistration {
        return db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                completion(.success(snapshot))
            }
        }
    }
}
