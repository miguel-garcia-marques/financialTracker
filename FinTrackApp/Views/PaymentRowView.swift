import SwiftUI

struct PaymentRowView: View {
    let payment: Payment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: payment.status == .draft ? "pencil.circle" : "checkmark.circle")
                .foregroundStyle(payment.status == .draft ? .orange : .green)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 4) {
                Text(payment.merchantName ?? payment.transactionName ?? "Pagamento sem comerciante")
                    .font(.headline)

                Text("\(payment.source.displayName) · \(payment.status.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(payment.amount?.formatted(.currency(code: payment.currency)) ?? "--")
                .font(.headline.monospacedDigit())
        }
    }
}
