import Charts
import SwiftUI

struct ReportsView: View {
  @StateObject private var reportsVM = ReportsViewModel()
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var themeManager: ThemeManager

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var strokeColor: Color { themeManager.strokeColor }

  private let metricColumns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
  ]

  var body: some View {
    NavigationView {
      ZStack {
        Color.clear.revolutBackground()

        ScrollView(showsIndicators: false) {
          VStack(spacing: 20) {
            headerSection
            timeRangeSelector

            if reportsVM.isLoading && reportsVM.salesData.isEmpty && reportsVM.totalCosts == 0 {
              loadingState
            } else {
              reportContent
            }
          }
          .padding(.vertical, 16)
          .animation(nil, value: reportsVM.isLoading)
        }
        .overlay(alignment: .topTrailing) {
          if reportsVM.isLoading {
            updatingPill
          }
        }
      }
      .navigationTitle("Reports")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        Task { await reportsVM.fetchData() }
      }
      .transaction { transaction in
        transaction.disablesAnimations = true
      }
    }
  }

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Business Report")
        .font(Typography.title2)
        .foregroundColor(textColor)
      Text("Your business at a glance: revenue, costs, and daily pulse.")
        .font(Typography.caption1)
        .foregroundColor(secondaryTextColor)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
  }

  private var timeRangeSelector: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(TimeRange.allCases, id: \.self) { range in
          Button {
            guard reportsVM.selectedTimeRange != range else { return }
            reportsVM.selectedTimeRange = range
            Task { await reportsVM.fetchData() }
          } label: {
            Text(range.rawValue)
              .font(Typography.subheadline.weight(.semibold))
              .foregroundColor(textColor)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(
                Capsule()
                  .fill(
                    reportsVM.selectedTimeRange == range
                      ? themeManager.primaryTextColor.opacity(0.18)
                      : cardBackground
                  )
              )
              .overlay(
                Capsule()
                  .stroke(
                    reportsVM.selectedTimeRange == range ? strokeColor : Color.clear,
                    lineWidth: 1
                  )
              )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal)
    }
  }

  private var loadingState: some View {
    VStack(spacing: 12) {
      Image(systemName: "hourglass")
        .font(.title3)
        .foregroundColor(secondaryTextColor)
      Text("Preparing your report...")
        .font(Typography.subheadline)
        .foregroundColor(secondaryTextColor)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }

  private var reportContent: some View {
    VStack(spacing: 16) {
      if reportsVM.salesCount == 0 && reportsVM.totalCosts == 0 {
        emptyState
      } else {
        netProfitCard
        metricsGrid
        performanceHighlights
        trendSection
        breakdownSection(
          title: "Payment mix",
          subtitle: "Preferred methods in this period",
          items: reportsVM.paymentBreakdown,
          accent: .marketBlue
        )
        if !reportsVM.locationBreakdown.isEmpty {
          breakdownSection(
            title: "Top locations",
            subtitle: "Best performing markets",
            items: reportsVM.locationBreakdown,
            accent: .marketGreen
          )
        }
      }
    }
  }

  private var netProfitCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Net Profit")
            .font(Typography.subheadline)
            .foregroundColor(secondaryTextColor)
          Text(currency(reportsVM.netProfit))
            .font(Typography.title1)
            .foregroundColor(textColor)
        }
        Spacer()
        Capsule()
          .fill(themeManager.translucentOverlay)
          .frame(height: 32)
          .overlay(
            HStack(spacing: 6) {
              Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(textColor)
              Text("Margin \(percent(reportsVM.profitMargin))")
                .font(Typography.caption1.weight(.semibold))
                .foregroundColor(textColor)
            }
            .padding(.horizontal, 12)
          )
      }

      HStack(spacing: 12) {
        pill(
          icon: "arrow.up.forward.circle.fill",
          title: "Revenue",
          value: currency(reportsVM.totalSales),
          color: .marketGreen
        )
        pill(
          icon: "arrow.down.circle.fill",
          title: "Costs",
          value: currency(reportsVM.totalCosts),
          color: .red
        )
      }
    }
    .padding()
    .background(cardBackground)
    .cornerRadius(CornerRadius.md)
    .shadow(color: strokeColor, radius: 10, x: 0, y: 8)
    .padding(.horizontal)
  }

  private var metricsGrid: some View {
    LazyVGrid(columns: metricColumns, spacing: 12) {
      MetricCard(
        title: "Total Sales",
        value: currency(reportsVM.totalSales),
        subtitle: "Revenue in range",
        icon: "tag.fill",
        color: .marketGreen
      )
      MetricCard(
        title: "Total Costs",
        value: currency(reportsVM.totalCosts),
        subtitle: "Operating spend",
        icon: "arrow.down.circle.fill",
        color: .red
      )
      MetricCard(
        title: "Avg Ticket",
        value: currency(reportsVM.averageTicket),
        subtitle: "\(reportsVM.salesCount) orders recorded",
        icon: "person.2.fill",
        color: .marketBlue
      )
      MetricCard(
        title: "Orders",
        value: "\(reportsVM.salesCount)",
        subtitle: "Transactions in range",
        icon: "chart.bar.fill",
        color: .marketYellow
      )
    }
    .padding(.horizontal)
  }

  private var performanceHighlights: some View {
    let costRatio = reportsVM.totalSales > 0 ? reportsVM.totalCosts / reportsVM.totalSales : 0

    return VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Performance pulse", subtitle: "Averages and stability")

      HStack(spacing: 12) {
        MiniStat(
          title: "Avg per day",
          value: currency(reportsVM.averageDailySales),
          caption: reportsVM.selectedTimeRange.rawValue
        )
        MiniStat(
          title: "Best day",
          value: reportsVM.bestDay.map { currency($0.amount) } ?? "—",
          caption: reportsVM.bestDay.map { formattedDate($0.date) } ?? "No sales"
        )
        MiniStat(
          title: "Cost ratio",
          value: percent(costRatio),
          caption: "vs revenue"
        )
      }
      .padding()
      .background(cardBackground)
      .cornerRadius(CornerRadius.md)
    }
    .padding(.horizontal)
  }

  private var trendSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Sales trend", subtitle: "Daily market pace")

      if reportsVM.salesData.isEmpty {
        Text("No sales in this period.")
          .font(Typography.caption1)
          .foregroundColor(secondaryTextColor)
          .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
      } else {
        Chart {
          ForEach(reportsVM.salesData) { data in
            AreaMark(
              x: .value("Date", data.date, unit: .day),
              y: .value("Sales", data.amount)
            )
            .foregroundStyle(
              LinearGradient(
                colors: [Color.marketBlue.opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .bottom
              )
            )

            LineMark(
              x: .value("Date", data.date, unit: .day),
              y: .value("Sales", data.amount)
            )
            .foregroundStyle(Color.marketBlue)
            .lineStyle(StrokeStyle(lineWidth: 3, lineJoin: .round))

            PointMark(
              x: .value("Date", data.date, unit: .day),
              y: .value("Sales", data.amount)
            )
            .foregroundStyle(textColor)
            .symbolSize(30)
          }
        }
        .transaction { transaction in
          transaction.animation = nil
        }
        .chartYAxis {
          AxisMarks(position: .leading) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
              .foregroundStyle(secondaryTextColor.opacity(0.4))
            AxisValueLabel {
              if let doubleValue = value.as(Double.self) {
                Text("\(profileVM.currencySymbol)\(Int(doubleValue))")
                  .foregroundColor(secondaryTextColor)
              }
            }
          }
        }
        .chartXAxis {
          AxisMarks(values: .automatic(desiredCount: 6)) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
              .foregroundStyle(strokeColor)
            AxisValueLabel(format: .dateTime.day().month(), centered: true)
              .foregroundStyle(secondaryTextColor)
          }
        }
        .frame(height: 240)
      }
    }
    .padding()
    .background(cardBackground)
    .cornerRadius(CornerRadius.md)
    .padding(.horizontal)
  }

  private func breakdownSection(
    title: String,
    subtitle: String,
    items: [ReportsViewModel.Breakdown],
    accent: Color
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader(title, subtitle: subtitle)

      if items.isEmpty {
        Text("Not enough data yet.")
          .font(Typography.caption1)
          .foregroundColor(secondaryTextColor)
      } else {
        ForEach(items.prefix(4)) { item in
          BreakdownRow(
            label: item.label,
            value: currency(item.value),
            percentageText: percent(item.percentage),
            progress: item.percentage,
            accent: accent
          )
        }
      }
    }
    .padding()
    .background(cardBackground)
    .cornerRadius(CornerRadius.md)
    .padding(.horizontal)
  }

  private var emptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "chart.bar.doc.horizontal")
        .font(.largeTitle)
        .foregroundColor(secondaryTextColor)
      Text("No activity in this range yet.")
        .font(Typography.subheadline)
        .foregroundColor(textColor)
      Text("Log sales or costs to unlock the full business report.")
        .font(Typography.caption1)
        .foregroundColor(secondaryTextColor)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(cardBackground)
    .cornerRadius(CornerRadius.md)
    .padding(.horizontal)
  }

  private var updatingPill: some View {
    Capsule()
      .fill(Color.black.opacity(0.25))
      .frame(height: 32)
      .overlay(
        HStack(spacing: 8) {
          Image(systemName: "clock.arrow.2.circlepath")
            .foregroundColor(textColor)
          Text("Updating")
            .font(Typography.caption2)
            .foregroundColor(textColor)
        }
        .padding(.horizontal, 12)
      )
      .padding(.horizontal)
      .padding(.top, 8)
  }

  private func pill(icon: String, title: String, value: String, color: Color) -> some View {
    HStack(spacing: 10) {
      Circle()
        .fill(color.opacity(0.15))
        .frame(width: 32, height: 32)
        .overlay(
          Image(systemName: icon)
            .foregroundColor(color)
        )

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(Typography.caption1)
          .foregroundColor(secondaryTextColor)
        Text(value)
          .font(Typography.body.weight(.semibold))
          .foregroundColor(textColor)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .background(cardBackground)
    .cornerRadius(CornerRadius.sm)
  }

  private func sectionHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(Typography.subheadline.weight(.semibold))
        .foregroundColor(textColor)
      Text(subtitle)
        .font(Typography.caption1)
        .foregroundColor(secondaryTextColor)
    }
  }

  private func currency(_ value: Double) -> String {
    "\(profileVM.currencySymbol)\(String(format: "%.2f", value))"
  }

  private func percent(_ value: Double) -> String {
    let percentValue = value * 100
    return "\(String(format: "%.0f", percentValue))%"
  }

  private func formattedDate(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
  }
}

