import SwiftData
import SwiftUI

struct DraftsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Payment.transactionAt, order: .reverse) private var payments: [Payment]

    private var drafts: [Payment] {
        payments.filter { $0.status == .draft }
    }

    var body: some View {
        NavigationStack {
            Group {
                if drafts.isEmpty {
                    EmptyStateView(
                        title: "Sem drafts pendentes",
                        message: "Eventos Apple Pay sem decisao ficam guardados aqui.",
                        systemImage: "tray"
                    )
                } else {
                    List(drafts) { payment in
                        NavigationLink {
                            DraftReviewView(payment: payment)
                        } label: {
                            PaymentRowView(payment: payment)
                        }
                    }
                }
            }
            .navigationTitle("Drafts")
            .toolbar {
                Button {
                    addSampleDraft()
                } label: {
                    Label("Adicionar draft", systemImage: "plus")
                }
            }
        }
    }

    private func addSampleDraft() {
        let payment = PaymentDraftFactory.applePayShortcutDraft(
            transaction: "sample-shortcut-transaction",
            cardOrPass: "Apple Pay",
            merchant: "Ji Yuan",
            amount: "8,70 €",
            name: "Ji Yuan"
        )
        modelContext.insert(payment)
        try? modelContext.save()
    }
}
