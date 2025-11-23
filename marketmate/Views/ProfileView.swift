import SwiftUI
import UIKit

struct ProfileView: View {
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var authVM: AuthViewModel  // To handle sign out state if needed

  @State private var showingShareSheet = false
  @State private var exportURL: URL?
  @State private var showingDeleteAlert = false

  let currencies = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD"]
  let currencySymbols = ["$", "€", "£", "¥", "A$", "C$"]

  var body: some View {
    NavigationView {
      ZStack {
        Color.white.edgesIgnoringSafeArea(.all)

        if profileVM.isLoading {
          ProgressView()
            .tint(.marketBlue)
        } else {
          VStack(spacing: 24) {
            // Profile Header
            VStack(spacing: 8) {
              // Username removed as requested
              Text(authVM.currentUserEmail ?? "")
                .font(.headline)
                .foregroundColor(.gray)
            }
            .padding(.top, 20)

            Form {
              Section(header: Text("Settings").foregroundColor(.gray)) {
                Picker("Currency", selection: $profileVM.selectedCurrency) {
                  ForEach(currencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                  }
                }
                .onChange(of: profileVM.selectedCurrency) { _, newValue in
                  Task {
                    await profileVM.updateCurrency(newValue)
                  }
                }
              }
              .listRowBackground(Color.white)

              Section(header: Text("Data Management").foregroundColor(.gray)) {
                Button(action: {
                  Task {
                    if let url = await profileVM.exportData() {
                      exportURL = url
                      showingShareSheet = true
                    }
                  }
                }) {
                  HStack {
                    Text("Download Data (CSV)")
                      .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                      .foregroundColor(.marketBlue)
                  }
                }
              }
              .listRowBackground(Color.white)

              Section {
                Button(action: {
                  Task {
                    await authVM.signOut()
                  }
                }) {
                  Text("Sign Out")
                    .foregroundColor(.marketBlue)
                }
              }
              .listRowBackground(Color.white)

              Section(header: Text("Danger Zone").foregroundColor(.red)) {
                Button(action: { showingDeleteAlert = true }) {
                  Text("Delete Account")
                    .foregroundColor(.red)
                }
              }
              .listRowBackground(Color.white)
            }
            .scrollContentBackground(.hidden)
          }
        }
      }
      .navigationTitle("Profile")
      .onAppear {
        Task {
          await profileVM.fetchProfile()
        }
      }
      .sheet(isPresented: $showingShareSheet) {
        if let url = exportURL {
          ShareSheet(activityItems: [url])
        }
      }
      .alert("Delete Account", isPresented: $showingDeleteAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          Task {
            await profileVM.deleteAccount()
            await authVM.checkSession()  // Refresh auth state to trigger logout in UI
          }
        }
      } message: {
        Text(
          "Are you sure you want to delete your account? This action cannot be undone and all your data will be lost."
        )
      }
    }
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  var activityItems: [Any]
  var applicationActivities: [UIActivity]? = nil

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems, applicationActivities: applicationActivities)
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
