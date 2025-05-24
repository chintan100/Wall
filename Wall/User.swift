import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String? // Firestore document ID, will be the user's UID
    var uid: String             // Explicitly store UID for potential querying, should match id
    var displayName: String?
    var photoURL: String?       // Store photo URL as a String

    // For future use, as you mentioned
    var isOnline: Bool?
    var lastSeen: Timestamp?

    // Conformance for Equatable if needed, e.g., for diffing in arrays
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
