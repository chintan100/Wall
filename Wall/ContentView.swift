//
//  ContentView.swift
//  Wall
//
//  Created by Chintan Patel on 24/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var authViewModel = AuthenticationViewModel()

    var body: some View {
        if authViewModel.isAuthenticated {
            WallView(authViewModel: authViewModel)
        } else {
            LoginView(authViewModel: authViewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
