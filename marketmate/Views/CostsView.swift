import SwiftUI

struct CostsView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @StateObject private var activityVM = ActivityViewModel()
  @State private var showingAddCost = false
  @State private var expandedActivityId: UUID?
  @EnvironmentObject var themeManager: ThemeManager

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var strokeColor: Color { themeManager.strokeColor }

  var body: some View {
    ZStack {
      // Gradient Background
      Color.clear.revolutBackground()

      VStack(spacing: 0) {
        // Header (Profile, Search, Reports)
        HStack(spacing: 12) {
          NavigationLink(destination: ProfileView().environmentObject(profileVM)) {
            Image(systemName: "person.crop.circle.fill")
              .resizable()
              .frame(width: 40, height: 40)
              .foregroundColor(secondaryTextColor)
          }

          // Search Bar
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(secondaryTextColor)
            TextField("", text: .constant(""))
              .foregroundColor(textColor)
              .accentColor(textColor)
              .placeholder(when: true) {  // Always show placeholder for now as text is constant
                Text("Search").foregroundColor(secondaryTextColor)
              }
          }
          .searchBarStyle(themeManager: themeManager)

          Button(action: {}) {
            Image(systemName: "chart.bar.xaxis")
              .foregroundColor(textColor)
              .font(Typography.title3)
          }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, 10)
        .padding(.bottom, Spacing.xs)

        // Content
        if costsVM.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: textColor))
        } else {
          ScrollView {
            LazyVStack(spacing: 16) {
              // Recent Activity Section (Costs Only)
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(textColor)
                  Spacer()
                  NavigationLink(
                    destination: ActivityHistoryView(initialFilter: .costs).environmentObject(
                      profileVM)
                  ) {
                    Text("Show all")
                      .font(.subheadline)
                      .foregroundColor(textColor)
                  }
                }

                ForEach(activityVM.activities.filter { $0.type == .cost }.prefix(3)) { activity in
                  VStack(spacing: 0) {
                    ActivityRow(
                      activity: activity,
                      currency: profileVM.currencySymbol
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                      if expandedActivityId == activity.id {
                        expandedActivityId = nil
                        activityVM.expandedDetails = nil
                      } else {
                        expandedActivityId = activity.id
                        Task {
                          await activityVM.fetchDetails(for: activity)
                        }
                      }
                    }

                    if expandedActivityId == activity.id {
                      ExpandedActivityView(
                        activity: activity,
                        viewModel: activityVM,
                        onEdit: { _ in }  // Editing not implemented in CostsView for now
                      )
                    }
                  }
                }
              }
              .padding(.horizontal)
            }
            .padding()
          }
        }

        // Floating Action Button
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button(action: { showingAddCost = true }) {
              Image(systemName: "plus")
                .font(.title)
                .foregroundColor(textColor)
                .frame(width: 60, height: 60)
                .background(cardBackground)
                .clipShape(Circle())
                .shadow(color: strokeColor, radius: 4, x: 0, y: 4)
            }
            .padding()
          }
        }
      }
    }
    .navigationBarHidden(true)
    .navigationDestination(isPresented: $showingAddCost) {
      AddCostView()
        .environmentObject(costsVM)
    }
    .onAppear {
      Task {
        await costsVM.fetchCosts()
        await costsVM.fetchCategories()
        await activityVM.fetchActivities()
      }
    }
  }

}

struct CostRowView: View {
  let cost: Cost
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var themeManager: ThemeManager

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }

  var categoryName: String? {
    guard let categoryId = cost.categoryId else { return nil }
    return costsVM.categories.first(where: { $0.id == categoryId })?.name
  }

  var body: some View {
    HStack {
      Circle()
        .fill(themeManager.translucentOverlay)
        .frame(width: 40, height: 40)
        .overlay(
          Image(systemName: "arrow.down.circle.fill")
            .foregroundColor(.marketRed)
        )

      VStack(alignment: .leading, spacing: 4) {
        Text(cost.description)
          .font(.headline)
          .foregroundColor(textColor)
      }

      Spacer()

      VStack(alignment: .trailing) {
        Text("-\(profileVM.currencySymbol) \(String(format: "%.2f", cost.amount))")
          .font(.headline)
          .foregroundColor(.marketRed)

        if let categoryName = categoryName {
          Text(categoryName)
            .font(.caption)
            .foregroundColor(secondaryTextColor)
        }
      }
    }
    .padding()
    .marketCardStyle(themeManager: themeManager)
  }
}
