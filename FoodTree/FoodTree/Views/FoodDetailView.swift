//
//  FoodDetailView.swift
//  FoodTree
//
//  Full-screen food detail with hero gallery and actions
//

import SwiftUI
import MapKit

struct FoodDetailView: View {
    let post: FoodPost
    @Binding var isPresented: Bool
    @State private var selectedImageIndex = 0
    @State private var showReportSheet = false
    @State private var showNavigationOptions = false
    @State private var isOnMyWay = false
    @State private var showSuccessConfetti = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image gallery
                    HeroGallery(images: post.images, selectedIndex: $selectedImageIndex)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        // Status and meta
                        HStack {
                            StatusPill(status: post.status, animated: post.status == .available)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 13))
                                Text(timeAgoText)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.inkSecondary)
                        }
                        
                        // Title
                        Text(post.title)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.inkPrimary)
                        
                        // Description
                        if let description = post.description {
                            Text(description)
                                .font(.system(size: 16))
                                .foregroundColor(.inkSecondary)
                                .lineSpacing(4)
                        }
                        
                        Divider()
                        
                        // Dietary badges
                        if !post.dietary.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Dietary information")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.inkSecondary)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(post.dietary) { tag in
                                        DietaryChip(tag: tag)
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        // Quantity and perishability
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Portions")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.inkMuted)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 18))
                                    Text("~\(post.quantityApprox)")
                                        .font(.system(size: 20, weight: .bold))
                                }
                                .foregroundColor(.inkPrimary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("Time left")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.inkMuted)
                                
                                if let timeRemaining = post.timeRemaining {
                                    HStack(spacing: 6) {
                                        Text("\(timeRemaining) min")
                                            .font(.system(size: 20, weight: .bold))
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 18))
                                    }
                                    .foregroundColor(timeRemaining < 15 ? .stateError : .inkPrimary)
                                }
                            }
                        }
                        
                        PerishabilityBadge(perishability: post.perishability, showAnimation: true)
                        
                        Divider()
                        
                        // Live status bar
                        LiveStatusBar(post: post)
                        
                        Divider()
                        
                        // Interest counter
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 14))
                                Text("\(post.metrics.views)")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 14))
                                Text("\(post.metrics.onMyWay) on the way")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 14))
                                Text("\(post.metrics.saves)")
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }
                        .foregroundColor(.inkSecondary)
                        
                        Divider()
                        
                        // Location
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pickup location")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                            
                            if let building = post.location.building {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.brandPrimary)
                                    
                                    Text(building)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.inkPrimary)
                                }
                            }
                            
                            if let notes = post.location.notes {
                                Text(notes)
                                    .font(.system(size: 15))
                                    .foregroundColor(.inkSecondary)
                                    .padding(.leading, 28)
                            }
                            
                            // Mini map
                            Map(coordinateRegion: .constant(MKCoordinateRegion(
                                center: post.location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                            )), annotationItems: [FoodPostAnnotation(post: post)]) { annotation in
                                MapMarker(coordinate: annotation.coordinate, tint: .brandPrimary)
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
                            .allowsHitTesting(false)
                        }
                        
                        Divider()
                        
                        // Organizer info
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(post.organizer.name.prefix(1)))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.brandPrimary)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(post.organizer.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.inkPrimary)
                                    
                                    if post.organizer.verified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                                
                                Text("Organizer")
                                    .font(.system(size: 14))
                                    .foregroundColor(.inkMuted)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(FTLayout.paddingM)
                    .padding(.bottom, 120)
                }
            }
            .background(Color.bgElev1)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.inkMuted)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            sharePost()
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            savePost()
                        }) {
                            Label("Save", systemImage: "bookmark")
                        }
                        
                        Button(role: .destructive, action: {
                            showReportSheet = true
                        }) {
                            Label("Report", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.inkMuted)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                // Action buttons
                VStack(spacing: 12) {
                    if isOnMyWay {
                        // Success message
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("You're marked as on your way!")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.stateSuccess)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.stateSuccess.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 12) {
                        // Navigate button
                        Button(action: {
                            showNavigationOptions = true
                            FTHaptics.light()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    .font(.system(size: 20))
                                Text("Navigate")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.brandPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                        }
                        
                        // On My Way button
                        Button(action: {
                            toggleOnMyWay()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isOnMyWay ? "checkmark.circle.fill" : "figure.walk.circle.fill")
                                    .font(.system(size: 20))
                                Text(isOnMyWay ? "On My Way!" : "On My Way")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isOnMyWay ? Color.stateSuccess : Color.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                        }
                    }
                }
                .padding(FTLayout.paddingM)
                .background(
                    Color.bgElev2Card
                        .ignoresSafeArea()
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                )
            }
            .confirmationDialog("Navigate to pickup", isPresented: $showNavigationOptions) {
                Button("Open in Apple Maps") {
                    // Open Apple Maps (stub)
                    FTHaptics.light()
                }
                
                Button("Open in Google Maps") {
                    // Open Google Maps (stub)
                    FTHaptics.light()
                }
                
                Button("Copy address") {
                    // Copy to clipboard (stub)
                    FTHaptics.light()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showReportSheet) {
                ReportView(postId: post.id, isPresented: $showReportSheet)
            }
        }
    }
    
    private var timeAgoText: String {
        let seconds = Date().timeIntervalSince(post.createdAt)
        let minutes = Int(seconds / 60)
        
        if minutes < 1 {
            return "Just now"
        } else if minutes == 1 {
            return "1 min ago"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
    
    private func toggleOnMyWay() {
        isOnMyWay.toggle()
        if isOnMyWay {
            FTHaptics.success()
            showSuccessConfetti = true
        } else {
            FTHaptics.light()
        }
    }
    
    private func sharePost() {
        FTHaptics.light()
        // Share sheet (stub)
    }
    
    private func savePost() {
        FTHaptics.medium()
        // Save post (stub)
    }
}

// MARK: - Food Detail Content (reusable without nav wrapper)
struct FoodDetailContent: View {
    let post: FoodPost
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    if !post.dietary.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(post.dietary.prefix(4)) { tag in
                                    DietaryChip(tag: tag, size: .small)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                StatusPill(status: post.status)
            }
            
            // Quick meta
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                    Text("\(post.quantityApprox)")
                        .font(.system(size: 14, weight: .medium))
                }
                
                if let timeRemaining = post.timeRemaining {
                    Text("•")
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("\(timeRemaining) min")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(timeRemaining < 15 ? .stateError : .inkSecondary)
                }
                
                if let userLocation = userLocation {
                    Text("•")
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text(String(format: "%.1f mi", post.location.distance(from: userLocation)))
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .foregroundColor(.inkSecondary)
            
            // Organizer
            HStack(spacing: 8) {
                if post.organizer.verified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.brandPrimary)
                }
                
                Text(post.organizer.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.inkSecondary)
            }
        }
        .padding(FTLayout.paddingM)
    }
}

