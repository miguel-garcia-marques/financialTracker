import Foundation
import SwiftData

enum PaymentSource: String, Codable, CaseIterable, Identifiable {
    case applePayShortcut = "apple_pay_shortcut"
    case manual
    case bankImport = "bank_import"
    case receiptMatch = "receipt_match"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .applePayShortcut: "Apple Pay"
        case .manual: "Manual"
        case .bankImport: "Importacao bancaria"
        case .receiptMatch: "Associacao fatura"
        }
    }
}

enum PaymentStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case pendingEnrichment = "pending_enrichment"
    case needsReconciliation = "needs_reconciliation"
    case complete
    case ignored
    case duplicate
    case discarded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .pendingEnrichment: "Pendente"
        case .needsReconciliation: "Revisao"
        case .complete: "Completo"
        case .ignored: "Ignorado"
        case .duplicate: "Duplicado"
        case .discarded: "Descartado"
        }
    }
}

@Model
final class Payment {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var transactionAt: Date
    var sourceRawValue: String
    var sourceConfidence: Decimal
    var statusRawValue: String
    var confirmedAt: Date?
    var discardedAt: Date?
    var amount: Decimal?
    var currency: String
    var merchantName: String?
    var merchantNormalized: String?
    var transactionName: String?
    var bankName: String?
    var locationLat: Decimal?
    var locationLon: Decimal?
    var locationLabel: String?
    var notes: String
    var structuredNotesData: Data
    var rawPayloadData: Data
    var duplicateGroupID: UUID?
    var reviewRequired: Bool

    @Relationship var bank: Bank?
    @Relationship var paymentMethod: PaymentMethod?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        transactionAt: Date = .now,
        source: PaymentSource,
        sourceConfidence: Decimal = 1,
        status: PaymentStatus,
        confirmedAt: Date? = nil,
        discardedAt: Date? = nil,
        amount: Decimal? = nil,
        currency: String = "EUR",
        merchantName: String? = nil,
        merchantNormalized: String? = nil,
        transactionName: String? = nil,
        bankName: String? = nil,
        locationLat: Decimal? = nil,
        locationLon: Decimal? = nil,
        locationLabel: String? = nil,
        notes: String = "",
        structuredNotesData: Data = Data("{}".utf8),
        rawPayloadData: Data = Data("{}".utf8),
        duplicateGroupID: UUID? = nil,
        reviewRequired: Bool = false,
        bank: Bank? = nil,
        paymentMethod: PaymentMethod? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.transactionAt = transactionAt
        self.sourceRawValue = source.rawValue
        self.sourceConfidence = sourceConfidence
        self.statusRawValue = status.rawValue
        self.confirmedAt = confirmedAt
        self.discardedAt = discardedAt
        self.amount = amount
        self.currency = currency
        self.merchantName = merchantName
        self.merchantNormalized = merchantNormalized
        self.transactionName = transactionName
        self.bankName = bankName
        self.locationLat = locationLat
        self.locationLon = locationLon
        self.locationLabel = locationLabel
        self.notes = notes
        self.structuredNotesData = structuredNotesData
        self.rawPayloadData = rawPayloadData
        self.duplicateGroupID = duplicateGroupID
        self.reviewRequired = reviewRequired
        self.bank = bank
        self.paymentMethod = paymentMethod
    }

    var source: PaymentSource {
        get { PaymentSource(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }

    var status: PaymentStatus {
        get { PaymentStatus(rawValue: statusRawValue) ?? .needsReconciliation }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = .now
            if newValue == .complete || newValue == .pendingEnrichment || newValue == .needsReconciliation {
                confirmedAt = confirmedAt ?? .now
            }
            if newValue == .discarded {
                discardedAt = discardedAt ?? .now
            }
        }
    }

    var isIncludedInFinancialTotals: Bool {
        status != .discarded && status != .ignored && status != .duplicate
    }
}
