import SwiftUI

struct AuthView: View {
  @EnvironmentObject var authVM: AuthViewModel
  @State private var isSignUp = false

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      VStack(spacing: 24) {
        // Logo or Title
        Text("MarketMate")
          .font(.system(size: 40, weight: .bold, design: .rounded))
          .foregroundColor(.white)
          .padding(.top, 60)

        Text(isSignUp ? "Create Account" : "Welcome Back")
          .font(.title2)
          .foregroundColor(.white)

        VStack(spacing: 16) {
          TextField("", text: $authVM.email)
            .placeholder(when: authVM.email.isEmpty) {
              Text("Email").foregroundColor(Color.white.opacity(0.6))
            }
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .background(Color.marketCard)
            .cornerRadius(12)
            .foregroundColor(.white)

          SecureField("", text: $authVM.password)
            .placeholder(when: authVM.password.isEmpty) {
              Text("Password").foregroundColor(Color.white.opacity(0.6))
            }
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
              .progressViewStyle(CircularProgressViewStyle(tint: .black))
          } else {
            Text(isSignUp ? "Sign Up" : "Log In")
              .font(.headline)
              .foregroundColor(.black)
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(CornerRadius.xl)
        .padding(.horizontal)

        Button(action: {
          isSignUp.toggle()
        }) {
          Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
            .foregroundColor(.white)
        }

        Spacer()
      }
      .padding()
    }
  }
}
