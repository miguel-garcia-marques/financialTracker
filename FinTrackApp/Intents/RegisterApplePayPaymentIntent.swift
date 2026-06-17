import AppIntents
import Foundation

struct RegisterApplePayPaymentIntent: AppIntent {
    static let title: LocalizedStringResource = "Registar Pagamento Apple Pay"
    static let description = IntentDescription("Cria um draft local a partir de uma automacao Transaction do Apple Shortcuts.")
    static let openAppWhenRun = true

    @Parameter(title: "Transacao")
    var transaction: String?

    @Parameter(title: "Cartao ou passe")
    var cardOrPass: String?

    @Parameter(title: "Comerciante")
    var merchant: String?

    @Parameter(title: "Quantia")
    var amount: String?

    @Parameter(title: "Nome")
    var name: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let payment = PaymentDraftFactory.applePayShortcutDraft(
            transaction: transaction,
            cardOrPass: cardOrPass,
            merchant: merchant,
            amount: amount,
            name: name
        )

        try PaymentStore.shared.create(payment)

        let merchantText = payment.merchantName ?? payment.transactionName ?? "pagamento"
        let amountText = payment.amount?.formatted(.currency(code: payment.currency)) ?? "montante por preencher"
        return .result(dialog: "Draft criado para \(merchantText): \(amountText).")
    }
}

struct FinTrackShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RegisterApplePayPaymentIntent(),
            phrases: [
                "Registar pagamento na \(.applicationName)",
                "Adicionar pagamento Apple Pay na \(.applicationName)"
            ],
            shortTitle: "Registar pagamento",
            systemImageName: "creditcard"
        )
    }
}
