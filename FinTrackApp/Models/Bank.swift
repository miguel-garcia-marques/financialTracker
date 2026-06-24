import Foundation
import SwiftData

@Model
final class Bank {
    @Attribute(.unique) var id: UUID
    var name: String
    var displayName: String
    var country: String
    var aliasesData: Data
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        displayName: String? = nil,
        country: String = "PT",
        aliases: [String] = [],
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.country = country
        self.aliasesData = (try? JSONEncoder().encode(aliases)) ?? Data("[]".utf8)
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var aliases: [String] {
        get { (try? JSONDecoder().decode([String].self, from: aliasesData)) ?? [] }
        set {
            aliasesData = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8)
            updatedAt = .now
        }
    }
}
