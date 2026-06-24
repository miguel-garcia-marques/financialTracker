import SwiftData
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Hoje", systemImage: "sun.max")
                }

            HistoryView()
                .tabItem {
                    Label("Historico", systemImage: "list.bullet")
                }

            CalendarView()
                .tabItem {
                    Label("Calendario", systemImage: "calendar")
                }

            ReceiptsView()
                .tabItem {
                    Label("Faturas", systemImage: "doc.text.viewfinder")
                }

            DraftsView()
                .tabItem {
                    Label("Drafts", systemImage: "tray")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Definicoes", systemImage: "gearshape")
                }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}
