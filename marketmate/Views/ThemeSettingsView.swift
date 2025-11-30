import SwiftUI

struct ThemeSettingsView: View {
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var themeManager: ThemeManager
  @Environment(\.dismiss) var dismiss

  @State private var customColor = Color.white
  @State private var isCustomColorPickerPresented = false
  @State private var isBackgroundExpanded = false

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
    ZStack {
      themeManager.backgroundColor.ignoresSafeArea()
      Color.clear.revolutBackground()

      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
          // Background Color Section
          VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Background Color")
              .font(Typography.subheadline)
              .foregroundColor(themeManager.secondaryTextColor)
              .padding(.horizontal, Spacing.xs)

            if isBackgroundExpanded {
              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                  // Preset Colors
                  ForEach(backgroundOptions, id: \.self) { hex in
                    Button(action: {
                      applyTheme(backgroundHex: hex, textHex: profileVM.themeTextHex)
                      withAnimation {
                        isBackgroundExpanded = false
                      }
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
              .marketCardStyle()
              .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
              Button(action: {
                withAnimation {
                  isBackgroundExpanded = true
                }
              }) {
                HStack {
                  ColorChip(
                    color: Color(hex: profileVM.themeBackgroundHex),
                    isSelected: true,
                    showBorder: profileVM.themeBackgroundHex.uppercased() == "FFFFFF"
                  )

                  Text("Select Color")
                    .font(Typography.body)
                    .foregroundColor(themeManager.primaryTextColor)

                  Spacer()

                  Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
              }
              .marketCardStyle()
            }
          }

          // Text Color Section
          VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Text Color")
              .font(Typography.subheadline)
              .foregroundColor(themeManager.secondaryTextColor)
              .padding(.horizontal, Spacing.xs)

            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: Spacing.sm) {
                ForEach(textOptions, id: \.self) { hex in
                  Button(action: {
                    applyTheme(backgroundHex: profileVM.themeBackgroundHex, textHex: hex)
                  }) {
                    ColorChip(
                      color: Color(hex: hex),
                      isSelected: hex.uppercased() == profileVM.themeTextHex.uppercased(),
                      showBorder: hex.uppercased() == "FFFFFF" || hex.uppercased() == "F8FAFC"
                    )
                  }
                }
              }
              .padding(.vertical, 4)
            }
            .marketCardStyle()
          }
        }
        .padding(Spacing.md)
      }
    }
    .navigationTitle("Theme Settings")
    .navigationBarTitleDisplayMode(.inline)
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
          withAnimation {
            isBackgroundExpanded = false
          }
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
                showBorder: hex.uppercased() == "FFFFFF" || hex.uppercased() == "F8FAFC"
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
