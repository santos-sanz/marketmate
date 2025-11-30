import SwiftUI

extension Color {
  static let marketBlue = Color(hex: "0066CC")
  static let marketDarkBlue = Color(hex: "004499")
  static let marketLightBlue = Color(hex: "5AC8FA")

  static let marketGreen = Color(hex: "1DB954")
  static let marketRed = Color(hex: "FF3B30")
  static let marketYellow = Color(hex: "FFCC00")

  static var marketTextPrimary: Color { Color(hex: ThemeManager.storedTextHex) }
  static var marketTextSecondary: Color {
    Color(hex: ThemeManager.storedTextHex).opacity(0.72)
  }
  static let marketTextTertiary = Color(hex: "8E8E93")

  static let marketCard = Color.white.opacity(0.15)
  static let marketSurface = Color.white

  static let marketBlack = Color.white
  static let marketDarkGray = Color(hex: "E5E5E5")
  static let marketLightGray = Color(hex: "CCCCCC")
}

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

enum CornerRadius {
  static let xs: CGFloat = 8
  static let sm: CGFloat = 12
  static let md: CGFloat = 16
  static let lg: CGFloat = 20
  static let xl: CGFloat = 40
}

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

extension View {
  func marketCardStyle(themeManager: ThemeManager) -> some View {
    self
      .background(themeManager.cardBackground)
      .cornerRadius(CornerRadius.sm)
      .shadow(
        color: Shadow.card.color, radius: Shadow.card.radius, x: Shadow.card.x, y: Shadow.card.y)
  }

  func solidCardStyle(themeManager: ThemeManager) -> some View {
    self
      .background(themeManager.elevatedCardBackground)
      .cornerRadius(CornerRadius.sm)
      .shadow(
        color: Shadow.card.color, radius: Shadow.card.radius, x: Shadow.card.x, y: Shadow.card.y)
  }

  func primaryButtonStyle(themeManager: ThemeManager) -> some View {
    self
      .font(Typography.headline)
      .foregroundColor(themeManager.primaryTextColor)
      .frame(maxWidth: .infinity)
      .padding(Spacing.md)
      .background(themeManager.primaryTextColor.opacity(0.14))
      .overlay(
        RoundedRectangle(cornerRadius: CornerRadius.xl)
          .stroke(themeManager.strokeColor, lineWidth: 1)
      )
      .cornerRadius(CornerRadius.xl)
  }

  func secondaryButtonStyle(themeManager: ThemeManager) -> some View {
    self
      .font(Typography.headline)
      .foregroundColor(themeManager.primaryTextColor)
      .padding(.horizontal, Spacing.sm)
      .padding(.vertical, Spacing.xxs + 2)
      .background(themeManager.translucentOverlay)
      .cornerRadius(CornerRadius.sm)
  }

  func iconButtonStyle(size: CGFloat = 40, themeManager: ThemeManager) -> some View {
    self
      .frame(width: size, height: size)
      .background(themeManager.translucentOverlay)
      .clipShape(Circle())
  }

  func revolutBackground() -> some View {
    self.background(
      AnimatedGradientBackground()
    )
  }

  func searchBarStyle(themeManager: ThemeManager) -> some View {
    self
      .padding(.vertical, Spacing.xs)
      .padding(.horizontal, Spacing.sm)
      .background(themeManager.fieldBackground)
      .overlay(
        RoundedRectangle(cornerRadius: CornerRadius.lg)
          .stroke(themeManager.mutedStrokeColor, lineWidth: 1)
      )
      .cornerRadius(CornerRadius.lg)
  }

  func themedNavigationBars(_ themeManager: ThemeManager) -> some View {
    let scheme: ColorScheme = themeManager.backgroundColor.isDark ? .dark : .light
    return self
      .toolbarBackground(themeManager.backgroundColor, for: .navigationBar)
      .toolbarBackground(themeManager.backgroundColor, for: .tabBar)
      .toolbarColorScheme(scheme, for: .navigationBar)
      .toolbarColorScheme(scheme, for: .tabBar)
      .tint(themeManager.primaryTextColor)
  }

  func unifiedHeaderStyle() -> some View {
    self
      .padding(.horizontal, Spacing.md)
      .padding(.top, 10)
      .padding(.bottom, Spacing.xs)
  }

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

  func toHex() -> String? {
    let uic = UIColor(self)
    guard let components = uic.cgColor.components, components.count >= 3 else {
      return nil
    }
    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)

    if components.count >= 4 {
      a = Float(components[3])
    }

    if a != Float(1.0) {
      return String(
        format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255),
        lroundf(a * 255))
    } else {
      return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
  }
}
