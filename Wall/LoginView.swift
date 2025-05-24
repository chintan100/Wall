//
//  LoginView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject var authViewModel = AuthenticationViewModel()

    var body: some View {
        
        VStack {
            
            Divider()
            
            Spacer()

            Button(action: {
                authViewModel.signInWithGoogle()
            }) {
                HStack {
                    
                    Text("Sign In With Google")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 44)
                .background(Color("ButtonColor"))
                .foregroundColor(.white)
                .cornerRadius(22)
            }
            .padding(.horizontal, 40)

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top)
            }
            Spacer()
        }
        .navigationTitle("Wall")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
