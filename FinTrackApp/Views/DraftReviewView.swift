import SwiftData
import SwiftUI

struct DraftReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var payment: Payment

    var body: some View {
        Form {
            Section("Draft") {
                TextField("Comerciante", text: binding(\.merchantName, default: ""))
                TextField("Nome da transacao", text: binding(\.transactionName, default: ""))
                LabeledContent("Montante", value: payment.amount?.formatted(.currency(code: payment.currency)) ?? "Por preencher")
                LabeledContent("Cartao ou passe", value: payment.paymentMethod?.shortcutCardLabel ?? "Por inferir")
                LabeledContent("Banco", value: payment.bank?.displayName ?? payment.bankName ?? "Por inferir")
                LabeledContent("Data", value: payment.transactionAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Fatura", value: "Sem fatura")
            }

            Section("Notas") {
                TextField("Notas", text: $payment.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button {
                    confirm()
                } label: {
                    Label("Confirmar", systemImage: "checkmark.circle")
                }

                Button {
                    keepPending()
                } label: {
                    Label("Guardar como pendente", systemImage: "clock")
                }

                Button(role: .destructive) {
                    discard()
                } label: {
                    Label("Descartar", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Rever draft")
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<Payment, String?>, default defaultValue: String) -> Binding<String> {
        Binding {
            payment[keyPath: keyPath] ?? defaultValue
        } set: { newValue in
            payment[keyPath: keyPath] = newValue.trimmedNilIfEmpty
            payment.updatedAt = .now
        }
    }

    private func confirm() {
        payment.status = payment.amount == nil || payment.merchantName == nil ? .needsReconciliation : .pendingEnrichment
        try? modelContext.save()
        dismiss()
    }

    private func keepPending() {
        payment.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }

    private func discard() {
        payment.status = .discarded
        try? modelContext.save()
        dismiss()
    }
}
