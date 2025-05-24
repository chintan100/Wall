//
//  PostRowView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI

struct PostRowView: View {
    let post: Post
    @ObservedObject var wallViewModel: WallViewModel
    @ObservedObject var userViewModel: UserViewModel
    
    @State private var isHighlighted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let user = userViewModel.usersCache[post.userId]
                let photoURLString = user?.photoURL
                
                UserAvatarView(user: user, photoURLString: photoURLString, userViewModel: userViewModel)
                
                VStack(alignment: .leading) {
                    Text(userViewModel.usersCache[post.userId]?.displayName ?? post.userName)
                        .font(.headline)
                    Text(post.message)
                        .font(.body)
                }
                
                Spacer()
                
                Text(wallViewModel.formattedDate(from: post.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(isHighlighted ? Color.green.opacity(0.25) : Color.clear)
                .animation(.easeOut(duration: 0.5), value: isHighlighted)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if wallViewModel.canDeletePost(post) {
                Button("Delete") {
                    wallViewModel.deletePost(post)
                }
                .tint(.red)
            }
        }
        .onAppear {
            let postAge = Date().timeIntervalSince(post.timestamp.dateValue())
            if postAge < 5.0 {
                isHighlighted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isHighlighted = false
                }
            }
            
            if post == wallViewModel.posts.last && wallViewModel.hasMorePosts {
                wallViewModel.fetchMorePosts()
            }
            
            if userViewModel.usersCache[post.userId] == nil {
                userViewModel.fetchUserProfiles([post.userId])
            }
        }
    }
}
