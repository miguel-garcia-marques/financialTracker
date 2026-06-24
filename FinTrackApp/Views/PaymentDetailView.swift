import SwiftUI

struct PaymentDetailView: View {
    let payment: Payment

    var body: some View {
        List {
            Section("Pagamento") {
                LabeledContent("Montante", value: payment.amount?.formatted(.currency(code: payment.currency)) ?? "Por preencher")
                LabeledContent("Comerciante", value: payment.merchantName ?? "Por preencher")
                LabeledContent("Nome", value: payment.transactionName ?? "Por preencher")
                LabeledContent("Data", value: payment.transactionAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Estado", value: payment.status.displayName)
                LabeledContent("Origem", value: payment.source.displayName)
            }

            Section("Banco e metodo") {
                LabeledContent("Banco", value: payment.bank?.displayName ?? payment.bankName ?? "Por inferir")
                LabeledContent("Metodo", value: payment.paymentMethod?.displayName ?? "Por inferir")
            }

            Section("Notas") {
                Text(payment.notes.isEmpty ? "Sem notas" : payment.notes)
                    .foregroundStyle(payment.notes.isEmpty ? .secondary : .primary)
            }
        }
        .navigationTitle(payment.merchantName ?? "Pagamento")
    }
}
