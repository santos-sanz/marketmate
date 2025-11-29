import SwiftUI

struct ExpandedActivityView: View {
  let activity: Activity
  @ObservedObject var viewModel: ActivityViewModel
  var onEdit: (ActivityHistoryView.SheetType) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Basic Info (Always shown)
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Date")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(activity.createdAt.formatted(date: .long, time: .standard))
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      if viewModel.isLoadingDetails {
        ProgressView()
          .tint(.white)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical)
      } else if let details = viewModel.expandedDetails {
        Divider().background(Color.white.opacity(0.1))

        switch details {
        case .sale(let sale):
          SaleDetailsView(sale: sale)
        case .cost(let cost):
          CostDetailsView(cost: cost)
        case .product(let product):
          ProductDetailsView(product: product)
        case .market(let market):
          MarketDetailsView(market: market)
        }
      } else {
        // Fallback for simple activities or if fetch failed/not needed
        if let amount = activity.amount {
          Divider().background(Color.white.opacity(0.1))
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Amount")
                .font(.caption)
                .foregroundColor(.marketTextSecondary)
              Text(String(format: "%.2f", amount))
                .font(.subheadline)
                .foregroundColor(.white)
            }
            Spacer()
          }
        }
      }
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .overlay(alignment: .topTrailing) {
      if let details = viewModel.expandedDetails {
        Button(action: {
          switch details {
          case .sale(let sale):
            onEdit(.editSale(sale))
          case .cost(let cost):
            onEdit(.editCost(cost))
          case .product(let product):
            onEdit(.editProduct(product))
          case .market(let market):
            onEdit(.editMarket(market))
          }
        }) {
          Image(systemName: "pencil.circle.fill")
            .font(.title2)
            .foregroundColor(.marketBlue)
            .padding(8)
        }
      }
    }
  }
}

struct SaleDetailsView: View {
  let sale: Sale

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Market Location
      if let location = sale.marketLocation {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Market")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(location)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
        Divider().background(Color.white.opacity(0.1))
      }

      // Payment Method
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Payment Method")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(sale.paymentMethod)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      Divider().background(Color.white.opacity(0.1))

      // Items
      if let items = sale.items, !items.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Items")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)

          ForEach(items) { item in
            HStack {
              Text("\(item.quantity)x \(item.productName)")
                .font(.subheadline)
                .foregroundColor(.white)
              Spacer()
              Text(String(format: "%.2f", item.priceAtSale * Double(item.quantity)))
                .font(.subheadline)
                .foregroundColor(.white)
            }
          }
        }
        Divider().background(Color.white.opacity(0.1))
      }

      // Total
      HStack {
        Text("Total")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
        Text(String(format: "%.2f", sale.totalAmount))
          .font(.headline)
          .foregroundColor(.marketGreen)
      }
    }
  }
}

struct CostDetailsView: View {
  let cost: Cost
  @EnvironmentObject var costsVM: CostsViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let categoryId = cost.categoryId,
        let categoryName = costsVM.categories.first(where: { $0.id == categoryId })?.name
      {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Category")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(categoryName)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
        Divider().background(Color.white.opacity(0.1))
      }

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Description")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(cost.description)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      Divider().background(Color.white.opacity(0.1))

      HStack {
        Text("Amount")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
        Text(String(format: "%.2f", cost.amount))
          .font(.headline)
          .foregroundColor(.red)
      }
    }
  }
}

struct ProductDetailsView: View {
  let product: Product
  @EnvironmentObject var inventoryVM: InventoryViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Product Name")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(product.name)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      Divider().background(Color.white.opacity(0.1))

      if let description = product.description, !description.isEmpty {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Description")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(description)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
        Divider().background(Color.white.opacity(0.1))
      }

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Price")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(String(format: "%.2f", product.price))
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()

        if let cost = product.cost {
          VStack(alignment: .trailing, spacing: 4) {
            Text("Cost")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(String(format: "%.2f", cost))
              .font(.subheadline)
              .foregroundColor(.white)
          }
        }
      }

      if let stock = product.stockQuantity {
        Divider().background(Color.white.opacity(0.1))
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Stock Quantity")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text("\(stock)")
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
      }

      if let categoryId = product.categoryId,
        let categoryName = inventoryVM.categories.first(where: { $0.id == categoryId })?.name
      {
        Divider().background(Color.white.opacity(0.1))
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Category")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(categoryName)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
      }
    }
  }
}

struct MarketDetailsView: View {
  let market: Market

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Market Name")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(market.name)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      if let location = market.location {
        Divider().background(Color.white.opacity(0.1))
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Location")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(location)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
      }

      Divider().background(Color.white.opacity(0.1))

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Date")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(market.date.formatted(date: .long, time: .omitted))
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text("Status")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(market.isOpen ? "Open" : "Closed")
            .font(.subheadline)
            .foregroundColor(market.isOpen ? .marketGreen : .red)

          if !market.isOpen, let endTime = market.endTime {
            Text(endTime.formatted(date: .omitted, time: .shortened))
              .font(.caption2)
              .foregroundColor(.marketTextSecondary)
          }
        }
      }
    }
  }
}
