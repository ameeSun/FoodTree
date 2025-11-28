//
//  PostComposerView.swift
//  TreeBites
//
//  Multi-step post composer with camera, tags, and location
//

import SwiftUI
import Combine
import MapKit
import UIKit

struct PostComposerView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = PostComposerViewModel()
    @StateObject private var repository = FoodPostRepository()
    @State private var showSuccessView = false
    @State private var isPublishing = false
    @State private var publishError: String?
    
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
                            HStack {
                                if isPublishing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(viewModel.currentStep == 5 ? (isPublishing ? "Publishing..." : "Publish") : "Next")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background((viewModel.canProceed && !isPublishing) ? Color.brandPrimary : Color.inkMuted)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                        }
                        .disabled(!viewModel.canProceed || isPublishing)
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
        .alert("Error", isPresented: .constant(publishError != nil)) {
            Button("OK") {
                publishError = nil
            }
        } message: {
            Text(publishError ?? "")
        }
    }
    
    private func publishPost() {
        guard let location = viewModel.location else {
            publishError = "Location is required"
            return
        }
        
        // Check if user is authenticated
        guard AuthService.shared.isAuthenticated else {
            publishError = "You must be logged in to post food. Please sign in and try again."
            return
        }
        
        // Check if user has permission to post (only organizers/administrators can post)
        // Use AuthService which is the primary auth system used throughout the app
        guard let user = AuthService.shared.currentUser, user.role == .organizer else {
            publishError = "You are a student and unable to post. Only administrators can create food posts."
            return
        }
        
        // Validate title length (database constraint: 3-200 characters)
        let trimmedTitle = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.count >= 3 else {
            publishError = "Title must be at least 3 characters long"
            return
        }
        guard trimmedTitle.count <= 200 else {
            publishError = "Title must be no more than 200 characters long"
            return
        }
        
        isPublishing = true
        publishError = nil
        
        // Capture trimmedTitle for use in Task
        let finalTitle = trimmedTitle
        
        Task {
            // Ensure AuthManager is synced for repository operations
            if AuthManager.shared.currentUserId == nil {
                await AuthManager.shared.checkSession()
            }
            
            // Double-check AuthManager has user ID after sync
            guard AuthManager.shared.currentUserId != nil else {
                await MainActor.run {
                    isPublishing = false
                    publishError = "Unable to verify user identity. Please try again."
                }
                return
            }
            
            do {
                // Calculate expiry time
                let expiresAt = Calendar.current.date(byAdding: .minute, value: viewModel.expiryMinutes, to: Date())
                
                // Convert dietary tags to strings
                let dietaryStrings = viewModel.dietaryTags.map { $0.rawValue }
                
                // Convert UIImage to JPEG data
                let imageDataArray = viewModel.photos.compactMap { image -> Data? in
                    // Compress image to reasonable size (max 2MB per image)
                    return image.jpegData(compressionQuality: 0.8)
                }
                
                guard !imageDataArray.isEmpty else {
                    await MainActor.run {
                        publishError = "Please add at least one photo"
                        isPublishing = false
                    }
                    return
                }
                
                // Create the post request
                let request = CreatePostRequest(
                    title: finalTitle,  // Use trimmed title that passed validation
                    description: viewModel.description.isEmpty ? nil : viewModel.description,
                    imageDataArray: imageDataArray,
                    dietary: dietaryStrings,
                    perishability: viewModel.perishability,
                    quantityEstimate: viewModel.quantity,
                    expiresAt: expiresAt,
                    location: location,
                    buildingId: nil, // TODO: Get building ID from selected building
                    buildingName: viewModel.selectedBuilding,
                    pickupInstructions: viewModel.accessNotes.isEmpty ? nil : viewModel.accessNotes
                )
                
                // Create the post
                _ = try await repository.createPost(input: request)
                
                // Success!
                await MainActor.run {
                    FTHaptics.success()
                    isPublishing = false
                    showSuccessView = true
                }
            } catch {
                await MainActor.run {
                    isPublishing = false
                    // Use localized error description if available, otherwise fall back to description
                    if let networkError = error as? NetworkError {
                        publishError = networkError.errorDescription ?? networkError.localizedDescription
                    } else {
                        publishError = error.localizedDescription
                    }
                    print("❌ Failed to publish post: \(error)")
                }
            }
        }
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
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
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
                        }
                    }
                } else {
                    // Show selected photos
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.photos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: viewModel.photos[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                        
                        if viewModel.photos.count < 3 {
                            Button(action: {
                                showCamera = true
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
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(images: $viewModel.photos)
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
    
    func perishabilityDescription(_ level: FoodPost.Perishability) -> String {
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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchService = LocationSearchService()
    @State private var searchText = ""
    @State private var showResults = false
    @State private var isReverseGeocoding = false
    @State private var searchTask: Task<Void, Never>?
    @State private var hasInitializedLocation = false
    
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
                
                // Building search with dropdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Building")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                    
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            TextField("Search buildings", text: $searchText)
                                .font(.system(size: 17))
                                .padding(16)
                                .background(Color.bgElev2Card)
                                .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                        .strokeBorder(Color.strokeSoft, lineWidth: 1)
                                )
                                .onTapGesture {
                                    showResults = true
                                }
                                .onChange(of: searchText) { newValue in
                                    performSearch(query: newValue)
                                }
                            
                            // Dropdown results
                            if showResults && !searchText.isEmpty {
                                VStack(spacing: 0) {
                                    if searchService.isSearching {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Searching...")
                                                .font(.system(size: 15))
                                                .foregroundColor(.inkSecondary)
                                        }
                                        .padding(16)
                                        .background(Color.bgElev2Card)
                                    } else if searchService.searchResults.isEmpty && !searchText.isEmpty {
                                        Text("No results found")
                                            .font(.system(size: 15))
                                            .foregroundColor(.inkSecondary)
                                            .padding(16)
                                            .background(Color.bgElev2Card)
                                    } else {
                                        ForEach(Array(searchService.searchResults.prefix(5)), id: \.self) { mapItem in
                                            Button(action: {
                                                selectLocation(mapItem: mapItem)
                                            }) {
                                                HStack(spacing: 12) {
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.brandPrimary)
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(mapItem.name ?? "Unknown")
                                                            .font(.system(size: 16, weight: .medium))
                                                            .foregroundColor(.inkPrimary)
                                                        
                                                        if let address = mapItem.placemark.thoroughfare {
                                                            Text(address)
                                                                .font(.system(size: 14))
                                                                .foregroundColor(.inkSecondary)
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .padding(16)
                                                .background(
                                                    viewModel.selectedBuilding == mapItem.name ? 
                                                    Color.brandPrimary.opacity(0.1) : Color.bgElev2Card
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            if mapItem != searchService.searchResults.prefix(5).last {
                                                Divider()
                                                    .padding(.leading, 48)
                                            }
                                        }
                                    }
                                }
                                .background(Color.bgElev2Card)
                                .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                                        .strokeBorder(Color.strokeSoft, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                
                // Show loading state for reverse geocoding
                if isReverseGeocoding {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Getting your location...")
                            .font(.system(size: 15))
                            .foregroundColor(.inkSecondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Show selected location info
                if let building = viewModel.selectedBuilding, viewModel.location != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.brandPrimary)
                        Text(building)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.inkPrimary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.brandPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                }
                
                // Show error if location unavailable
                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Location access denied. Please enable location services in Settings.")
                            .font(.system(size: 14))
                            .foregroundColor(.inkSecondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
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
        .onAppear {
            if !hasInitializedLocation {
                initializeLocation()
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if newLocation != nil, !hasInitializedLocation {
                initializeLocation()
            }
        }
        .onTapGesture {
            // Dismiss dropdown when tapping outside
            showResults = false
        }
    }
    
    private func initializeLocation() {
        guard !hasInitializedLocation else { return }
        
        // Request location permission if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
            return
        }
        
        // Wait for location if not available yet
        guard let userLocation = locationManager.location else {
            // Start updating location
            locationManager.startUpdatingLocation()
            return
        }
        
        // Reverse geocode the location
        Task {
            await MainActor.run {
                isReverseGeocoding = true
            }
            
            do {
                if let address = try await locationManager.reverseGeocodeLocation(userLocation) {
                    await MainActor.run {
                        searchText = address
                        viewModel.selectedBuilding = address
                        viewModel.location = userLocation
                        hasInitializedLocation = true
                        isReverseGeocoding = false
                    }
                } else {
                    await MainActor.run {
                        isReverseGeocoding = false
                        hasInitializedLocation = true
                    }
                }
            } catch {
                await MainActor.run {
                    isReverseGeocoding = false
                    hasInitializedLocation = true
                    print("Reverse geocoding error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchService.cancelSearch()
            showResults = false
            return
        }
        
        // Get user location - if unavailable, don't search
        guard let searchLocation = locationManager.location else {
            searchService.cancelSearch()
            showResults = false
            return
        }
        
        showResults = true
        
        // Debounce search
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            if !Task.isCancelled {
                await searchService.search(query: query, near: searchLocation)
            }
        }
    }
    
    private func selectLocation(mapItem: MKMapItem) {
        guard let name = mapItem.name else { return }
        
        viewModel.selectedBuilding = name
        viewModel.location = mapItem.placemark.coordinate
        searchText = name
        showResults = false
        
        FTHaptics.light()
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
                    // Image preview
                    if let firstImage = viewModel.photos.first {
                        Image(uiImage: firstImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                            .overlay(
                                Group {
                                    if viewModel.photos.count > 1 {
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Text("+\(viewModel.photos.count - 1) more")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(8)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .padding(12)
                                            }
                                        }
                                    }
                                }
                            )
                    } else {
                        Rectangle()
                            .fill(Color.brandPrimary.opacity(0.1))
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.brandPrimary.opacity(0.3))
                                    Text("No photos")
                                        .font(.system(size: 14))
                                        .foregroundColor(.inkMuted)
                                }
                            )
                    }
                    
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
    @Published var photos: [UIImage] = []
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
        case 2: 
            // Title must be 3-200 characters (database constraint)
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedTitle.count >= 3 && trimmedTitle.count <= 200
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

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                if parent.images.count < 3 {
                    parent.images.append(image)
                }
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

