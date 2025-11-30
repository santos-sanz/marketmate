import SwiftUI
import UIKit
import Combine

enum ThemeDefaults {
  static let backgroundHex = "0F172A"
  static let textHex = "FFFFFF"
}

final class ThemeManager: ObservableObject {
  @Published var backgroundHex: String {
    didSet { persistTheme() }
  }

  @Published var textHex: String {
    didSet { persistTheme() }
  }

  static let backgroundKey = "theme_background_hex"
  static let textKey = "theme_text_hex"

  init(
    backgroundHex: String = ThemeDefaults.backgroundHex,
    textHex: String = ThemeDefaults.textHex
  ) {
    let storedBackground = UserDefaults.standard.string(forKey: Self.backgroundKey)
    let storedText = UserDefaults.standard.string(forKey: Self.textKey)
    self.backgroundHex = storedBackground ?? backgroundHex
    self.textHex = storedText ?? textHex
  }

  var backgroundColor: Color { Color(hex: backgroundHex) }

  var primaryTextColor: Color { Color(hex: textHex) }

  var secondaryTextColor: Color { Color(hex: textHex).opacity(0.72) }

  var primaryTextWeight: Font.Weight { .semibold }

  var secondaryTextWeight: Font.Weight { .medium }

  func apply(
    backgroundHex: String,
    textHex: String
  ) {
    self.backgroundHex = backgroundHex
    self.textHex = textHex
  }

  static var storedBackgroundHex: String {
    UserDefaults.standard.string(forKey: backgroundKey) ?? ThemeDefaults.backgroundHex
  }

  static var storedTextHex: String {
    UserDefaults.standard.string(forKey: textKey) ?? ThemeDefaults.textHex
  }

  private func persistTheme() {
    UserDefaults.standard.set(backgroundHex, forKey: Self.backgroundKey)
    UserDefaults.standard.set(textHex, forKey: Self.textKey)
  }
}

extension Color {
  func hexString() -> String? {
    let uiColor = UIColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return nil
    }

    let r = Int(red * 255)
    let g = Int(green * 255)
    let b = Int(blue * 255)

    return String(format: "%02X%02X%02X", r, g, b)
  }

  func blended(with color: Color, amount: CGFloat) -> Color {
    let primary = UIColor(self)
    let secondary = UIColor(color)

    var pR: CGFloat = 0
    var pG: CGFloat = 0
    var pB: CGFloat = 0
    var pA: CGFloat = 0
    var sR: CGFloat = 0
    var sG: CGFloat = 0
    var sB: CGFloat = 0
    var sA: CGFloat = 0

    guard primary.getRed(&pR, green: &pG, blue: &pB, alpha: &pA),
      secondary.getRed(&sR, green: &sG, blue: &sB, alpha: &sA)
    else { return self }

    let red = (1 - amount) * pR + amount * sR
    let green = (1 - amount) * pG + amount * sG
    let blue = (1 - amount) * pB + amount * sB
    let alpha = (1 - amount) * pA + amount * sA

    return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
  }

  func adjusted(by amount: CGFloat) -> Color {
    if amount >= 0 {
      return blended(with: .white, amount: min(amount, 1))
    } else {
      return blended(with: .black, amount: min(abs(amount), 1))
    }
  }
}
