//
//  UserRepository.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol UserRepositoryProtocol {
    func fetchUsers(userIds: [String]) async throws -> [User]
    func updateUserOnlineStatus(isOnline: Bool) async throws
    func listenToUserUpdates(completion: @escaping (Result<[User], Error>) -> Void) -> ListenerRegistration?
}

class UserRepository: UserRepositoryProtocol {
    private let firebaseService: FirebaseServiceProtocol
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }
    
    func fetchUsers(userIds: [String]) async throws -> [User] {
        return try await firebaseService.fetchUsers(userIds: userIds)
    }
    
    func updateUserOnlineStatus(isOnline: Bool) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw UserError.userNotAuthenticated
        }
        
        try await firebaseService.updateUserStatus(userId: currentUserId, isOnline: isOnline)
    }
    
    func listenToUserUpdates(completion: @escaping (Result<[User], Error>) -> Void) -> ListenerRegistration? {
        return firebaseService.listenToUserUpdates { result in
            switch result {
            case .success(let snapshot):
                let users = snapshot.documents.compactMap { document -> User? in
                    try? document.data(as: User.self)
                }
                completion(.success(users))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

enum UserError: LocalizedError {
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated."
        }
    }
}
