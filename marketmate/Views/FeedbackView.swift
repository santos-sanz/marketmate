import SwiftUI

struct FeedbackView: View {
  @StateObject private var viewModel = FeedbackViewModel()
  @State private var selectedTab = 0
  @State private var bugDescription = ""
  @State private var showingAddFeature = false
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color.marketBlue,
          Color.marketDarkBlue,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // Custom Segmented Control
        HStack {
          SegmentButton(title: "Report Bug", isSelected: selectedTab == 0) {
            selectedTab = 0
          }
          SegmentButton(title: "Feature Requests", isSelected: selectedTab == 1) {
            selectedTab = 1
          }
        }
        .padding()
        .background(Color.white.opacity(0.1))

        if selectedTab == 0 {
          BugReportView(description: $bugDescription, viewModel: viewModel)
        } else {
          FeatureRequestListView(viewModel: viewModel, showingAddFeature: $showingAddFeature)
        }
      }
    }
    .navigationTitle("Feedback & Support")
    .navigationBarTitleDisplayMode(.inline)
    // Close button is not needed in push navigation usually, but if we want to keep it for consistency or if it was modally presented before:
    // Since it's now pushed, the back button is automatic. We can remove the toolbar close button.
  }
}

struct SegmentButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(isSelected ? .bold : .regular)
        .foregroundColor(isSelected ? .marketBlue : .white)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.white : Color.clear)
        .cornerRadius(8)
    }
  }
}

struct BugReportView: View {
  @Binding var description: String
  @ObservedObject var viewModel: FeedbackViewModel
  @State private var showingSuccess = false

  var body: some View {
    VStack(spacing: 20) {
      Text("Found a bug? Let us know!")
        .font(.headline)
        .foregroundColor(.white)
        .padding(.top)

      TextEditor(text: $description)
        .frame(height: 150)
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .foregroundColor(.black)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)

      Button(action: {
        Task {
          if await viewModel.submitBug(description: description) {
            description = ""
            showingSuccess = true
          }
        }
      }) {
        if viewModel.isLoading {
          ProgressView().tint(.white)
        } else {
          Text("Submit Bug Report")
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.marketBlue)
            .cornerRadius(12)
        }
      }
      .disabled(description.isEmpty || viewModel.isLoading)
      .opacity(description.isEmpty ? 0.6 : 1)
      .padding(.horizontal)

      Spacer()
    }
    .alert("Thank You!", isPresented: $showingSuccess) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Your bug report has been submitted successfully.")
    }
  }
}

struct FeatureRequestListView: View {
  @ObservedObject var viewModel: FeedbackViewModel
  @Binding var showingAddFeature: Bool

  var body: some View {
    ZStack {
      if viewModel.isLoading && viewModel.featureRequests.isEmpty {
        ProgressView().tint(.white)
      } else {
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(viewModel.featureRequests) { feature in
              FeatureRow(feature: feature, viewModel: viewModel)
            }
          }
          .padding()
        }
        .refreshable {
          await viewModel.fetchFeatureRequests()
        }
      }

      // Floating Action Button
      VStack {
        Spacer()
        HStack {
          Spacer()
          Button(action: { showingAddFeature = true }) {
            Image(systemName: "plus")
              .font(.title)
              .foregroundColor(.white)
              .frame(width: 60, height: 60)
              .background(Color.marketBlue)
              .clipShape(Circle())
              .shadow(radius: 4)
          }
          .padding()
        }
      }
    }
    .onAppear {
      Task {
        await viewModel.fetchFeatureRequests()
      }
    }
    .navigationDestination(isPresented: $showingAddFeature) {
      AddFeatureView(viewModel: viewModel)
    }
  }
}

struct FeatureRow: View {
  let feature: FeatureRequest
  @ObservedObject var viewModel: FeedbackViewModel

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(feature.title)
          .font(.headline)
          .foregroundColor(.white)
        Text(feature.description)
          .font(.caption)
          .foregroundColor(.white.opacity(0.7))
          .lineLimit(3)
      }

      Spacer()

      Button(action: {
        Task {
          await viewModel.toggleVote(for: feature)
        }
      }) {
        VStack(spacing: 4) {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title2)
            .foregroundColor(feature.hasVoted == true ? .marketGreen : .white.opacity(0.3))

          Text("\(feature.votes)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
      }
    }
    .padding()
    .background(Color.marketCard)
    .cornerRadius(12)
  }
}

struct AddFeatureView: View {
  @ObservedObject var viewModel: FeedbackViewModel
  @Environment(\.presentationMode) var presentationMode
  @State private var title = ""
  @State private var description = ""

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color.marketBlue,
          Color.marketDarkBlue,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      Form {
        Section(header: Text("Feature Details").foregroundColor(.white.opacity(0.7))) {
          TextField("Title", text: $title)
            .foregroundColor(.white)

          ZStack(alignment: .topLeading) {
            if description.isEmpty {
              Text("Description")
                .foregroundColor(.white.opacity(0.3))
                .padding(.top, 8)
                .padding(.leading, 4)
            }
            TextEditor(text: $description)
              .frame(height: 100)
              .foregroundColor(.white)
              .scrollContentBackground(.hidden)
          }
        }
        .listRowBackground(Color.white.opacity(0.15))

        Section {
          Button(action: {
            Task {
              if await viewModel.submitFeatureRequest(title: title, description: description) {
                presentationMode.wrappedValue.dismiss()
              }
            }
          }) {
            if viewModel.isLoading {
              ProgressView()
            } else {
              Text("Submit Request")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
          }
          .listRowBackground(Color.marketBlue)
          .disabled(title.isEmpty || description.isEmpty)
        }
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("New Feature")
    .navigationBarTitleDisplayMode(.inline)
  }
}
