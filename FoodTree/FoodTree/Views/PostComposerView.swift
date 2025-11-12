//
//  PostComposerView.swift
//  FoodTree
//
//  Multi-step post composer with camera, tags, and location
//

import SwiftUI
import PhotosUI
import Combine
import CoreLocation

struct PostComposerView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = PostComposerViewModel()
    @State private var showSuccessView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgElev1.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressBar(currentStep: viewModel.currentStep, totalSteps: 5)
                        .padding(.horizontal, FTLayout.paddingM)
                        .padding(.vertical, 12)
                    
                    // Content
                    TabView(selection: $viewModel.currentStep) {
                        PhotoStepView(viewModel: viewModel)
                            .tag(1)
                        
                        DetailsStepView(viewModel: viewModel)
                            .tag(2)
                        
                        QuantityStepView(viewModel: viewModel)
                            .tag(3)
                        
                        LocationStepView(viewModel: viewModel)
                            .tag(4)
                        
                        ReviewStepView(viewModel: viewModel)
                            .tag(5)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: viewModel.currentStep)
                    
                    // Navigation buttons
                    HStack(spacing: 12) {
                        if viewModel.currentStep > 1 {
                            Button(action: {
                                viewModel.previousStep()
                                FTHaptics.light()
                            }) {
                                Text("Back")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.inkSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.bgElev2Card)
                                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                            }
                        }
                        
                        Button(action: {
                            if viewModel.currentStep == 5 {
                                publishPost()
                            } else {
                                viewModel.nextStep()
                                FTHaptics.light()
                            }
                        }) {
                            Text(viewModel.currentStep == 5 ? "Publish" : "Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.canProceed ? Color.brandPrimary : Color.inkMuted)
                                .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                        }
                        .disabled(!viewModel.canProceed)
                    }
                    .padding(FTLayout.paddingM)
                    .background(Color.bgElev2Card.ignoresSafeArea())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.inkSecondary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Post Food")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .fullScreenCover(isPresented: $showSuccessView) {
            PostSuccessView(isPresented: $isPresented)
        }
    }
    
    private func publishPost() {
        FTHaptics.success()
        showSuccessView = true
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? Color.brandPrimary : Color.strokeSoft)
                    .frame(height: 4)
                    .animation(FTAnimation.easeInOut, value: currentStep)
            }
        }
    }
}

// MARK: - Step 1: Photos
struct PhotoStepView: View {
    @ObservedObject var viewModel: PostComposerViewModel
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add photos")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    Text("Show what's available. Great photos help students find your food!")
                        .font(.system(size: 16))
                        .foregroundColor(.inkSecondary)
                }
                
                // Photo grid
                if viewModel.photos.isEmpty {
                    VStack(spacing: 16) {
                        Button(action: {
                            showCamera = true
                            FTHaptics.light()
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.brandPrimary)
                                
                                Text("Take Photo")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.inkPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.brandPrimary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                            .overlay(
                                RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundColor(.brandPrimary.opacity(0.3))
                            )
                        }
                        
                        Button(action: {
                            showImagePicker = true
                            FTHaptics.light()
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.inkSecondary)
                                
                                Text("Choose from Library")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.inkPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .background(Color.bgElev2Card)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                            .ftShadow()
                        }
                    }
                } else {
                    // Show selected photos
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.photos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                                
                                Button(action: {
                                    viewModel.removePhoto(at: index)
                                    FTHaptics.light()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.3)).padding(-4))
                                }
                                .padding(8)
                            }
                        }
                        
                        if viewModel.photos.count < 4 {
                            Button(action: {
                                showImagePicker = true
                                FTHaptics.light()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.brandPrimary)
                                    
                                    Text("Add")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.inkSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(Color.bgElev2Card)
                                .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                        .strokeBorder(Color.strokeSoft, lineWidth: 2)
                                )
                            }
                        }
                    }
                }
            }
            .padding(FTLayout.paddingM)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $viewModel.photos)
        }
    }
}

// MARK: - Step 2: Details
struct DetailsStepView: View {
    @ObservedObject var viewModel: PostComposerViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's available?")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    Text("Add a clear title and description")
                        .font(.system(size: 16))
                        .foregroundColor(.inkSecondary)
                }
                
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                    
                    TextField("e.g., Leftover pizza slices", text: $viewModel.title)
                        .font(.system(size: 17))
                        .padding(16)
                        .background(Color.bgElev2Card)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                        .overlay(
                            RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                .strokeBorder(Color.strokeSoft, lineWidth: 1)
                        )
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (optional)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                    
                    TextField("Add details about the food", text: $viewModel.description, axis: .vertical)
                        .font(.system(size: 17))
                        .lineLimit(3...6)
                        .padding(16)
                        .background(Color.bgElev2Card)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                        .overlay(
                            RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                .strokeBorder(Color.strokeSoft, lineWidth: 1)
                        )
                }
                
                Divider()
                
                // Dietary tags
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dietary information")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(DietaryTag.allCases) { tag in
                            DietaryFilterChip(
                                tag: tag,
                                isSelected: viewModel.dietaryTags.contains(tag)
                            ) {
                                if viewModel.dietaryTags.contains(tag) {
                                    viewModel.dietaryTags.remove(tag)
                                } else {
                                    viewModel.dietaryTags.insert(tag)
                                }
                            }
                        }
                    }
                }
            }
            .padding(FTLayout.paddingM)
        }
    }
}

