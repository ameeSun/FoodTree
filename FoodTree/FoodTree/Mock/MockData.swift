//
//  MockData.swift
//  FoodTree
//
//  Realistic Stanford campus demo data
//

import Foundation
import CoreLocation

struct MockData {
    // Stanford campus center
    static let stanfordCenter = CLLocationCoordinate2D(latitude: 37.4275, longitude: -122.1697)
    
    // MARK: - Sample Organizers
    static let organizers = [
        Organizer(id: "1", name: "Stanford CS Club", verified: true, avatarUrl: nil),
        Organizer(id: "2", name: "EVGR Events", verified: true, avatarUrl: nil),
        Organizer(id: "3", name: "Tresidder Union", verified: true, avatarUrl: nil),
        Organizer(id: "4", name: "Gates Hall", verified: true, avatarUrl: nil),
        Organizer(id: "5", name: "Old Union", verified: true, avatarUrl: nil),
        Organizer(id: "6", name: "Fraternity Row", verified: false, avatarUrl: nil),
        Organizer(id: "7", name: "Y2E2 Study Group", verified: false, avatarUrl: nil),
    ]
    
    // MARK: - Stanford Buildings
    static let buildings = [
        StanfordBuilding(name: "Huang Engineering Center", lat: 37.4275, lng: -122.1770),
        StanfordBuilding(name: "Gates Computer Science", lat: 37.4300, lng: -122.1730),
        StanfordBuilding(name: "Old Union", lat: 37.4265, lng: -122.1698),
        StanfordBuilding(name: "Tresidder Union", lat: 37.4255, lng: -122.1691),
        StanfordBuilding(name: "EVGR C Courtyard", lat: 37.4290, lng: -122.1750),
        StanfordBuilding(name: "Memorial Court", lat: 37.4270, lng: -122.1680),
        StanfordBuilding(name: "Y2E2", lat: 37.4268, lng: -122.1735),
        StanfordBuilding(name: "Fraternity Row", lat: 37.4310, lng: -122.1665),
    ]
    
