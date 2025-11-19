//
//  OnboardingView.swift
//  FoodTree
//
//  Onboarding flow with permissions requests
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var showPermissions = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "leaf.circle.fill",
            title: "Welcome to FoodTree 🌳",
            description: "Discover free food on campus and help reduce waste",
            color: .brandPrimary
        ),
        OnboardingPage(
            icon: "map.fill",
            title: "Find",
            description: "See what's available nearby in real-time on the map",
            color: .brandPrimary
        ),
        OnboardingPage(
            icon: "figure.walk",
            title: "Walk",
            description: "Head to the pickup location before it's gone",
            color: .brandPrimary
        ),
        OnboardingPage(
            icon: "fork.knife.circle.fill",
            title: "Enjoy",
            description: "Grab your food and make new friends!",
            color: .brandPrimary
        )
    ]
    
    var body: some View {
        ZStack {
            Color.bgElev1.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        showPermissions = true
                        FTHaptics.light()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.inkSecondary)
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                    .padding(.top, 60)
                }
                
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Continue button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                        FTHaptics.light()
                    } else {
                        showPermissions = true
                        FTHaptics.medium()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                        .ftShadow()
                }
                .padding(.horizontal, FTLayout.paddingL)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showPermissions) {
            PermissionsView()
        }
    }
}

// MARK: - Onboarding Page
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with orchard illustration
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                
                Circle()
                    .fill(page.color.opacity(0.05))
                    .frame(width: 280, height: 280)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundColor(page.color)
                    .scaleEffect(isAnimating ? 1.0 : 0.7)
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: isAnimating)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.inkPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text(page.description)
                    .font(.system(size: 18))
                    .foregroundColor(.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
            .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    
    let permissions: [Permission] = [
        Permission(
            icon: "location.circle.fill",
            title: "Enable Location",
            description: "See food posts near you and get walking directions",
            required: true
        ),
        Permission(
            icon: "bell.badge.fill",
            title: "Allow Notifications",
            description: "Get alerts when free food appears nearby",
            required: false
        )
    ]
    
    var body: some View {
        ZStack {
            Color.bgElev1.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: permissions[currentStep].icon)
                        .font(.system(size: 56))
                        .foregroundColor(.brandPrimary)
                }
                
                // Content
                VStack(spacing: 16) {
                    Text(permissions[currentStep].title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.inkPrimary)
                    
                    Text(permissions[currentStep].description)
                        .font(.system(size: 17))
                        .foregroundColor(.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        grantPermission()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.brandPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                            .ftShadow()
                    }
                    
                    if !permissions[currentStep].required {
                        Button(action: {
                            skipPermission()
                        }) {
                            Text("Skip for now")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.inkSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                }
                .padding(.horizontal, FTLayout.paddingL)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func grantPermission() {
        FTHaptics.medium()
        
        if currentStep == 0 {
            // Request location permission
            LocationManager.shared.requestLocationPermission()
            // Check authorization status
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let status = LocationManager.shared.authorizationStatus
                appState.hasLocationPermission = (status == .authorizedWhenInUse || status == .authorizedAlways)
                nextStep()
            }
        } else {
            // Request notification permission
            NotificationManager.shared.requestAuthorization()
            // Check authorization status
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let status = NotificationManager.shared.authorizationStatus
                appState.hasNotificationPermission = (status == .authorized)
                nextStep()
            }
        }
    }
    
    private func skipPermission() {
        FTHaptics.light()
        nextStep()
    }
    
    private func nextStep() {
        if currentStep < permissions.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            appState.completeOnboarding()
        }
    }
}

struct Permission {
    let icon: String
    let title: String
    let description: String
    let required: Bool
}

