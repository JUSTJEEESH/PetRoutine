import Foundation

enum CaregiverRole: String, CaseIterable, Identifiable, Codable {
    case owner
    case caregiver
    case viewer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .owner: "Owner"
        case .caregiver: "Caregiver"
        case .viewer: "Viewer"
        }
    }

    var description: String {
        switch self {
        case .owner: "Full control over pets, tasks, and household"
        case .caregiver: "Complete tasks and add logs"
        case .viewer: "View-only access"
        }
    }
}

struct Caregiver: Identifiable, Hashable {
    let id: UUID
    var name: String
    var role: CaregiverRole
    var isTemporary: Bool
    var expiresAt: Date?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        role: CaregiverRole = .caregiver,
        isTemporary: Bool = false,
        expiresAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.isTemporary = isTemporary
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    var isExpired: Bool {
        guard isTemporary, let expiresAt else { return false }
        return Date() > expiresAt
    }
}

struct Household: Identifiable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "My Household",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