struct MetricCard: View {
  let title: String
  let value: String
  let subtitle: String
  let icon: String
  let color: Color
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
          .font(Typography.subheadline)
          .foregroundColor(secondaryTextColor)
        Spacer()
        Image(systemName: icon)
          .foregroundColor(color)
      }

      Text(value)
        .font(Typography.title2)
        .foregroundColor(textColor)

      Text(subtitle)
        .font(Typography.caption2)
        .foregroundColor(secondaryTextColor)
    }
    .padding()
    .background(cardBackground)
    .cornerRadius(CornerRadius.md)
  }
}

struct MiniStat: View {
  let title: String
  let value: String
  let caption: String
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(Typography.caption1)
        .foregroundColor(secondaryTextColor)
      Text(value)
        .font(Typography.title3.weight(.semibold))
        .foregroundColor(textColor)
      Text(caption)
        .font(Typography.caption2)
        .foregroundColor(secondaryTextColor)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct BreakdownRow: View {
  let label: String
  let value: String
  let percentageText: String
  let progress: Double
  let accent: Color
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var strokeColor: Color { themeManager.strokeColor }
  private var cardBackground: Color { themeManager.cardBackground }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(label)
          .font(Typography.subheadline)
          .foregroundColor(textColor)
        Spacer()
        Text(percentageText)
          .font(Typography.caption1.weight(.semibold))
          .foregroundColor(accent)
      }

      HStack {
        Text(value)
          .font(Typography.caption1)
          .foregroundColor(secondaryTextColor)
        Spacer()
      }

      ProgressView(value: progress)
        .tint(accent)
    }
  }
}
