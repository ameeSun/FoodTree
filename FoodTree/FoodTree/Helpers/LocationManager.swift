//
//  LocationManager.swift
//  TreeBites
//
//  Location services manager
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private var locationTimeoutTask: Task<Void, Never>?
    private let locationTimeoutSeconds: TimeInterval = 10.0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        // Request permission if not determined
        if authorizationStatus == .notDetermined {
            requestLocationPermission()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
        
        // Set up timeout fallback
        startLocationTimeout()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    private func startLocationTimeout() {
        locationTimeoutTask?.cancel()
        locationTimeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(locationTimeoutSeconds * 1_000_000_000))
            
            // If still no location after timeout, use fallback
            if await location == nil && authorizationStatus != .denied && authorizationStatus != .restricted {
                await MainActor.run {
                    // Only use fallback if we haven't gotten a location yet
                    if self.location == nil {
                        self.location = MockData.stanfordCenter
                        self.errorMessage = "Using default location. Enable location services for accurate results."
                    }
                }
            }
        }
    }
    
    func distanceInMiles(from coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = location else { return nil }
        
        let current = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let distanceInMeters = current.distance(from: target)
        return distanceInMeters / 1609.34 // Convert to miles
    }
    
    func walkingTime(to coordinate: CLLocationCoordinate2D) -> Int? {
        guard let distance = distanceInMiles(from: coordinate) else { return nil }
        
        // Average walking speed: 3 mph
        let hours = distance / 3.0
        return Int(hours * 60) // Convert to minutes
    }
    
    /// Reverse geocode a coordinate to get address/place name
    func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D) async throws -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            return nil
        }
        
        // Prefer place name, then thoroughfare, then formatted address
        if let name = placemark.name, !name.isEmpty {
            return name
        } else if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
            return thoroughfare
        } else if let locality = placemark.locality, !locality.isEmpty {
            return locality
        } else {
            return "Unknown Location"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Cancel timeout since we got a location
        locationTimeoutTask?.cancel()
        
        self.location = location.coordinate
        self.errorMessage = nil
        
        // Stop updating to save battery (we got what we need)
        stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            // Use fallback location when permission denied
            location = MockData.stanfordCenter
            errorMessage = "Location access denied. Using default location."
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        
        // Only use fallback if we don't have a location yet
        if location == nil {
            location = MockData.stanfordCenter
            errorMessage = "Unable to get your location. Using default location."
        }
    }
}

