import SwiftUI

struct CostsView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @State private var showingAddCost = false
  @State private var selectedCost: Cost?

  var body: some View {
    NavigationView {
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
                .foregroundColor(.white.opacity(0.8))
            }

            // Search Bar
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
              TextField("Search", text: .constant(""))
                .foregroundColor(.white)
                .accentColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)

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
                ForEach(costsVM.costs) { cost in
                  CostRowView(cost: cost)
                    .onTapGesture {
                      selectedCost = cost
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
      .sheet(isPresented: $showingAddCost) {
        AddCostView()
          .environmentObject(costsVM)
      }
      .sheet(item: $selectedCost) { cost in
        CostDetailView(cost: cost)
          .environmentObject(costsVM)
      }
    }
    .onAppear {
      Task {
        await costsVM.fetchCosts()
        await costsVM.fetchCategories()
      }
    }
  }
}

struct CostRowView: View {
  let cost: Cost
  @EnvironmentObject var profileVM: ProfileViewModel

  var body: some View {
    HStack {
      Circle()
        .fill(Color.red.opacity(0.2))
        .frame(width: 40, height: 40)
        .overlay(
          Image(systemName: "dollarsign.circle.fill")
            .foregroundColor(.red)
        )

      VStack(alignment: .leading, spacing: 4) {
        Text(cost.description)
          .font(.headline)
          .foregroundColor(.white)
      }

      Spacer()

      VStack(alignment: .trailing) {
        Text("-\(profileVM.selectedCurrency) \(String(format: "%.2f", cost.amount))")
          .font(.headline)
          .foregroundColor(.red)

        if let category = cost.category {
          Text(category)
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
        }
      }
    }
    .padding()
    .marketCardStyle()
  }
}
