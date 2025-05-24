//
//  UserAvatarView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseAuth

struct UserAvatarView: View {
    let user: User?
    let photoURLString: String?
    @ObservedObject var userViewModel: UserViewModel
    
    var body: some View {
        ZStack {
            if let urlString = photoURLString, let photoDisplayURL = URL(string: urlString) {
                AsyncImage(url: photoDisplayURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: 40, height: 40)
                             .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                            .frame(width: 40, height: 40)
                    }
                }
            } else if user != nil {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            } else {
                ProgressView()
                    .frame(width: 40, height: 40)
            }
            
            if let userId = user?.uid,
               let cachedUser = userViewModel.usersCache[userId],
               cachedUser.isOnline == true,
               cachedUser.uid != Auth.auth().currentUser?.uid {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 15, y: -15)
            }
        }
    }
}
