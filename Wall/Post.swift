//
//  Post.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import FirebaseFirestore

struct Post: Identifiable, Codable, Hashable {
    
    @DocumentID var id: String?
    var message: String
    var userName: String
    var userId: String 
    var timestamp: Timestamp

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}