// MARK: - Step 3: Quantity & Perishability
struct QuantityStepView: View {
    @ObservedObject var viewModel: PostComposerViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How much is available?")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    Text("Help students know if there's enough")
                        .font(.system(size: 16))
                        .foregroundColor(.inkSecondary)
                }
                
                // Quantity slider
                QuantitySlider(quantity: $viewModel.quantity, range: 1...100)
                
                Divider()
                
                // Perishability
                VStack(alignment: .leading, spacing: 16) {
                    Text("Perishability")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    VStack(spacing: 12) {
                        ForEach([FoodPost.Perishability.low, .medium, .high], id: \.self) { level in
                            Button(action: {
                                viewModel.perishability = level
                                FTHaptics.light()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .stroke(viewModel.perishability == level ? Color.brandPrimary : Color.strokeSoft, lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                        
                                        if viewModel.perishability == level {
                                            Circle()
                                                .fill(Color.brandPrimary)
                                                .frame(width: 12, height: 12)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(level.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.inkPrimary)
                                        
                                        Text(perishabilityDescription(level))
                                            .font(.system(size: 14))
                                            .foregroundColor(.inkSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.bgElev2Card)
                                .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                        .strokeBorder(
                                            viewModel.perishability == level ? Color.brandPrimary : Color.strokeSoft,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                        }
                    }
                }
                
                Divider()
                
                // Time window
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available for how long?")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    HStack(spacing: 12) {
                        ForEach([30, 60, 90], id: \.self) { minutes in
                            Button(action: {
                                viewModel.expiryMinutes = minutes
                                FTHaptics.light()
                            }) {
                                Text("\(minutes) min")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(viewModel.expiryMinutes == minutes ? .white : .inkPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.expiryMinutes == minutes ? Color.brandPrimary : Color.bgElev2Card)
                                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                            .strokeBorder(
                                                viewModel.expiryMinutes == minutes ? Color.clear : Color.strokeSoft,
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }
            }
            .padding(FTLayout.paddingM)
        }
    }
    
    private func perishabilityDescription(_ level: FoodPost.Perishability) -> String {
        switch level {
        case .low: return "Packaged, dry goods, or shelf-stable"
        case .medium: return "Should be consumed within an hour"
        case .high: return "Must be consumed soon, kept cold/hot"
        }
    }
}

// MARK: - Step 4: Location
struct LocationStepView: View {
    @ObservedObject var viewModel: PostComposerViewModel
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where can students pick it up?")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    Text("Be specific so people can find you easily")
                        .font(.system(size: 16))
                        .foregroundColor(.inkSecondary)
                }
                
                // Building search
                VStack(alignment: .leading, spacing: 8) {
                    Text("Building")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                    
                    TextField("Search buildings", text: $searchText)
                        .font(.system(size: 17))
                        .padding(16)
                        .background(Color.bgElev2Card)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                        .overlay(
                            RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                .strokeBorder(Color.strokeSoft, lineWidth: 1)
                        )
                }
                
                // Building suggestions
                VStack(spacing: 8) {
                    ForEach(filteredBuildings, id: \.name) { building in
                        Button(action: {
                            viewModel.selectedBuilding = building.name
                            viewModel.location = building.coordinate
                            searchText = building.name
                            FTHaptics.light()
                        }) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.brandPrimary)
                                
                                Text(building.name)
                                    .font(.system(size: 16))
                                    .foregroundColor(.inkPrimary)
                                
                                Spacer()
                                
                                if viewModel.selectedBuilding == building.name {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                            .padding(16)
                            .background(Color.bgElev2Card)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                            .overlay(
                                RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                    .strokeBorder(
                                        viewModel.selectedBuilding == building.name ? Color.brandPrimary : Color.strokeSoft,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                
                Divider()
                
                // Access notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access instructions")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                    
                    TextField("e.g., Second floor lounge, near elevators", text: $viewModel.accessNotes, axis: .vertical)
                        .font(.system(size: 17))
                        .lineLimit(2...4)
                        .padding(16)
                        .background(Color.bgElev2Card)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                        .overlay(
                            RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                .strokeBorder(Color.strokeSoft, lineWidth: 1)
                        )
                }
            }
            .padding(FTLayout.paddingM)
        }
    }
    
    private var filteredBuildings: [StanfordBuilding] {
        if searchText.isEmpty {
            return MockData.buildings
        } else {
            return MockData.buildings.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

// MARK: - Step 5: Review & Publish
struct ReviewStepView: View {
    @ObservedObject var viewModel: PostComposerViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review your post")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    Text("Make sure everything looks good")
                        .font(.system(size: 16))
                        .foregroundColor(.inkSecondary)
                }
                
                // Preview card
                VStack(alignment: .leading, spacing: 16) {
                    // Fake image preview
                    Rectangle()
                        .fill(Color.brandPrimary.opacity(0.1))
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.brandPrimary.opacity(0.3))
                                Text("\(viewModel.photos.count) photo\(viewModel.photos.count == 1 ? "" : "s")")
                                    .font(.system(size: 14))
                                    .foregroundColor(.inkMuted)
                            }
                        )
                    
                    Text(viewModel.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    if !viewModel.description.isEmpty {
                        Text(viewModel.description)
                            .font(.system(size: 15))
                            .foregroundColor(.inkSecondary)
                    }
                    
                    if !viewModel.dietaryTags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(Array(viewModel.dietaryTags)) { tag in
                                DietaryChip(tag: tag)
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portions")
                                .font(.system(size: 13))
                                .foregroundColor(.inkMuted)
                            Text("~\(viewModel.quantity)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available for")
                                .font(.system(size: 13))
                                .foregroundColor(.inkMuted)
                            Text("\(viewModel.expiryMinutes) min")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                        }
                        
                        Spacer()
                    }
                    
                    if let building = viewModel.selectedBuilding {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.brandPrimary)
                            Text(building)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.inkPrimary)
                        }
                        
                        if !viewModel.accessNotes.isEmpty {
                            Text(viewModel.accessNotes)
                                .font(.system(size: 14))
                                .foregroundColor(.inkSecondary)
                                .padding(.leading, 24)
                        }
                    }
                }
                .padding(FTLayout.paddingM)
                .background(Color.bgElev2Card)
                .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                .ftShadow()
                
                Divider()
                
                // Responsible sharing checklist
                VStack(alignment: .leading, spacing: 16) {
                    Text("Responsible sharing")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    Toggle(isOn: $viewModel.agreedToGuidelines) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I confirm that:")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.inkPrimary)
                            
                            Text("• Food is accurately described with allergen info\n• Food was held at safe serving temperature\n• I've read the Community Guidelines")
                                .font(.system(size: 14))
                                .foregroundColor(.inkSecondary)
                        }
                    }
                    .tint(.brandPrimary)
                }
                .padding(FTLayout.paddingM)
                .background(Color.brandPrimary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
            }
            .padding(FTLayout.paddingM)
        }
    }
}

