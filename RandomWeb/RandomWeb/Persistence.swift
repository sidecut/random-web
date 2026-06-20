import Foundation

struct CoinStats: Codable, Equatable {
    var heads: Int = 0
    var tails: Int = 0
    var total: Int { heads + tails }
}

struct Prefs: Codable {
    var min: Int = 1
    var max: Int = 100
    var tab: String = "numbers"
    var coinStats: CoinStats = CoinStats()
}

final class PrefsStore: ObservableObject {
    static let shared = PrefsStore()
    private let key = "random-web-prefs"

    @Published var prefs: Prefs {
        didSet { save() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Prefs.self, from: data) {
            prefs = decoded
        } else {
            prefs = Prefs()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
