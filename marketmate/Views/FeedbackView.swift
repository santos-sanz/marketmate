import SwiftUI

struct FeedbackView: View {
  @StateObject private var viewModel = FeedbackViewModel()
  @State private var selectedTab = 0
  @State private var bugDescription = ""
  @State private var showingAddFeature = false
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var themeManager: ThemeManager

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var strokeColor: Color { themeManager.strokeColor }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

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
      .background(cardBackground)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(strokeColor, lineWidth: 1)
      )

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
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(isSelected ? .bold : .regular)
        .foregroundColor(isSelected ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
          isSelected ? themeManager.cardBackground : Color.clear
        )
        .cornerRadius(8)
    }
  }
}

struct BugReportView: View {
  @Binding var description: String
  @ObservedObject var viewModel: FeedbackViewModel
  @State private var showingSuccess = false
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var strokeColor: Color { themeManager.strokeColor }

  var body: some View {
    VStack(spacing: 20) {
      Text("Found a bug? Let us know!")
        .font(.headline)
        .foregroundColor(textColor)
        .padding(.top)

      TextEditor(text: $description)
        .frame(height: 150)
        .padding(8)
        .background(cardBackground)
        .cornerRadius(8)
        .foregroundColor(textColor)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(strokeColor, lineWidth: 1)
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
          ProgressView().tint(textColor)
        } else {
          Text("Submit Bug Report")
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(cardBackground)
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
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var strokeColor: Color { themeManager.strokeColor }

  var body: some View {
    ZStack {
      if viewModel.isLoading && viewModel.featureRequests.isEmpty {
        ProgressView().tint(textColor)
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
              .foregroundColor(textColor)
              .frame(width: 60, height: 60)
              .background(cardBackground)
              .clipShape(Circle())
              .shadow(color: strokeColor, radius: 4)
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
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(feature.title)
          .font(.headline)
          .foregroundColor(textColor)
        Text(feature.description)
          .font(.caption)
          .foregroundColor(secondaryTextColor)
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
            .foregroundColor(feature.hasVoted == true ? .marketGreen : secondaryTextColor)

          Text("\(feature.votes)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(textColor)
        }
        .padding(8)
        .background(cardBackground)
        .cornerRadius(8)
      }
    }
    .padding()
    .background(cardBackground)
    .cornerRadius(12)
  }
}

struct AddFeatureView: View {
  @ObservedObject var viewModel: FeedbackViewModel
  @Environment(\.presentationMode) var presentationMode
  @State private var title = ""
  @State private var description = ""
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      Form {
        Section(header: Text("Feature Details").foregroundColor(secondaryTextColor)) {
          TextField("Title", text: $title)
            .foregroundColor(textColor)

          ZStack(alignment: .topLeading) {
            if description.isEmpty {
              Text("Description")
                .foregroundColor(secondaryTextColor)
                .padding(.top, 8)
                .padding(.leading, 4)
            }
            TextEditor(text: $description)
              .frame(height: 100)
              .foregroundColor(textColor)
              .scrollContentBackground(.hidden)
          }
        }
        .listRowBackground(cardBackground)

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
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
            }
          }
          .listRowBackground(cardBackground)
          .disabled(title.isEmpty || description.isEmpty)
        }
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("New Feature")
    .navigationBarTitleDisplayMode(.inline)
  }
}
