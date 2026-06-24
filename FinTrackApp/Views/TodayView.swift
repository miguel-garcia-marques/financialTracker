import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \Payment.transactionAt, order: .reverse) private var payments: [Payment]

    private var todaysPayments: [Payment] {
        payments.filter { payment in
            Calendar.current.isDateInToday(payment.transactionAt) && payment.isIncludedInFinancialTotals
        }
    }

    private var total: Decimal {
        todaysPayments.compactMap(\.amount).reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total de hoje", value: total.formatted(.currency(code: "EUR")))
                    LabeledContent("Transacoes", value: "\(todaysPayments.count)")
                }

                if todaysPayments.isEmpty {
                    EmptyStateView(
                        title: "Sem compras hoje",
                        message: "Pagamentos confirmados e drafts recentes aparecem aqui.",
                        systemImage: "creditcard"
                    )
                } else {
                    Section("Hoje") {
                        ForEach(todaysPayments) { payment in
                            PaymentRowView(payment: payment)
                        }
                    }
                }
            }
            .navigationTitle("Hoje")
        }
    }
}
