import SwiftUI

struct AnimatedGradientBackground: View {
  @State private var animateGradient = false

  var body: some View {
    LinearGradient(
      colors: [
        Color.marketBlue,
        Color.marketDarkBlue,
        Color.marketBlue.opacity(0.8),
        Color.marketLightBlue.opacity(0.6)
      ],
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
