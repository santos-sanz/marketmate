import Charts
import SwiftUI

struct ReportsView: View {
  @StateObject private var reportsVM = ReportsViewModel()
  @EnvironmentObject var profileVM: ProfileViewModel

  var body: some View {
    NavigationView {
      ZStack {
        // Gradient Background
        Color.clear.revolutBackground()

        ScrollView {
          VStack(spacing: 20) {
            // Time Range Picker
            Picker("Time Range", selection: $reportsVM.selectedTimeRange) {
              ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: reportsVM.selectedTimeRange) { _, _ in
              Task {
                await reportsVM.fetchData()
              }
            }

            // Summary Cards
            if reportsVM.isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .marketGreen))
                .padding()
            } else {
              VStack(spacing: 16) {
                SummaryCard(
                  title: "Total Sales", amount: reportsVM.totalSales, color: .marketGreen,
                  icon: "tag.fill", currency: profileVM.currencySymbol)
                SummaryCard(
                  title: "Total Costs", amount: reportsVM.totalCosts, color: .red,
                  icon: "arrow.down.circle.fill", currency: profileVM.currencySymbol)
              }
              .padding(.horizontal)

              HStack(spacing: 16) {
                SummaryCard(
                  title: "Net Profit", amount: reportsVM.netProfit,
                  color: reportsVM.netProfit >= 0 ? .marketBlue : .orange, icon: "banknote.fill",
                  currency: profileVM.currencySymbol)
              }
              .padding(.horizontal)
              // Charts
              VStack(alignment: .leading) {
                Text("Sales Trend")
                  .font(.headline)
                  .foregroundColor(.white)
                  .padding(.horizontal)

                Chart {
                  ForEach(reportsVM.salesData) { data in
                    BarMark(
                      x: .value("Date", data.date, unit: .day),
                      y: .value("Sales", data.amount)
                    )
                    .foregroundStyle(Color.marketBlue)
                  }
                }
                .chartYAxis {
                  AxisMarks(position: .leading, values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                      .foregroundStyle(Color.marketTextSecondary)
                    AxisValueLabel {
                      if let doubleValue = value.as(Double.self) {
                        Text("\(profileVM.currencySymbol) \(Int(doubleValue))")
                          .foregroundColor(.white.opacity(0.7))
                      }
                    }
                  }
                }
                .chartXAxis {
                  AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                      .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel(format: .dateTime.day().month(), centered: true)
                      .foregroundStyle(Color.marketTextSecondary)
                  }
                }
                .frame(height: 250)
                .padding()
                .background(Color.marketCard)
                .cornerRadius(12)
                .padding(.horizontal)
              }
            }
          }
        }
      }
      .navigationTitle("Reports")
      .onAppear {
        Task { await reportsVM.fetchData() }
      }
    }
  }
}

struct SummaryCard: View {
  let title: String
  let amount: Double
  let color: Color
  let icon: String
  let currency: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(color)
        Text(title)
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.7))
      }
      Text("\(currency) \(String(format: "%.2f", amount))")
        .font(.title2)
        .bold()
        .foregroundColor(.white)
    }
    .padding()
    .marketCardStyle()
  }
}
