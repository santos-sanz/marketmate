import SwiftUI

// MARK: - Colors
extension Color {
  // Primary Colors
  static let marketBlue = Color(hex: "0066CC") // Slightly darker than 007AFF
  static let marketDarkBlue = Color(hex: "004499") // Slightly darker than 0055B3
  static let marketLightBlue = Color(hex: "5AC8FA")

  // Semantic Colors
  static let marketGreen = Color(hex: "1DB954")  // Success, Sales, Positive
  static let marketRed = Color(hex: "FF3B30")  // Error, Delete, Negative
  static let marketYellow = Color(hex: "FFCC00")  // Warning

  // Text Colors
  static let marketTextPrimary = Color.white
  static let marketTextSecondary = Color.white.opacity(0.7)
  static let marketTextTertiary = Color(hex: "8E8E93")

  // Surface Colors
  static let marketCard = Color.white.opacity(0.15)  // Glassmorphism
  static let marketSurface = Color.white  // Solid backgrounds

  // Legacy (for compatibility)
  static let marketBlack = Color.white
  static let marketDarkGray = Color(hex: "E5E5E5")
  static let marketLightGray = Color(hex: "CCCCCC")
}

// MARK: - Typography
enum Typography {
  static let display = Font.system(size: 48, weight: .bold)
  static let title1 = Font.system(size: 28, weight: .bold)
  static let title2 = Font.title2.weight(.semibold)
  static let title3 = Font.system(size: 20, weight: .semibold)
  static let headline = Font.headline
  static let body = Font.body
  static let callout = Font.callout
  static let subheadline = Font.subheadline
  static let footnote = Font.footnote
  static let caption1 = Font.caption
  static let caption2 = Font.caption2
}

// MARK: - Spacing
enum Spacing {
  static let xxxs: CGFloat = 2
  static let xxs: CGFloat = 4
  static let xs: CGFloat = 8
  static let sm: CGFloat = 12
  static let md: CGFloat = 16
  static let lg: CGFloat = 20
  static let xl: CGFloat = 24
  static let xxl: CGFloat = 32
}

// MARK: - Corner Radius
enum CornerRadius {
  static let xs: CGFloat = 8
  static let sm: CGFloat = 12
  static let md: CGFloat = 16
  static let lg: CGFloat = 20
  static let xl: CGFloat = 40
}

// MARK: - Shadows
struct ShadowStyle {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

enum Shadow {
  static let card = ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
  static let floating = ShadowStyle(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
  static let tabBar = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
}

// MARK: - View Modifiers
extension View {
  // Card Styles
  func marketCardStyle() -> some View {
    self
      .background(Color.marketCard)
      .cornerRadius(CornerRadius.sm)
      .shadow(
        color: Shadow.card.color, radius: Shadow.card.radius, x: Shadow.card.x, y: Shadow.card.y)
  }

  func solidCardStyle() -> some View {
    self
      .background(Color.marketSurface)
      .cornerRadius(CornerRadius.sm)
      .shadow(
        color: Shadow.card.color, radius: Shadow.card.radius, x: Shadow.card.x, y: Shadow.card.y)
  }

  // Button Styles
  func primaryButtonStyle() -> some View {
    self
      .font(Typography.headline)
      .foregroundColor(.black)
      .frame(maxWidth: .infinity)
      .padding(Spacing.md)
      .background(Color.marketGreen)
      .cornerRadius(CornerRadius.xl)
  }

  func secondaryButtonStyle() -> some View {
    self
      .font(Typography.headline)
      .foregroundColor(.white)
      .padding(.horizontal, Spacing.sm)
      .padding(.vertical, Spacing.xxs + 2)
      .background(Color.white.opacity(0.2))
      .cornerRadius(CornerRadius.sm)
  }

  func iconButtonStyle(size: CGFloat = 40) -> some View {
    self
      .frame(width: size, height: size)
      .background(Color.white.opacity(0.2))
      .clipShape(Circle())
  }

  // Backgrounds
  func revolutBackground() -> some View {
    self.background(
      AnimatedGradientBackground()
    )
  }

  // Search Bar Style
  func searchBarStyle() -> some View {
    self
      .padding(.vertical, Spacing.xs)
      .padding(.horizontal, Spacing.sm)
      .background(Color.white.opacity(0.2))
      .cornerRadius(CornerRadius.lg)
  }

  // Header Style (unified across all views)
  func unifiedHeaderStyle() -> some View {
    self
      .padding(.horizontal, Spacing.md)
      .padding(.top, 10)
      .padding(.bottom, Spacing.xs)
  }

  // Placeholder Helper
  func placeholder<Content: View>(
    when shouldShow: Bool,
    alignment: Alignment = .leading,
    @ViewBuilder placeholder: () -> Content
  ) -> some View {
    ZStack(alignment: alignment) {
      placeholder().opacity(shouldShow ? 1 : 0)
      self
    }
  }
}

// MARK: - Hex Color Initializer
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
