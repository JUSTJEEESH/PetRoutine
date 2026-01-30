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
        case .owner: "Full control"
        case .caregiver: "Complete tasks, add logs"
        case .viewer: "Read-only access"
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
        return expiresAt < Date()
    }
}

struct Household: Identifiable {
    let id: UUID
    var name: String
    var caregivers: [Caregiver]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "My Household",
        caregivers: [Caregiver] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.caregivers = caregivers
        self.createdAt = createdAt
    }
}
