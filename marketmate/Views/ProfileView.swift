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
                .marketCardStyle()
              }
              .padding(.horizontal, Spacing.md)

              // Theme Section
              ThemeSelectionView()
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
                .marketCardStyle()
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
                .marketCardStyle()
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

struct ThemeSelectionView: View {
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var themeManager: ThemeManager

  @State private var customColor = Color.white
  @State private var isCustomColorPickerPresented = false

  // Summer & Vibrant Palette
  private let backgroundOptions = [
    "0F172A",  // Default Dark
    "FFFFFF",  // White
    "FF5733",  // Vibrant Orange
    "FFC300",  // Vivid Yellow
    "DAF7A6",  // Light Green
    "33FF57",  // Bright Green
    "33FFF5",  // Cyan
    "3380FF",  // Bright Blue
    "A833FF",  // Purple
    "FF33A8",  // Pink
  ]

  // Restricted Text Colors: White, Gray, Black
  private let textOptions = ["FFFFFF", "808080", "000000"]

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      Text("Theme")
        .font(Typography.subheadline)
        .foregroundColor(themeManager.secondaryTextColor)
        .padding(.horizontal, Spacing.xs)

      VStack(alignment: .leading, spacing: Spacing.lg) {
        // Background Color Section
        VStack(alignment: .leading, spacing: Spacing.sm) {
          Text("Background Color")
            .font(Typography.body.weight(themeManager.primaryTextWeight))
            .foregroundColor(themeManager.primaryTextColor)

          Text("Choose a vibrant color or select your own.")
            .font(Typography.caption1)
            .foregroundColor(themeManager.secondaryTextColor)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
              // Preset Colors
              ForEach(backgroundOptions, id: \.self) { hex in
                Button(action: {
                  applyTheme(backgroundHex: hex, textHex: profileVM.themeTextHex)
                }) {
                  ColorChip(
                    color: Color(hex: hex),
                    isSelected: hex.uppercased() == profileVM.themeBackgroundHex.uppercased(),
                    showBorder: hex.uppercased() == "FFFFFF"
                  )
                }
              }

              // Custom Color Picker Button
              Button(action: { isCustomColorPickerPresented = true }) {
                Circle()
                  .fill(
                    LinearGradient(
                      colors: [.red, .orange, .yellow, .green, .blue, .purple],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                  )
                  .frame(width: 36, height: 36)
                  .overlay(
                    Circle()
                      .stroke(Color.white.opacity(0.2), lineWidth: 2)
                  )
                  .overlay(
                    Image(systemName: "plus")
                      .font(.system(size: 14, weight: .bold))
                      .foregroundColor(.white)
                      .shadow(radius: 2)
                  )
              }
            }
            .padding(.vertical, 4)
          }
        }

        Divider().background(themeManager.primaryTextColor.opacity(0.08))

        // Text Color Section
        ThemeSelectorRow(
          title: "Text Color",
          description: "Select a text color for optimal contrast.",
          currentHex: profileVM.themeTextHex,
          options: textOptions
        ) { newHex in
          applyTheme(backgroundHex: profileVM.themeBackgroundHex, textHex: newHex)
        }

        ThemePreview()
      }
      .marketCardStyle()
    }
    .sheet(isPresented: $isCustomColorPickerPresented) {
      VStack(spacing: 20) {
        Text("Select Custom Color")
          .font(Typography.title3)
          .foregroundColor(themeManager.primaryTextColor)
          .padding(.top)

        ColorPicker("Pick a color", selection: $customColor, supportsOpacity: false)
          .labelsHidden()
          .scaleEffect(1.5)
          .padding()

        Button(action: {
          if let hex = customColor.toHex() {
            applyTheme(backgroundHex: hex, textHex: profileVM.themeTextHex)
          }
          isCustomColorPickerPresented = false
        }) {
          Text("Apply Color")
            .primaryButtonStyle()
        }
        .padding(.horizontal)
      }
      .padding()
      .presentationDetents([.medium])
      .background(themeManager.backgroundColor.ignoresSafeArea())
    }
  }

  private func applyTheme(backgroundHex: String, textHex: String) {
    let normalizedBackground = backgroundHex.uppercased()
    let normalizedText = textHex.uppercased()
    guard
      normalizedBackground != profileVM.themeBackgroundHex
        || normalizedText != profileVM.themeTextHex
    else { return }
    profileVM.themeBackgroundHex = normalizedBackground
    profileVM.themeTextHex = normalizedText
    themeManager.apply(backgroundHex: normalizedBackground, textHex: normalizedText)
    profileVM.scheduleThemeUpdate(backgroundHex: normalizedBackground, textHex: normalizedText)
  }
}

struct ThemeSelectorRow: View {
  @EnvironmentObject var themeManager: ThemeManager
  let title: String
  let description: String
  let currentHex: String
  let options: [String]
  let onSelect: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(Typography.body.weight(themeManager.primaryTextWeight))
          .foregroundColor(themeManager.primaryTextColor)

        Text(description)
          .font(Typography.caption1)
          .foregroundColor(themeManager.secondaryTextColor)
          .fixedSize(horizontal: false, vertical: true)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Spacing.sm) {
          ForEach(options, id: \.self) { hex in
            Button(action: { onSelect(hex) }) {
              ColorChip(
                color: Color(hex: hex),
                isSelected: hex.uppercased() == currentHex.uppercased(),
                showBorder: hex.uppercased() == "FFFFFF" || hex.uppercased() == "F8FAFC"  // Add border for light colors
              )
            }
          }
        }
        .padding(.vertical, 4)
      }
    }
  }
}

struct ColorChip: View {
  let color: Color
  let isSelected: Bool
  var showBorder: Bool = false

  var body: some View {
    Circle()
      .fill(color)
      .frame(width: 36, height: 36)
      .overlay(
        Circle()
          .stroke(Color.white.opacity(showBorder ? 0.6 : (isSelected ? 0.9 : 0.2)), lineWidth: 2)
      )
      .overlay(
        Group {
          if isSelected {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(color.adjusted(by: -0.6))
          }
        }
      )
  }
}

struct ThemePreview: View {
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xs) {
      Text("Preview")
        .font(Typography.caption1.weight(.semibold))
        .foregroundColor(themeManager.secondaryTextColor)

      VStack(alignment: .leading, spacing: Spacing.xs) {
        Text("Primary Headline")
          .font(.system(size: 16, weight: themeManager.primaryTextWeight))
          .foregroundColor(themeManager.primaryTextColor)

        Text("Secondary text with lower weight and opacity.")
          .font(.system(size: 14, weight: themeManager.secondaryTextWeight))
          .foregroundColor(themeManager.secondaryTextColor)
      }
      .padding(Spacing.md)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(themeManager.backgroundColor.opacity(0.9))
      .cornerRadius(CornerRadius.sm)
      .overlay(
        RoundedRectangle(cornerRadius: CornerRadius.sm)
          .stroke(themeManager.primaryTextColor.opacity(0.08))
      )
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
