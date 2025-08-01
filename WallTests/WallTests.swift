//
//  WallTests.swift
//  WallTests
//
//  Created by Chintan Patel on 24/05/25.
//

import Testing
import FirebaseFirestore
@testable import Wall

// MARK: - Mock Classes

class MockPostRepository: PostRepositoryProtocol {
    var fetchPostsResult: Result<(posts: [Post], lastDocument: DocumentSnapshot?), Error> = .success((posts: [], lastDocument: nil))
    var addPostResult: Result<Void, Error> = .success(())
    var deletePostResult: Result<Void, Error> = .success(())
    
    var fetchPostsCalled = false
    var addPostCalled = false
    var deletePostCalled = false
    var listenToPostsCalled = false
    
    var lastFetchLimit: Int?
    var lastAddMessage: String?
    var lastDeletePost: Post?
    
    private var posts: [Post] = []
    private var listenersCompletion: [(Result<[Post], Error>) -> Void] = []
    
    func fetchPosts(limit: Int, startAfter: DocumentSnapshot?, filterByCurrentUser: Bool) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?) {
        fetchPostsCalled = true
        lastFetchLimit = limit
        return try fetchPostsResult.get()
    }
    
    func addPost(message: String) async throws {
        addPostCalled = true
        lastAddMessage = message
        try addPostResult.get()
        
        let newPost = Post(
            id: UUID().uuidString,
            message: message,
            userName: "Test User",
            userId: "test-user-id",
            timestamp: Timestamp(date: Date())
        )
        posts.append(newPost)
        
        Task { @MainActor in
            // Notify all listeners
            for completion in listenersCompletion {
                completion(.success(posts))
            }
        }
    }
    
    func deletePost(_ post: Post) async throws {
        deletePostCalled = true
        lastDeletePost = post
        try deletePostResult.get()
    }
    
    func listenToPosts(limit: Int, filterByCurrentUser: Bool, completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration? {
        listenToPostsCalled = true
        listenersCompletion.append(completion)
        return nil
    }
    
    func listenToPostsInRange(fromTimestamp: Timestamp, filterByUser: String?, completion: @escaping (Result<[Post], Error>) -> Void) -> ListenerRegistration? {
        return nil
    }
}

class MockUserRepository: UserRepositoryProtocol {
    var fetchUsersResult: Result<[User], Error> = .success([])
    var updateUserOnlineStatusResult: Result<Void, Error> = .success(())
    
    var fetchUsersCalled = false
    var updateUserOnlineStatusCalled = false
    var listenToUserUpdatesCalled = false
    
    var lastFetchUserIds: [String]?
    var lastOnlineStatus: Bool?
    
    func fetchUsers(userIds: [String]) async throws -> [User] {
        fetchUsersCalled = true
        lastFetchUserIds = userIds
        return try fetchUsersResult.get()
    }
    
    func updateUserOnlineStatus(isOnline: Bool) async throws {
        updateUserOnlineStatusCalled = true
        lastOnlineStatus = isOnline
        try updateUserOnlineStatusResult.get()
    }
    
    func listenToUserUpdates(completion: @escaping (Result<[User], Error>) -> Void) -> ListenerRegistration? {
        listenToUserUpdatesCalled = true
        return nil
    }
}

// MARK: - Test Structs

struct WallViewModelTests {
    
    @Test func testInitialState() async {
        let mockRepo = MockPostRepository()
        let viewModel = await WallViewModel(postRepository: mockRepo)
        
        await MainActor.run {
            #expect(viewModel.posts.isEmpty)
            #expect(viewModel.newMessage.isEmpty)
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.isAddingPost == false)
            #expect(viewModel.isLoadingMore == false)
            #expect(viewModel.hasMorePosts == true)
            #expect(viewModel.isMyPostsFilterActive == false)
        }
    }
    
    @Test func testToggleMyPostsFilter() async {
        let mockRepo = MockPostRepository()
        let viewModel = await WallViewModel(postRepository: mockRepo)
        
        await MainActor.run {
            #expect(viewModel.isMyPostsFilterActive == false)
            viewModel.toggleMyPostsFilter()
            #expect(viewModel.isMyPostsFilterActive == true)
            viewModel.toggleMyPostsFilter()
            #expect(viewModel.isMyPostsFilterActive == false)
        }
    }
    
    @Test func testAddPostWithEmptyMessage() async {
        let mockRepo = MockPostRepository()
        let viewModel = await WallViewModel(postRepository: mockRepo)
        
        await MainActor.run {
            viewModel.newMessage = ""
            viewModel.addPost()
            #expect(viewModel.errorMessage?.contains("empty") == true)
            #expect(mockRepo.addPostCalled == false)
        }
    }
    
    @Test func testAddPostWithValidMessage() async {
        let mockRepo = MockPostRepository()
        let viewModel = await WallViewModel(postRepository: mockRepo)
        
        await MainActor.run {
            viewModel.newMessage = "Test message 1"
            viewModel.addPost()
            
            sleep(1)
            viewModel.newMessage = "Test message 2"
            viewModel.addPost()
            
            #expect(viewModel.isAddingPost == true)
        }
        
        sleep(2)
        
        await MainActor.run {
            #expect(mockRepo.addPostCalled == true)
            #expect(mockRepo.lastAddMessage == "Test message 2")
            #expect(viewModel.isAddingPost == false)
            #expect(viewModel.posts.count == 2)
            #expect(viewModel.newMessage.isEmpty)
        }
    }
    
    @Test func testAddPostWithRealRepository() async {
        let realRepo = PostRepository()
        let viewModel = await WallViewModel(postRepository: realRepo)
        
        await MainActor.run {
            viewModel.newMessage = "Test integration message"
            viewModel.addPost()
            #expect(viewModel.isAddingPost == true)
        }
        
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            // Should fail because no authenticated user
            #expect(viewModel.errorMessage?.contains("authenticated") == true)
            #expect(viewModel.isAddingPost == false)
            #expect(viewModel.posts.isEmpty)
            #expect(viewModel.newMessage == "Test integration message") // Message should remain
        }
    }
}

