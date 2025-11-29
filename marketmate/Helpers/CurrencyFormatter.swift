import SwiftUI

/// A view modifier that formats text field input to accept only numeric values and decimal separators
struct CurrencyInputModifier: ViewModifier {
  @Binding var text: String

  func body(content: Content) -> some View {
    content
      .keyboardType(.decimalPad)
      .onChange(of: text) { _, newValue in
        // Allow only numbers and one decimal separator (. or ,)
        let filtered = newValue.filter { "0123456789.,".contains($0) }

        // Ensure only one decimal separator
        let components = filtered.components(separatedBy: CharacterSet(charactersIn: ".,"))
        if components.count > 2 {
          // More than one decimal separator, keep only the first one
          let firstPart = components[0]
          let secondPart = components[1]
          text = firstPart + "." + secondPart
        } else {
          text = filtered
        }
      }
  }
}

extension View {
  /// Applies currency input formatting (numbers and decimal separator only)
  func currencyInput(text: Binding<String>) -> some View {
    self.modifier(CurrencyInputModifier(text: text))
  }
}
