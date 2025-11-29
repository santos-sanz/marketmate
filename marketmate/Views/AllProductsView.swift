import SwiftUI

struct AllProductsView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.dismiss) var dismiss

  @State private var searchText = ""

  var filteredProducts: [Product] {
    if searchText.isEmpty {
      return inventoryVM.products
    } else {
      return inventoryVM.products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
  }

  let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]

  var body: some View {
    ZStack {
      Color.clear.revolutBackground().ignoresSafeArea()

      VStack(spacing: 0) {
        // Header
        HStack {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .font(.title2)
              .foregroundColor(.white)
          }

          Spacer()

          Text("All Products")
            .font(.headline)
            .foregroundColor(.white)

          Spacer()

          // Hidden placeholder to balance the back button
          Image(systemName: "chevron.left")
            .font(.title2)
            .foregroundColor(.clear)
        }
        .padding()
        .background(Color.white.opacity(0.1))

        // Search Bar
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.marketTextSecondary)
          TextField("Search products", text: $searchText)
            .foregroundColor(.white)
            .accentColor(.white)
            .placeholder(when: searchText.isEmpty) {
              Text("Search products").foregroundColor(.marketTextSecondary)
            }
        }
        .searchBarStyle()
        .padding()

        ScrollView {
          LazyVGrid(columns: columns, spacing: Spacing.xs) {
            ForEach(filteredProducts) { product in
              ProductCardWithQuantity(
                product: product,
                quantity: salesVM.quantityInCart(for: product),
                action: {
                  salesVM.addToCart(product: product)
                }
              )
            }
          }
          .padding(.horizontal, Spacing.sm)
          .padding(.bottom, 100)  // Space for cart summary
        }
      }

      // Cart Summary Overlay
      if !salesVM.cartItems.isEmpty {
        VStack {
          Spacer()
          VStack(spacing: 0) {
            HStack(alignment: .center) {
              VStack(alignment: .leading, spacing: 2) {
                Text("\(salesVM.cartItems.reduce(0) { $0 + $1.quantity }) items")
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundColor(.white.opacity(0.8))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                  Text("Total")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                  
                  Text("\(profileVM.currencySymbol) \(String(format: "%.2f", salesVM.cartTotal))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                }
              }
              
              Spacer()
              
              Button(action: {
                dismiss() // Go back to SalesView to checkout
              }) {
                HStack {
                  Text("View Cart")
                    .font(.headline)
                    .fontWeight(.semibold)
                  Image(systemName: "cart.fill")
                    .font(.headline)
                }
                .foregroundColor(.marketBlue)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(30)
              }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .padding(.bottom, 8) // Extra padding for safe area if needed
          }
          .background(
            Rectangle()
              .fill(.ultraThinMaterial)
              .overlay(Color.black.opacity(0.2))
          )
          .cornerRadius(24, corners: [.topLeft, .topRight])
          .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        }
      }
    }
    .navigationBarHidden(true)
  }
}

struct ProductCardWithQuantity: View {
  let product: Product
  let quantity: Int
  let action: () -> Void
  @EnvironmentObject var profileVM: ProfileViewModel

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: Spacing.xxs) {
        HStack(alignment: .top) {
          Text(product.name)
            .font(Typography.headline)
            .foregroundColor(.white)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

          if quantity > 0 {
            Text("\(quantity)")
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .padding(6)
              .background(Color.marketGreen)
              .clipShape(Circle())
          }
        }

        Spacer()

        Text("\(profileVM.currencySymbol) \(String(format: "%.2f", product.price))")
          .font(Typography.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)
      }
      .frame(height: 100)
      .padding(Spacing.sm)
      .background(Color.marketCard)
      .cornerRadius(CornerRadius.sm)
      .overlay(
        RoundedRectangle(cornerRadius: CornerRadius.sm)
          .stroke(quantity > 0 ? Color.marketGreen : Color.clear, lineWidth: 2)
      )
    }
  }
}
