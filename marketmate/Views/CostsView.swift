import Supabase
import SwiftUI

struct CostsView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @State private var showingAddCost = false
  @State private var selectedCost: Cost?
  @State private var activities: [Activity] = []
  private let client = SupabaseService.shared.client

  var body: some View {
    ZStack {
      // Gradient Background
      Color.clear.revolutBackground()

      VStack(spacing: 0) {
        // Header (Profile, Search, Reports)
        HStack(spacing: 12) {
          Button(action: {}) {
            Image(systemName: "person.crop.circle.fill")
              .resizable()
              .frame(width: 40, height: 40)
              .foregroundColor(.marketTextSecondary)
          }

          // Search Bar
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(.marketTextSecondary)
            TextField("", text: .constant(""))
              .foregroundColor(.white)
              .accentColor(.white)
              .placeholder(when: true) {  // Always show placeholder for now as text is constant
                Text("Search").foregroundColor(.white)
              }
          }
          .searchBarStyle()

          Button(action: {}) {
            Image(systemName: "chart.bar.xaxis")
              .foregroundColor(.white)
              .font(Typography.title3)
          }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, 10)
        .padding(.bottom, Spacing.xs)

        // Content
        if costsVM.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .marketBlue))
        } else if costsVM.costs.isEmpty {
          VStack(spacing: 20) {
            Image(systemName: "chart.pie")
              .font(.system(size: 60))
              .foregroundColor(.marketTextSecondary)
            Text("No costs recorded")
              .font(.title2)
              .foregroundColor(.marketTextSecondary)
            Button(action: { showingAddCost = true }) {
              Text("Add a cost")
                .primaryButtonStyle()
                .frame(width: 200)
            }
          }
        } else {
          ScrollView {
            LazyVStack(spacing: 16) {
              // Recent Activity Section (Costs Only)
              VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                  .font(.headline)
                  .foregroundColor(.white)

                ForEach(activities.filter { $0.type == .cost }.prefix(5)) { activity in
                  ActivityRow(
                    activity: activity,
                    currency: profileVM.currencySymbol
                  )
                }
              }
              .padding(.horizontal)

              Divider()
                .background(Color.white.opacity(0.2))
                .padding()

              ForEach(costsVM.costs) { cost in
                NavigationLink(destination: CostDetailView(cost: cost).environmentObject(costsVM)) {
                  CostRowView(cost: cost)
                    .environmentObject(costsVM)
                }
              }
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
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.marketBlue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
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
        await fetchActivities()
      }
    }
  }

  func fetchActivities() async {
    guard let userId = client.auth.currentUser?.id else { return }

    do {
      let fetchedActivities: [Activity] =
        try await client
        .from("recent_activity")
        .select()
        .eq("user_id", value: userId)
        .order("created_at", ascending: false)
        .limit(20)
        .execute()
        .value

      self.activities = fetchedActivities
    } catch {
      print("❌ [CostsView] Error fetching activities: \(error)")
    }
  }
}

struct CostRowView: View {
  let cost: Cost
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var costsVM: CostsViewModel

  var categoryName: String? {
    guard let categoryId = cost.categoryId else { return nil }
    return costsVM.categories.first(where: { $0.id == categoryId })?.name
  }

  var body: some View {
    HStack {
      Circle()
        .fill(Color.marketRed.opacity(0.2))
        .frame(width: 40, height: 40)
        .overlay(
          Image(systemName: "arrow.down.circle.fill")
            .foregroundColor(.marketRed)
        )

      VStack(alignment: .leading, spacing: 4) {
        Text(cost.description)
          .font(.headline)
          .foregroundColor(.white)
      }

      Spacer()

      VStack(alignment: .trailing) {
        Text("-\(profileVM.currencySymbol) \(String(format: "%.2f", cost.amount))")
          .font(.headline)
          .foregroundColor(.marketRed)

        if let categoryName = categoryName {
          Text(categoryName)
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
        }
      }
    }
    .padding()
    .marketCardStyle()
  }
}
