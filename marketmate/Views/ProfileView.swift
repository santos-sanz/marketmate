import SwiftUI
import UIKit

struct ProfileView: View {
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var authVM: AuthViewModel

  @State private var showingShareSheet = false
  @State private var exportURL: URL?
  @State private var showingDeleteAlert = false
  @State private var showingFeedback = false

  let currencies = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD"]

  var body: some View {
    NavigationView {
      ZStack {
        // Gradient Background
        Color.clear.revolutBackground()

        if profileVM.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
        } else {
          ScrollView {
            VStack(spacing: Spacing.lg) {
              // Profile Header
              VStack(spacing: Spacing.sm) {
                Image(systemName: "person.crop.circle.fill")
                  .resizable()
                  .frame(width: 80, height: 80)
                  .foregroundColor(.marketTextSecondary)
                  .padding(.top, Spacing.md)  // Minimal top padding

                Text(authVM.currentUserEmail ?? "User")
                  .font(Typography.title3)
                  .foregroundColor(.white)
              }
              .frame(maxWidth: .infinity)

              // Settings Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Settings")
                  .font(Typography.subheadline)
                  .foregroundColor(.marketTextSecondary)
                  .padding(.horizontal, Spacing.xs)

                VStack(spacing: 0) {
                  // Currency Picker Row
                  Menu {
                    Picker("Currency", selection: $profileVM.selectedCurrency) {
                      ForEach(currencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                      }
                    }
                  } label: {
                    ProfileRow(
                      icon: "banknote", title: "Currency", value: profileVM.selectedCurrency)
                  }
                }
                .marketCardStyle()
              }
              .padding(.horizontal, Spacing.md)

              // Data Management Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Data Management")
                  .font(Typography.subheadline)
                  .foregroundColor(.marketTextSecondary)
                  .padding(.horizontal, Spacing.xs)

                VStack(spacing: 0) {
                  Button(action: {
                    Task {
                      if let url = await profileVM.exportData() {
                        exportURL = url
                        showingShareSheet = true
                      }
                    }
                  }) {
                    ProfileRow(
                      icon: "square.and.arrow.up", title: "Download Data (CSV)", showChevron: true)
                  }
                }
                .marketCardStyle()
              }
              .padding(.horizontal, Spacing.md)

              // Feedback & Support Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Feedback & Support")
                  .font(Typography.subheadline)
                  .foregroundColor(.marketTextSecondary)
                  .padding(.horizontal, Spacing.xs)

                VStack(spacing: 0) {
                  Button(action: { showingFeedback = true }) {
                    ProfileRow(
                      icon: "bubble.left.and.exclamationmark.bubble.right",
                      title: "Report Bug / Request Feature",
                      showChevron: true
                    )
                  }
                }
                .marketCardStyle()
              }
              .padding(.horizontal, Spacing.md)

              // Account Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Account")
                  .font(Typography.subheadline)
                  .foregroundColor(.marketTextSecondary)
                  .padding(.horizontal, Spacing.xs)

                VStack(spacing: 0) {
                  Button(action: {
                    Task {
                      await authVM.signOut()
                    }
                  }) {
                    ProfileRow(
                      icon: "rectangle.portrait.and.arrow.right", title: "Sign Out",
                      titleColor: .white)
                  }

                  Divider().background(Color.white.opacity(0.1))

                  Button(action: { showingDeleteAlert = true }) {
                    ProfileRow(icon: "trash", title: "Delete Account", titleColor: .marketRed)
                  }
                }
                .marketCardStyle()
              }
              .padding(.horizontal, Spacing.md)
            }
            .padding(.bottom, Spacing.xl)
          }
        }
      }
      .navigationBarHidden(true)
      .onAppear {
        Task {
          await profileVM.fetchProfile()
        }
      }
      .sheet(isPresented: $showingShareSheet) {
        if let url = exportURL {
          ShareSheet(activityItems: [url])
        }
      }
      .navigationDestination(isPresented: $showingFeedback) {
        FeedbackView()
      }
      .alert("Delete Account", isPresented: $showingDeleteAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          Task {
            await profileVM.deleteAccount()
            await authVM.checkSession()
          }
        }
      } message: {
        Text(
          "Are you sure you want to delete your account? This action cannot be undone and all your data will be lost."
        )
      }
      .alert("Error", isPresented: .constant(profileVM.errorMessage != nil)) {
        Button("OK", role: .cancel) {
          profileVM.errorMessage = nil
        }
      } message: {
        Text(profileVM.errorMessage ?? "An unknown error occurred")
      }
      .disabled(profileVM.isLoading)
    }
  }
}

struct ProfileRow: View {
  let icon: String
  let title: String
  var value: String? = nil
  var titleColor: Color = .white
  var showChevron: Bool = false

  var body: some View {
    HStack(spacing: Spacing.md) {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundColor(titleColor == .marketRed ? .marketRed : .marketTextSecondary)
        .frame(width: 24)

      Text(title)
        .font(Typography.body)
        .foregroundColor(titleColor)

      Spacer()

      if let value = value {
        Text(value)
          .font(Typography.subheadline)
          .foregroundColor(.marketTextSecondary)
      }

      if showChevron || value != nil {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.marketTextSecondary)
      }
    }
    .padding(Spacing.md)
    .contentShape(Rectangle())  // Make full row tappable
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  var activityItems: [Any]
  var applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems, applicationActivities: applicationActivities)
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
