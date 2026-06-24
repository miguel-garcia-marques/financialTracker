import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                title: "Calendario por criar",
                message: "A vista mensal vai mostrar totais por dia e pendencias.",
                systemImage: "calendar"
            )
            .navigationTitle("Calendario")
        }
    }
}

struct ReceiptsView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                title: "Sem faturas",
                message: "Faturas avulsas e anexos de pagamentos aparecem aqui.",
                systemImage: "doc.text.viewfinder"
            )
            .navigationTitle("Faturas")
        }
    }
}

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                title: "Sem insights",
                message: "Totais e qualidade de dados locais aparecem aqui.",
                systemImage: "chart.line.uptrend.xyaxis"
            )
            .navigationTitle("Insights")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Dados") {
                    LabeledContent("Modo", value: "Local-first")
                    LabeledContent("Moeda predefinida", value: "EUR")
                }

                Section("Integracoes") {
                    LabeledContent("Shortcuts", value: "App Intent")
                    LabeledContent("IA cloud", value: "Desligada")
                }
            }
            .navigationTitle("Definicoes")
        }
    }
}