// MARK: - Hero Gallery
struct HeroGallery: View {
    let images: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(images.indices, id: \.self) { index in
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .clipped()
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 320)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// MARK: - Live Status Bar
struct LiveStatusBar: View {
    let post: FoodPost
    
    private var progress: Double {
        Double(post.quantityApprox) / 100.0
    }
    
    private var barColor: Color {
        if post.quantityApprox >= 50 {
            return .mapPoiAvailable
        } else if post.quantityApprox >= 20 {
            return .mapPoiLow
        } else {
            return .mapPoiOut
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live availability")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.inkMuted)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.strokeSoft)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(FTAnimation.spring, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Report View
struct ReportView: View {
    let postId: String
    @Binding var isPresented: Bool
    @State private var selectedReason: ReportReason?
    @State private var additionalInfo = ""
    
    enum ReportReason: String, CaseIterable {
        case spam = "Spam or misleading"
        case unsafe = "Food safety concern"
        case wrongLocation = "Wrong location"
        case inappropriate = "Inappropriate content"
        case other = "Other"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                            FTHaptics.light()
                        }) {
                            HStack {
                                Text(reason.rawValue)
                                    .foregroundColor(.inkPrimary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Reason")
                }
                
                Section {
                    TextField("Additional details (optional)", text: $additionalInfo, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Details")
                }
            }
            .navigationTitle("Report Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(selectedReason == nil)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func submitReport() {
        FTHaptics.warning()
        // Submit report (stub)
        isPresented = false
    }
}

