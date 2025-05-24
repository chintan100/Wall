//
//  WallView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI
import FirebaseAuth

struct WallView: View {
    
    @StateObject var wallViewModel = WallViewModel()
    @StateObject var userViewModel = UserViewModel()
    @ObservedObject var authViewModel: AuthenticationViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            Divider()
            
            VStack(spacing: 10) {
                
                TextField("Write something here...", text: $wallViewModel.newMessage, axis:.vertical)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .font(.system(size: 20))
                    .lineLimit(4)
                
//                HStack{
                    
                    Button(action: {
                        
                        wallViewModel.addPost()
                        
                    }) {
                        Text(wallViewModel.isAddingPost ? "Adding to the wall..." : "Add to the wall")
                            .frame(maxWidth: .infinity)
                            .frame(height: 23)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(wallViewModel.isAddingPost ? Color.gray : Color("ButtonColor"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(wallViewModel.isAddingPost)
                    
//                    Spacer()
//                }
            }
            .padding()
            
            Divider()
            
            // Posts List
            if wallViewModel.posts.isEmpty && wallViewModel.errorMessage == nil {
                
                Spacer()
                Text(wallViewModel.isMyPostsFilterActive ? "You haven't posted anything yet." : "No posts yet. Be the first!")
                    .foregroundColor(.gray)
                Spacer()
                
            }
            
            else {
                
                List {
                    
                    ForEach(wallViewModel.posts) { post in
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            HStack {
                                
                                ZStack { // Use ZStack for ProgressView overlay or fallback
                                    let user = userViewModel.usersCache[post.userId]
                                    let photoURLString = user?.photoURL
                                    
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
                                    } else if user != nil { // User data loaded, but no photoURL or it's invalid
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    } else { // User data not yet in cache (still fetching)
                                        ProgressView()
                                            .frame(width: 40, height: 40)
                                    }
                                    
                                    if let user = userViewModel.usersCache[post.userId], user.isOnline == true {
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if wallViewModel.canDeletePost(post) {
                                Button("Delete") {
                                    wallViewModel.deletePost(post)
                                }
                                .tint(.red)
                            }
                        }
                        .onAppear {
                            if post == wallViewModel.posts.last && wallViewModel.hasMorePosts {
                                wallViewModel.fetchMorePosts()
                            }
                        }
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
            
            if let errorMessage = wallViewModel.errorMessage {
                
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle("Wall")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            
            ToolbarItem(placement: .navigationBarLeading) {
                
                Button("Log Out") {
                    userViewModel.setUserOffline()
                    authViewModel.signOut()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    wallViewModel.toggleMyPostsFilter(userViewModel: userViewModel)
                } label: {
                    Image(systemName: wallViewModel.isMyPostsFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .onAppear {
            userViewModel.setUserOnline()
            wallViewModel.setUserViewModel(userViewModel)
        }
        .onDisappear {
            userViewModel.setUserOffline()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                userViewModel.setUserOnline()
            case .background, .inactive:
                userViewModel.setUserOffline()
            @unknown default:
                break
            }
        }
    }
}

struct WallView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        NavigationView {
            
            WallView(authViewModel: AuthenticationViewModel())
        }
    }
}
