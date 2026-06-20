import SwiftUI

enum Theme {
    static let bg = Color(hex: "#0f0f14")
    static let surface = Color(hex: "#1a1a24")
    static let surfaceHover = Color(hex: "#242438")
    static let text = Color(hex: "#e8e8f0")
    static let textMuted = Color(hex: "#8888a0")
    static let accent = Color(hex: "#7c5cfc")
    static let accentGlow = Color(hex: "#7c5cfc").opacity(0.35)
    static let danger = Color(hex: "#fc5c7d")
    static let success = Color(hex: "#5cfc9b")
    static let border = Color(hex: "#2a2a3a")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
