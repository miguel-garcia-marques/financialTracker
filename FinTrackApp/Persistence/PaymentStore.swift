import Foundation
import SwiftData

@MainActor
final class PaymentStore {
    static let shared = PaymentStore()

    private let container: ModelContainer

    init(container: ModelContainer = FinTrackModelContainer.shared) {
        self.container = container
    }

    var context: ModelContext {
        ModelContext(container)
    }

    func create(_ payment: Payment) throws {
        let context = context
        context.insert(payment)
        try context.save()
    }

    func payments(includeDiscarded: Bool = false) throws -> [Payment] {
        let descriptor = FetchDescriptor<Payment>(
            sortBy: [SortDescriptor(\.transactionAt, order: .reverse)]
        )
        let payments = try context.fetch(descriptor)
        guard !includeDiscarded else { return payments }
        return payments.filter(\.isIncludedInFinancialTotals)
    }

    func payment(id: UUID) throws -> Payment? {
        let descriptor = FetchDescriptor<Payment>(
            predicate: #Predicate { payment in
                payment.id == id
            }
        )
        return try context.fetch(descriptor).first
    }

    func banks(includeInactive: Bool = false) throws -> [Bank] {
        let descriptor = FetchDescriptor<Bank>(
            sortBy: [SortDescriptor(\.displayName)]
        )
        let banks = try context.fetch(descriptor)
        return includeInactive ? banks : banks.filter(\.isActive)
    }

    func paymentMethods(includeInactive: Bool = false) throws -> [PaymentMethod] {
        let descriptor = FetchDescriptor<PaymentMethod>(
            sortBy: [SortDescriptor(\.displayName)]
        )
        let methods = try context.fetch(descriptor)
        return includeInactive ? methods : methods.filter(\.isActive)
    }

    func paymentMethod(shortcutCardLabel: String) throws -> PaymentMethod? {
        try paymentMethods().first { method in
            method.matches(shortcutCardLabel: shortcutCardLabel)
        }
    }

    func bank(matching value: String) throws -> Bank? {
        try banks().first { bank in
            bank.matches(value)
        }
    }

    func update(_ payment: Payment, mutate: (Payment) -> Void) throws {
        mutate(payment)
        payment.touch()
        try context.save()
    }

    func delete(_ payment: Payment) throws {
        let context = context
        context.delete(payment)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}

enum PaymentDraftFactory {
    static func applePayShortcutDraft(
        transaction: String?,
        cardOrPass: String?,
        merchant: String?,
        amount: String?,
        name: String?,
        triggeredAt: Date = .now
    ) -> Payment {
        let normalizedAmount = AmountParser.parse(amount)
        let merchantName = merchant?.trimmedNilIfEmpty
        let transactionName = name?.trimmedNilIfEmpty
        let rawPayload: [String: String] = [
            "transaction": transaction,
            "card_or_pass": cardOrPass,
            "merchant": merchant,
            "amount": amount,
            "name": name,
            "triggered_at": ISO8601DateFormatter().string(from: triggeredAt)
        ].compactMapValues { $0 }

        return Payment(
            transactionAt: triggeredAt,
            source: .applePayShortcut,
            status: .draft,
            amount: normalizedAmount.value,
            currency: normalizedAmount.currency,
            merchantName: merchantName,
            merchantNormalized: merchantName?.normalizedMerchantName,
            transactionName: transactionName,
            bankName: nil,
            notes: "",
            rawPayloadData: (try? JSONEncoder().encode(rawPayload)) ?? Data("{}".utf8),
            reviewRequired: normalizedAmount.value == nil || merchantName == nil,
            paymentMethod: nil
        )
    }
}

enum AmountParser {
    static func parse(_ input: String?) -> (value: Decimal?, currency: String) {
        guard let input else { return (nil, "EUR") }

        let currency = if input.contains("€") {
            "EUR"
        } else if input.localizedCaseInsensitiveContains("USD") || input.contains("$") {
            "USD"
        } else if input.localizedCaseInsensitiveContains("GBP") || input.contains("£") {
            "GBP"
        } else {
            "EUR"
        }

        let numericText = input
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "EUR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "USD", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "GBP", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")

        return (Decimal(string: numericText, locale: Locale(identifier: "en_US_POSIX")), currency)
    }
}

extension String {
    var trimmedNilIfEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedMerchantName: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
}
