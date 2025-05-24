//
//  WallView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI

struct WallView: View {
    
    @StateObject var wallViewModel = WallViewModel()
    @ObservedObject var authViewModel: AuthenticationViewModel
    
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
                Text("No posts yet. Be the first!")
                    .foregroundColor(.gray)
                Spacer()
                
            }
            
            else {
                
                List {
                    
                    ForEach(wallViewModel.posts) { post in
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            HStack {
                                
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading) {
                                    
                                    Text(post.userName)
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
                    authViewModel.signOut()
                }
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
