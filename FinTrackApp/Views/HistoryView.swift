import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \Payment.transactionAt, order: .reverse) private var payments: [Payment]

    var body: some View {
        NavigationStack {
            Group {
                let visiblePayments = payments.filter(\.isIncludedInFinancialTotals)
                if visiblePayments.isEmpty {
                    EmptyStateView(
                        title: "Sem historico",
                        message: "Transacoes manuais e pagamentos confirmados aparecem nesta lista.",
                        systemImage: "list.bullet.rectangle"
                    )
                } else {
                    List(visiblePayments) { payment in
                        NavigationLink {
                            PaymentDetailView(payment: payment)
                        } label: {
                            PaymentRowView(payment: payment)
                        }
                    }
                }
            }
            .navigationTitle("Historico")
        }
    }
}
