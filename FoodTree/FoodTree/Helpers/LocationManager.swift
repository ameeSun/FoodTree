//
//  LocationManager.swift
//  FoodTree
//
//  Location services manager (stub implementation)
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Mock Stanford location for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.location = MockData.stanfordCenter
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
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
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location.coordinate
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        // Fallback to Stanford center
        self.location = MockData.stanfordCenter
    }
}