    // MARK: - Sample Posts
    static func generatePosts() -> [FoodPost] {
        let now = Date()
        
        return [
            FoodPost(
                id: "1",
                title: "Leftover Burrito Bowls",
                description: "Chicken and veggie burrito bowls from our CS Club meeting. Still warm!",
                images: ["burrito_bowls"],
                createdAt: now.addingTimeInterval(-360), // 6 min ago
                expiresAt: now.addingTimeInterval(2400), // 40 min from now
                perishability: .high,
                dietary: [.glutenFree, .dairyFree],
                quantityApprox: 35,
                status: .available,
                location: PostLocation(
                    lat: 37.4275,
                    lng: -122.1770,
                    building: "Huang Engineering Center",
                    notes: "Third floor lounge, near the elevators"
                ),
                organizer: organizers[0],
                metrics: PostMetrics(views: 42, onMyWay: 8, saves: 12)
            ),
            
            FoodPost(
                id: "2",
                title: "Veggie Sushi Platters",
                description: "Assorted veggie sushi from recruiting event. All vegetarian.",
                images: ["sushi"],
                createdAt: now.addingTimeInterval(-900), // 15 min ago
                expiresAt: now.addingTimeInterval(1800), // 30 min from now
                perishability: .high,
                dietary: [.vegetarian, .dairyFree],
                quantityApprox: 25,
                status: .available,
                location: PostLocation(
                    lat: 37.4300,
                    lng: -122.1730,
                    building: "Gates Computer Science",
                    notes: "First floor commons"
                ),
                organizer: organizers[3],
                metrics: PostMetrics(views: 67, onMyWay: 15, saves: 23)
            ),
            
            FoodPost(
                id: "3",
                title: "Pizza Slices",
                description: "Cheese and veggie pizza from study session.",
                images: ["pizza"],
                createdAt: now.addingTimeInterval(-1800), // 30 min ago
                expiresAt: now.addingTimeInterval(3600), // 60 min from now
                perishability: .medium,
                dietary: [.vegetarian],
                quantityApprox: 12,
                status: .low,
                location: PostLocation(
                    lat: 37.4265,
                    lng: -122.1698,
                    building: "Old Union",
                    notes: "Second floor lounge"
                ),
                organizer: organizers[4],
                metrics: PostMetrics(views: 89, onMyWay: 7, saves: 18)
            ),
            
            FoodPost(
                id: "4",
                title: "Mediterranean Plates",
                description: "Falafel, hummus, pita, and salads. All halal and vegan options available.",
                images: ["mediterranean"],
                createdAt: now.addingTimeInterval(-600), // 10 min ago
                expiresAt: now.addingTimeInterval(2700), // 45 min from now
                perishability: .medium,
                dietary: [.vegan, .halal, .vegetarian, .glutenFree],
                quantityApprox: 40,
                status: .available,
                location: PostLocation(
                    lat: 37.4290,
                    lng: -122.1750,
                    building: "EVGR C Courtyard",
                    notes: "Outdoor tables near C wing entrance"
                ),
                organizer: organizers[1],
                metrics: PostMetrics(views: 55, onMyWay: 12, saves: 19)
            ),
            
            FoodPost(
                id: "5",
                title: "Cookies & Milk",
                description: "Freshly baked chocolate chip and oatmeal cookies with cold milk.",
                images: ["cookies"],
                createdAt: now.addingTimeInterval(-300), // 5 min ago
                expiresAt: now.addingTimeInterval(5400), // 90 min from now
                perishability: .low,
                dietary: [.vegetarian, .containsNuts],
                quantityApprox: 60,
                status: .available,
                location: PostLocation(
                    lat: 37.4255,
                    lng: -122.1691,
                    building: "Tresidder Union",
                    notes: "Main lobby, near Starbucks"
                ),
                organizer: organizers[2],
                metrics: PostMetrics(views: 38, onMyWay: 9, saves: 14)
            ),
            
            FoodPost(
                id: "6",
                title: "Paneer Tikka & Rice",
                description: "Indian vegetarian feast with paneer tikka, rice, and naan.",
                images: ["indian"],
                createdAt: now.addingTimeInterval(-1200), // 20 min ago
                expiresAt: now.addingTimeInterval(1200), // 20 min from now
                perishability: .high,
                dietary: [.vegetarian, .halal],
                quantityApprox: 18,
                status: .low,
                location: PostLocation(
                    lat: 37.4268,
                    lng: -122.1735,
                    building: "Y2E2",
                    notes: "Ground floor atrium"
                ),
                organizer: organizers[6],
                metrics: PostMetrics(views: 72, onMyWay: 11, saves: 9)
            ),
            
            FoodPost(
                id: "7",
                title: "Bagels & Cream Cheese",
                description: "Assorted bagels with cream cheese and spreads.",
                images: ["bagels"],
                createdAt: now.addingTimeInterval(-2400), // 40 min ago
                expiresAt: now.addingTimeInterval(1800), // 30 min from now
                perishability: .low,
                dietary: [.vegetarian],
                quantityApprox: 30,
                status: .available,
                location: PostLocation(
                    lat: 37.4270,
                    lng: -122.1680,
                    building: "Memorial Court",
                    notes: "Near the fountain"
                ),
                organizer: organizers[4],
                metrics: PostMetrics(views: 45, onMyWay: 6, saves: 11)
            ),
            
            FoodPost(
                id: "8",
                title: "Fruit & Cheese Platter",
                description: "Fresh fruit, cheese cubes, and crackers.",
                images: ["fruit_cheese"],
                createdAt: now.addingTimeInterval(-180), // 3 min ago
                expiresAt: now.addingTimeInterval(3600), // 60 min from now
                perishability: .medium,
                dietary: [.vegetarian, .glutenFree],
                quantityApprox: 45,
                status: .available,
                location: PostLocation(
                    lat: 37.4310,
                    lng: -122.1665,
                    building: "Fraternity Row",
                    notes: "Sigma Chi house, front porch"
                ),
                organizer: organizers[5],
                metrics: PostMetrics(views: 28, onMyWay: 5, saves: 7)
            ),
        ]
    }
    
    // MARK: - Sample Notifications
    static func generateNotifications() -> [AppNotification] {
        let now = Date()
        return [
            AppNotification(
                id: UUID().uuidString,
                title: "New post near Huang",
                body: "Leftover Burrito Bowls • 7 min left",
                timestamp: now.addingTimeInterval(-120),
                type: .newPost
            ),
            AppNotification(
                id: UUID().uuidString,
                title: "Running low!",
                body: "Pizza Slices at Old Union is almost gone",
                timestamp: now.addingTimeInterval(-600),
                type: .runningLow,
                read: true
            ),
            AppNotification(
                id: UUID().uuidString,
                title: "You're close!",
                body: "Mediterranean Plates at EVGR C is 150m away and expiring soon",
                timestamp: now.addingTimeInterval(-300),
                type: .nearby
            ),
        ]
    }
}

struct StanfordBuilding: Identifiable {
    let id = UUID()
    let name: String
    let lat: Double
    let lng: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

