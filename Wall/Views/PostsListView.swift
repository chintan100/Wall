//
//  PostsListView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI

struct PostsListView: View {
    @ObservedObject var wallViewModel: WallViewModel
    @ObservedObject var userViewModel: UserViewModel
    
    var body: some View {
        if wallViewModel.posts.isEmpty && wallViewModel.errorMessage == nil {
            EmptyStateView(
                isMyPostsFilter: wallViewModel.isMyPostsFilterActive,
                isLoading: wallViewModel.isLoadingPosts
            )
        } else {
            List {
                ForEach(wallViewModel.posts) { post in
                    PostRowView(
                        post: post,
                        wallViewModel: wallViewModel,
                        userViewModel: userViewModel
                    )
                }
                
                if wallViewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct EmptyStateView: View {
    let isMyPostsFilter: Bool
    let isLoading: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isLoading {
                ProgressView()
                Text("Loading messages...")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            } else {
                Text(isMyPostsFilter ? "You haven't posted anything yet." : "No posts yet. Be the first!")
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}
