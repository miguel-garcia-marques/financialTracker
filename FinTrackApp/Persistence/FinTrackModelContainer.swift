import Foundation
import SwiftData

enum FinTrackModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Payment.self,
            Bank.self,
            PaymentMethod.self
        ])

        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Unable to create FinTrack model container: \(error)")
        }
    }()
}
