//
//  BlockedOrganizerStore.swift
//  TreeBites
//
//  Lightweight persistence for blocked organizer IDs
//

import Foundation

struct BlockedOrganizer: Identifiable, Codable, Equatable {
    let id: String
    let name: String
}

struct BlockedOrganizerStore {
    static let updatedNotification = Notification.Name("blockedOrganizersUpdated")
    
    private static let storageKey = "blockedOrganizers"
    private static let legacyStorageKey = "blockedOrganizerIds"
    
    static func load() -> [BlockedOrganizer] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let organizers = try? JSONDecoder().decode([BlockedOrganizer].self, from: data) {
            return organizers
        }
        
        let legacyIds = UserDefaults.standard.stringArray(forKey: legacyStorageKey) ?? []
        return legacyIds.map { BlockedOrganizer(id: $0, name: "Blocked user") }
    }
    
    static func loadIds() -> Set<String> {
        Set(load().map(\.id))
    }
    
    static func save(_ organizers: [BlockedOrganizer]) {
        if let data = try? JSONEncoder().encode(organizers) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        NotificationCenter.default.post(name: updatedNotification, object: nil)
    }
    
    static func add(organizer: Organizer) {
        var organizers = load()
        guard !organizers.contains(where: { $0.id == organizer.id }) else { return }
        organizers.append(BlockedOrganizer(id: organizer.id, name: organizer.name))
        save(organizers)
    }
    
    static func remove(id: String) {
        var organizers = load()
        organizers.removeAll { $0.id == id }
        save(organizers)
    }
}
