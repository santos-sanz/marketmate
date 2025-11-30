import SwiftUI

struct AuthView: View {
  @EnvironmentObject var authVM: AuthViewModel
  @EnvironmentObject var themeManager: ThemeManager
  @State private var isSignUp = false
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      VStack(spacing: 24) {
        // Logo or Title
        Text("MarketMate")
          .font(.system(size: 40, weight: .bold, design: .rounded))
          .foregroundColor(textColor)
          .padding(.top, 60)

        Text(isSignUp ? "Create Account" : "Welcome Back")
          .font(.title2)
          .foregroundColor(textColor)

        VStack(spacing: 16) {
          TextField("", text: $authVM.email)
            .placeholder(when: authVM.email.isEmpty) {
              Text("Email").foregroundColor(secondaryTextColor)
            }
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .foregroundColor(textColor)

          SecureField("", text: $authVM.password)
            .placeholder(when: authVM.password.isEmpty) {
              Text("Password").foregroundColor(secondaryTextColor)
            }
            .textContentType(isSignUp ? .newPassword : .password)
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .foregroundColor(textColor)
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
              .progressViewStyle(CircularProgressViewStyle(tint: textColor))
          } else {
            Text(isSignUp ? "Sign Up" : "Log In")
              .font(.headline)
              .foregroundColor(textColor)
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(cardBackground)
        .cornerRadius(CornerRadius.xl)
        .padding(.horizontal)

        Button(action: {
          isSignUp.toggle()
        }) {
          Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
            .foregroundColor(secondaryTextColor)
        }

        Spacer()
      }
      .padding()
    }
  }
}
