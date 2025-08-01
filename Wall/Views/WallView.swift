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
            
            PostInputView(wallViewModel: wallViewModel)
            
            Divider()
            
            PostsListView(
                wallViewModel: wallViewModel,
                userViewModel: userViewModel
            )
            
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
                    wallViewModel.toggleMyPostsFilter()
                } label: {
                    Image(systemName: wallViewModel.isMyPostsFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
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
