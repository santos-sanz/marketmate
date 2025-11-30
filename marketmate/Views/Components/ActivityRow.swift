import SwiftUI

struct ActivityRow: View {
  let activity: Activity
  let currency: String

  private var iconName: String {
    switch activity.type {
    case .sale: return "tag.fill"
    case .cost: return "arrow.down.circle.fill"
    case .productCreated, .productUpdated, .productDeleted: return "cube.box.fill"
    case .marketOpened: return "tent.fill"
    case .marketClosed: return "tent"
    }
  }

  private var iconColor: Color {
    switch activity.type {
    case .sale: return .marketGreen
    case .cost: return .red
    case .productCreated, .productUpdated, .productDeleted: return .marketBlue
    case .marketOpened, .marketClosed: return .yellow
    }
  }

  private var backgroundColor: Color {
    switch activity.type {
    case .sale: return Color.marketGreen.opacity(0.2)
    case .cost: return Color.red.opacity(0.2)
    case .productCreated, .productUpdated, .productDeleted: return Color.marketBlue.opacity(0.2)
    case .marketOpened, .marketClosed: return Color.yellow.opacity(0.2)
    }
  }

  var body: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(backgroundColor)
        .frame(width: 28, height: 28)
        .overlay(
          Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(Typography.caption1.weight(.bold))
        )

      VStack(alignment: .leading, spacing: 1) {
        Text(activity.title)
          .font(Typography.subheadline.weight(.medium))
          .foregroundColor(.white)

        if let subtitle = activity.subtitle {
          Text(subtitle)
            .font(Typography.caption2)
            .foregroundColor(.marketTextSecondary)
            .lineLimit(1)
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 1) {
        if let qty = activity.quantity {
          Text("\(qty > 0 ? "+" : "")\(qty)")
            .font(Typography.subheadline.weight(.semibold))
            .foregroundColor(.white)
        } else if let amount = activity.amount {
          let isPositive = activity.type == .sale
          Text("\(isPositive ? "+" : "-")\(currency)\(String(format: "%.2f", amount))")
            .font(Typography.subheadline.weight(.semibold))
            .foregroundColor(.white)
        }

        Text(timestamp)
          .font(Typography.caption2)
          .foregroundColor(.marketTextSecondary)
      }
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
    .contentShape(Rectangle())
  }

  private var timestamp: String {
    let calendar = Calendar.current
    if calendar.isDateInToday(activity.createdAt) {
      return "Today \(activity.createdAt.formatted(date: .omitted, time: .shortened))"
    }
    if calendar.isDateInYesterday(activity.createdAt) {
      return "Yesterday \(activity.createdAt.formatted(date: .omitted, time: .shortened))"
    }
    return
      "\(activity.createdAt.formatted(date: .abbreviated, time: .omitted)) \(activity.createdAt.formatted(date: .omitted, time: .shortened))"
  }
}
