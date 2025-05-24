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
            Spacer()
            Text("Wall")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 50)

            Button(action: {
                authViewModel.signInWithGoogle()
            }) {
                HStack {
                    
                    Text("Sign In With Google")
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding(.horizontal, 40)

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top)
            }
            Spacer()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
