//
//  PostInputView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI

struct PostInputView: View {
    @ObservedObject var wallViewModel: WallViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            TextField("Write something here...", text: $wallViewModel.newMessage, axis: .vertical)
                .textFieldStyle(DefaultTextFieldStyle())
                .font(.system(size: 20))
                .lineLimit(4)
                .accessibilityIdentifier("postInputTextField")
            
            Button(action: {
                hideKeyboard()
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
            .accessibilityIdentifier("postButton")
            .disabled(wallViewModel.isAddingPost)
        }
        .padding()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
