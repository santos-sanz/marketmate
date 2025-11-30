import SwiftUI
import UIKit

struct ProfileView: View {
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var authVM: AuthViewModel
  @EnvironmentObject var themeManager: ThemeManager

  @State private var showingShareSheet = false
  @State private var exportURL: URL?
  @State private var showingDeleteAlert = false
  @State private var showingFeedback = false

  let currencies = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD"]

  var body: some View {
    NavigationView {
      ZStack {
        themeManager.backgroundColor.ignoresSafeArea()
        // Gradient Background
        Color.clear.revolutBackground()

        if profileVM.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryTextColor))
        } else {
          ScrollView {
            VStack(spacing: Spacing.lg) {
              // Profile Header
              VStack(spacing: Spacing.sm) {
                Image(systemName: "person.crop.circle.fill")
                  .resizable()
                  .frame(width: 80, height: 80)
                  .foregroundColor(themeManager.secondaryTextColor)
                  .padding(.top, Spacing.md)  // Minimal top padding

                Text(authVM.currentUserEmail ?? "User")
                  .font(Typography.title3)
                  .foregroundColor(themeManager.primaryTextColor)
              }
              .frame(maxWidth: .infinity)

              // Settings Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Settings")
                  .font(Typography.subheadline)
                  .foregroundColor(themeManager.secondaryTextColor)
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

                  Divider().background(themeManager.primaryTextColor.opacity(0.1))

                  ProfileToggleRow(
                    icon: "shippingbox",
                    title: "Use Inventory",
                    isOn: $profileVM.useInventory
                  )
                }
                .marketCardStyle(themeManager: themeManager)
              }
              .padding(.horizontal, Spacing.md)

              // Theme Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Theme")
                  .font(Typography.subheadline)
                  .foregroundColor(themeManager.secondaryTextColor)
                  .padding(.horizontal, Spacing.xs)

                NavigationLink(destination: ThemeSettingsView()) {
                  HStack(spacing: Spacing.md) {
                    ThemeSplitCircle(
                      backgroundHex: profileVM.themeBackgroundHex,
                      textHex: profileVM.themeTextHex
                    )
                    .frame(width: 24, height: 24)

                    Text("Theme")
                      .font(Typography.body)
                      .foregroundColor(themeManager.primaryTextColor)

                    Spacer()

                    Image(systemName: "chevron.right")
                      .font(.caption)
                      .foregroundColor(themeManager.secondaryTextColor)
                  }
                  .padding(Spacing.md)
                  .contentShape(Rectangle())
                }
                .marketCardStyle(themeManager: themeManager)
              }
              .padding(.horizontal, Spacing.md)

              // Data Management Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Data Management")
                  .font(Typography.subheadline)
                  .foregroundColor(themeManager.secondaryTextColor)
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
                .marketCardStyle(themeManager: themeManager)
              }
              .padding(.horizontal, Spacing.md)

              // Feedback & Support Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Feedback & Support")
                  .font(Typography.subheadline)
                  .foregroundColor(themeManager.secondaryTextColor)
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
                .marketCardStyle(themeManager: themeManager)
              }
              .padding(.horizontal, Spacing.md)

              // Account Section
              VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Account")
                  .font(Typography.subheadline)
                  .foregroundColor(themeManager.secondaryTextColor)
                  .padding(.horizontal, Spacing.xs)

                VStack(spacing: 0) {
                  Button(action: {
                    Task {
                      await authVM.signOut()
                    }
                  }) {
                    ProfileRow(
                      icon: "rectangle.portrait.and.arrow.right", title: "Sign Out")
                  }

                  Divider().background(themeManager.primaryTextColor.opacity(0.1))

                  Button(action: { showingDeleteAlert = true }) {
                    ProfileRow(icon: "trash", title: "Delete Account", titleColor: .marketRed)
                  }
                }
                .marketCardStyle(themeManager: themeManager)
              }
              .padding(.horizontal, Spacing.md)
            }
            .padding(.bottom, Spacing.xl)
          }
        }
      }
      .navigationBarHidden(true)
      .onAppear {
        profileVM.themeBackgroundHex = themeManager.backgroundHex
        profileVM.themeTextHex = themeManager.textHex
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
      .onChange(of: profileVM.selectedCurrency) { _, newValue in
        guard profileVM.profile?.currency != newValue else { return }
        Task {
          await profileVM.updateCurrency(newValue)
        }
      }
      .onChange(of: profileVM.useInventory) { _, newValue in
        guard profileVM.profile?.useInventory != newValue else { return }
        Task {
          await profileVM.updateUseInventory(newValue)
        }
      }
    }
  }
}

struct ProfileRow: View {
  @EnvironmentObject var themeManager: ThemeManager
  let icon: String
  let title: String
  var value: String? = nil
  var titleColor: Color? = nil
  var showChevron: Bool = false

  private var primaryColor: Color {
    if let titleColor = titleColor {
      return titleColor
    }
    return themeManager.primaryTextColor
  }

  private var secondaryColor: Color {
    themeManager.secondaryTextColor
  }

  var body: some View {
    HStack(spacing: Spacing.md) {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundColor(primaryColor == .marketRed ? .marketRed : secondaryColor)
        .frame(width: 24)

      Text(title)
        .font(Typography.body)
        .foregroundColor(primaryColor)

      Spacer()

      if let value = value {
        Text(value)
          .font(Typography.subheadline)
          .foregroundColor(secondaryColor)
      }

      if showChevron || value != nil {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(secondaryColor)
      }
    }
    .padding(Spacing.md)
    .contentShape(Rectangle())  // Make full row tappable
  }
}

struct ProfileToggleRow: View {
  @EnvironmentObject var themeManager: ThemeManager
  let icon: String
  let title: String
  @Binding var isOn: Bool

  var body: some View {
    Toggle(isOn: $isOn) {
      HStack(spacing: Spacing.md) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(themeManager.secondaryTextColor)
          .frame(width: 24)

        Text(title)
          .font(Typography.body)
          .foregroundColor(themeManager.primaryTextColor)
      }
    }
    .toggleStyle(SwitchToggleStyle(tint: themeManager.primaryTextColor))
    .padding(Spacing.md)
  }
}

struct ThemeSplitCircle: View {
  let backgroundHex: String
  let textHex: String
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    ZStack {
      // Left half - background color
      Circle()
        .trim(from: 0, to: 0.5)
        .fill(Color(hex: backgroundHex))
        .rotationEffect(.degrees(90))

      // Right half - text color
      Circle()
        .trim(from: 0, to: 0.5)
        .fill(Color(hex: textHex))
        .rotationEffect(.degrees(270))

      // Border
      Circle()
        .stroke(themeManager.strokeColor, lineWidth: 1)
    }
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
