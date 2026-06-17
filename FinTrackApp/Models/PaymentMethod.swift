import Foundation
import SwiftData

enum PaymentMethodType: String, Codable, CaseIterable, Identifiable {
    case applePayCard = "apple_pay_card"
    case bankCard = "bank_card"
    case cash
    case other

    var id: String { rawValue }
}

@Model
final class PaymentMethod {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var typeRawValue: String
    var last4: String?
    var issuer: String?
    var shortcutCardLabel: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship var bank: Bank?

    init(
        id: UUID = UUID(),
        displayName: String,
        type: PaymentMethodType = .applePayCard,
        last4: String? = nil,
        issuer: String? = nil,
        shortcutCardLabel: String? = nil,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        bank: Bank? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.typeRawValue = type.rawValue
        self.last4 = last4
        self.issuer = issuer
        self.shortcutCardLabel = shortcutCardLabel
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bank = bank
    }

    var type: PaymentMethodType {
        get { PaymentMethodType(rawValue: typeRawValue) ?? .other }
        set {
            typeRawValue = newValue.rawValue
            updatedAt = .now
        }
    }
}
