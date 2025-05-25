//
//  LoginView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    @State private var isSigningIn = false

    var body: some View {
        
        VStack {
            
            Divider()
            
            Spacer()

            Button(action: {
                isSigningIn = true
                authViewModel.signInWithGoogle {
                    isSigningIn = false
                }
            }) {
                HStack {
                    if isSigningIn {
                        
                        Text("Signing In...")
                            .fontWeight(.bold)
                            .padding(.leading, 5)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In With Google")
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 44)
                .background(Color("ButtonColor"))
                .foregroundColor(.white)
                .cornerRadius(22)
            }
            .accessibilityIdentifier("signInWithGoogleButton")
            .disabled(isSigningIn)
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
        .onAppear {
            authViewModel.errorMessage = nil
        }
        .onChange(of: isSigningIn) { _, newValue in
            if newValue {
                authViewModel.errorMessage = nil
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authViewModel: AuthenticationViewModel())
    }
}
