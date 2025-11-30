import SwiftUI

struct AnimatedGradientBackground: View {
  @EnvironmentObject var themeManager: ThemeManager
  @State private var animateGradient = false

  private var gradientColors: [Color] {
    let base = themeManager.backgroundColor
    return [
      base.adjusted(by: -0.12),
      base.adjusted(by: 0.04),
      base.adjusted(by: 0.14),
      base.adjusted(by: -0.2),
    ]
  }

  var body: some View {
    LinearGradient(
      colors: gradientColors,
      startPoint: animateGradient ? .topLeading : .bottomLeading,
      endPoint: animateGradient ? .bottomTrailing : .topTrailing
    )
    .ignoresSafeArea()
    .onAppear {
      withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
        animateGradient.toggle()
      }
    }
  }
}

struct TabBarBackground: View {
  var body: some View {
    ZStack {
      // Animated gradient
      AnimatedGradientBackground()

      // Blur effect overlay
      Rectangle()
        .fill(.ultraThinMaterial)
        .opacity(0.8)
    }
  }
}