struct UserViewModelTests {
    
    @Test func testInitialState() async {
        let mockRepo = MockUserRepository()
        let viewModel = await UserViewModel(userRepository: mockRepo)
        
        await MainActor.run {
            #expect(viewModel.usersCache.isEmpty)
            #expect(viewModel.errorMessage == nil)
            #expect(mockRepo.listenToUserUpdatesCalled == true)
        }
    }
    
    @Test func testSetUserOnline() async {
        let mockRepo = MockUserRepository()
        let viewModel = await UserViewModel(userRepository: mockRepo)
        
        await MainActor.run {
            viewModel.setUserOnline()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockRepo.updateUserOnlineStatusCalled == true)
        #expect(mockRepo.lastOnlineStatus == true)
    }
    
    @Test func testSetUserOffline() async {
        let mockRepo = MockUserRepository()
        let viewModel = await UserViewModel(userRepository: mockRepo)
        
        await MainActor.run {
            viewModel.setUserOffline()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockRepo.updateUserOnlineStatusCalled == true)
        #expect(mockRepo.lastOnlineStatus == false)
    }
    
    @Test func testFetchUserProfiles() async {
        let mockRepo = MockUserRepository()
        let testUsers = [
            User(uid: "user1", displayName: "User 1", photoURL: nil, isOnline: true, lastSeen: nil),
            User(uid: "user2", displayName: "User 2", photoURL: nil, isOnline: false, lastSeen: nil)
        ]
        mockRepo.fetchUsersResult = .success(testUsers)
        
        let viewModel = await UserViewModel(userRepository: mockRepo)
        
        await MainActor.run {
            viewModel.fetchUserProfiles(["user1", "user2"])
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockRepo.fetchUsersCalled == true)
        #expect(mockRepo.lastFetchUserIds == ["user1", "user2"])
        
        await MainActor.run {
            #expect(viewModel.usersCache.count == 2)
            #expect(viewModel.usersCache["user1"]?.displayName == "User 1")
            #expect(viewModel.usersCache["user2"]?.displayName == "User 2")
        }
    }
    
    @Test func testFetchUserProfilesSkipsEmpty() async {
        let mockRepo = MockUserRepository()
        let viewModel = await UserViewModel(userRepository: mockRepo)
        
        await MainActor.run {
            viewModel.fetchUserProfiles([])
        }
        
        #expect(mockRepo.fetchUsersCalled == false)
    }
    
    @Test func testFetchUserProfilesSkipsCached() async {
        let mockRepo = MockUserRepository()
        let viewModel = await UserViewModel(userRepository: mockRepo)
        
        await MainActor.run {
            // Pre-populate cache
            let cachedUser = User(uid: "user1", displayName: "Cached User", photoURL: nil, isOnline: true, lastSeen: nil)
            viewModel.usersCache["user1"] = cachedUser
            
            viewModel.fetchUserProfiles(["user1"])
        }
        
        #expect(mockRepo.fetchUsersCalled == false)
    }
}

struct PostRepositoryTests {
    
    @Test func testAddPostError() async {
        let postRepo = PostRepository(firebaseService: FirebaseService())
        
        do {
            // Should fail because no authenticated user
            try await postRepo.addPost(message: "Test message")
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is PostError)
            if let postError = error as? PostError {
                #expect(postError == PostError.userNotAuthenticated)
            }
        }
    }
}

struct PostErrorTests {
    
    @Test func testPostErrorDescriptions() {
        #expect(PostError.userNotAuthenticated.errorDescription?.contains("authenticated") == true)
        #expect(PostError.invalidPostId.errorDescription?.contains("ID") == true)
        #expect(PostError.unauthorizedAccess.errorDescription?.contains("own posts") == true)
        #expect(PostError.emptyMessage.errorDescription?.contains("empty") == true)
    }
}

struct UserErrorTests {
    
    @Test func testUserErrorDescriptions() {
        #expect(UserError.userNotAuthenticated.errorDescription?.contains("authenticated") == true)
    }
}

struct PostModelTests {
    
    @Test func testPostEquality() {
        let post1 = Post(id: "1", message: "Test", userName: "User", userId: "user1", timestamp: Timestamp())
        let post2 = Post(id: "1", message: "Different", userName: "Different", userId: "user2", timestamp: Timestamp())
        let post3 = Post(id: "2", message: "Test", userName: "User", userId: "user1", timestamp: Timestamp())
        
        #expect(post1 == post2) // Same ID
        #expect(post1 != post3) // Different ID
    }
    
    @Test func testPostHashing() {
        let post1 = Post(id: "1", message: "Test", userName: "User", userId: "user1", timestamp: Timestamp())
        let post2 = Post(id: "1", message: "Different", userName: "Different", userId: "user2", timestamp: Timestamp())
        
        #expect(post1.hashValue == post2.hashValue) // Same ID should hash the same
    }
}

struct UserModelTests {
    
    @Test func testUserEquality() {
        let user1 = User(id: "1", uid: "user1", displayName: "User 1", photoURL: nil, isOnline: true, lastSeen: nil)
        let user2 = User(id: "1", uid: "user2", displayName: "User 2", photoURL: nil, isOnline: false, lastSeen: nil)
        let user3 = User(id: "2", uid: "user1", displayName: "User 1", photoURL: nil, isOnline: true, lastSeen: nil)
        
        #expect(user1 == user2) // Same ID
        #expect(user1 != user3) // Different ID
    }
}
