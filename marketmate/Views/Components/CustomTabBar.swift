import SwiftUI

struct CustomTabBar: View {
  @Binding var selectedTab: Int
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var profileVM: ProfileViewModel

  var body: some View {
    HStack {
      // Home
      TabBarButton(
        icon: "house.fill",
        text: "Home",
        isSelected: selectedTab == 0,
        themeManager: themeManager
      ) {
        selectedTab = 0
      }

      Spacer()

      // Sales
      TabBarButton(
        icon: "tag.fill",
        text: "Sales",
        isSelected: selectedTab == 1,
        themeManager: themeManager
      ) {
        selectedTab = 1
      }

      // Inventory (Conditional)
      if profileVM.useInventory {
        Spacer()
        TabBarButton(
          icon: "cube.box.fill",
          text: "Inventory",
          isSelected: selectedTab == 2,
          themeManager: themeManager
        ) {
          selectedTab = 2
        }
      }

      Spacer()

      // Costs
      TabBarButton(
        icon: "arrow.down.circle.fill",
        text: "Costs",
        isSelected: selectedTab == 3,
        themeManager: themeManager
      ) {
        selectedTab = 3
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 24)
    .background(themeManager.backgroundColor.opacity(0.8))
    .background(.ultraThinMaterial)
    .clipShape(Capsule())
    .overlay(
      Capsule()
        .stroke(themeManager.primaryTextColor.opacity(0.2), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    .padding(.horizontal, 24)
  }
}

struct TabBarButton: View {
  let icon: String
  let text: String
  let isSelected: Bool
  let themeManager: ThemeManager
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 24))

        Text(text)
          .font(.caption2)
          .fontWeight(.medium)
      }
      .foregroundColor(isSelected ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .background(
        isSelected ? themeManager.primaryTextColor.opacity(0.1) : Color.clear
      )
      .clipShape(Capsule())
    }
  }
}

#Preview {
  CustomTabBar(selectedTab: .constant(0))
    .environmentObject(ThemeManager())
    .environmentObject(ProfileViewModel())
}
