import SwiftUI

struct AuthView: View {
  @StateObject private var authVM = AuthViewModel()
  @State private var isSignUp = false

  var body: some View {
    ZStack {
      Color.marketBlack.edgesIgnoringSafeArea(.all)

      VStack(spacing: 24) {
        // Logo or Title
        Text("MarketMate")
          .font(.system(size: 40, weight: .bold, design: .rounded))
          .foregroundColor(.marketGreen)
          .padding(.top, 60)

        Text(isSignUp ? "Create Account" : "Welcome Back")
          .font(.title2)
          .foregroundColor(.white)

        VStack(spacing: 16) {
          TextField("Email", text: $authVM.email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .background(Color.marketCard)
            .cornerRadius(12)
            .foregroundColor(.white)

          SecureField("Password", text: $authVM.password)
            .textContentType(isSignUp ? .newPassword : .password)
            .padding()
            .background(Color.marketCard)
            .cornerRadius(12)
            .foregroundColor(.white)
        }
        .padding(.horizontal)

        if let errorMessage = authVM.errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
            .font(.caption)
        }

        Button(action: {
          Task {
            if isSignUp {
              await authVM.signUp()
            } else {
              await authVM.signIn()
            }
          }
        }) {
          if authVM.isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .marketBlack))
          } else {
            Text(isSignUp ? "Sign Up" : "Log In")
              .font(.headline)
              .foregroundColor(.marketBlack)
          }
        }
        .primaryButtonStyle()
        .padding(.horizontal)

        Button(action: {
          isSignUp.toggle()
        }) {
          Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
            .foregroundColor(.marketGreen)
        }

        Spacer()
      }
      .padding()
    }
  }
}