// MARK: - Post Composer ViewModel
class PostComposerViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var photos: [String] = []
    @Published var title = ""
    @Published var description = ""
    @Published var dietaryTags: Set<DietaryTag> = []
    @Published var quantity = 20
    @Published var perishability: FoodPost.Perishability = .medium
    @Published var expiryMinutes = 60
    @Published var selectedBuilding: String?
    @Published var location: CLLocationCoordinate2D?
    @Published var accessNotes = ""
    @Published var agreedToGuidelines = false
    
    var canProceed: Bool {
        switch currentStep {
        case 1: return !photos.isEmpty
        case 2: return !title.isEmpty
        case 3: return true
        case 4: return selectedBuilding != nil
        case 5: return agreedToGuidelines
        default: return false
        }
    }
    
    func nextStep() {
        if currentStep < 5 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func removePhoto(at index: Int) {
        photos.remove(at: index)
    }
}

// MARK: - Success View
struct PostSuccessView: View {
    @Binding var isPresented: Bool
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.brandPrimary.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                
                VStack(spacing: 12) {
                    Text("Post published! 🌳")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Students nearby will be notified")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        // Share link (stub)
                        FTHaptics.light()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share link")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                    }
                    
                    Button(action: {
                        FTHaptics.light()
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(FTLayout.paddingL)
        }
        .onAppear {
            showConfetti = true
            FTHaptics.success()
        }
    }
}

// MARK: - Image Picker Stub
struct ImagePicker: View {
    @Binding var images: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Photo picker would appear here")
                    .foregroundColor(.inkSecondary)
                
                Button("Add Mock Photo") {
                    images.append("mock_photo_\(images.count)")
                    FTHaptics.light()
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Select Photos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

