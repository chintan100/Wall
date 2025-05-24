//
//  UserViewModel.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseFirestore

@MainActor
class UserViewModel: ObservableObject {
    @Published var usersCache: [String: User] = [:]
    @Published var errorMessage: String?
    
    private let userRepository: UserRepositoryProtocol
    private var userStatusListener: ListenerRegistration?
    
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
        listenToUserStatusUpdates()
    }
    
    deinit {
        userStatusListener?.remove()
        Task {
            try? await userRepository.updateUserOnlineStatus(isOnline: false)
        }
    }
    
    func setUserOnline() {
        Task {
            do {
                try await userRepository.updateUserOnlineStatus(isOnline: true)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func setUserOffline() {
        Task {
            do {
                try await userRepository.updateUserOnlineStatus(isOnline: false)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchUserProfiles(_ userIds: [String]) {
        guard !userIds.isEmpty else { return }
        
        // Filter out users we already have
        let uncachedUserIds = userIds.filter { !usersCache.keys.contains($0) }
        guard !uncachedUserIds.isEmpty else { return }
        
        Task {
            do {
                let users = try await userRepository.fetchUsers(userIds: uncachedUserIds)
                for user in users {
                    self.usersCache[user.uid] = user
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func listenToUserStatusUpdates() {
        userStatusListener = userRepository.listenToUserUpdates { [weak self] (result: Result<[User], Error>) in
            Task { @MainActor [weak self] in
                switch result {
                case .success(let users):
                    for user in users {
                        self?.usersCache[user.uid] = user
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
