import SwiftUI

struct CoinView: View {
    @StateObject private var store = PrefsStore.shared
    @State private var coinResult: CoinResult = .none
    @State private var isFlipping: Bool = false
    @State private var flipAngle: Double = 0
    @State private var displayHeads: Bool = true

    enum CoinResult {
        case none, heads, tails
        var text: String {
            switch self { case .none: return ""; case .heads: return "Heads"; case .tails: return "Tails" }
        }
        var color: Color {
            switch self { case .heads: return Theme.accent; default: return Theme.danger }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            PrimaryButton(label: "Toss Coin") { tossCoin() }

            // Coin
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#f5d76e"), Color(hex: "#e6b800")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
                    .rotation3DEffect(
                        .degrees(flipAngle),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                    .overlay(
                        Group {
                            if !isFlipping && coinResult == .none {
                                Text("?")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(Color(hex: "#8b7300"))
                            } else {
                                CoinFaceView(isHeads: displayHeads)
                                    .clipShape(Circle())
                            }
                        }
                        .rotation3DEffect(.degrees(flipAngle), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                    )
            }
            .frame(height: 160)

            // Result label
            Text(coinResult.text)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(coinResult == .none ? .clear : coinResult.color)
                .frame(minHeight: 40)
                .padding(.bottom, 16)

            // Stats
            HStack(spacing: 12) {
                StatCell(value: store.prefs.coinStats.heads, label: "Heads")
                StatCell(value: store.prefs.coinStats.tails, label: "Tails")
                StatCell(value: store.prefs.coinStats.total, label: "Total")
            }

            Button(action: resetStats) {
                Text("Clear stats")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private func tossCoin() {
        guard !isFlipping else { return }
        let isHeads = CSPRNG.randomBoolean()

        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        if reduceMotion {
            settle(isHeads: isHeads)
            return
        }

        isFlipping = true
        coinResult = .none
        var flips = 3 + Int.random(in: 0...2)
        if (flips % 2 == 0) != isHeads { flips += 1 }

        displayHeads = true
        var done = 0

        func doFlip() {
            withAnimation(.linear(duration: 0.08)) {
                flipAngle = -90
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                displayHeads.toggle()
                withAnimation(.linear(duration: 0.08)) {
                    flipAngle = 0
                }
                done += 1
                if done < flips {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { doFlip() }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        settle(isHeads: isHeads)
                        isFlipping = false
                    }
                }
            }
        }
        doFlip()
    }

    private func settle(isHeads: Bool) {
        displayHeads = isHeads
        coinResult = isHeads ? .heads : .tails
        if isHeads {
            store.prefs.coinStats.heads += 1
        } else {
            store.prefs.coinStats.tails += 1
        }
    }

    private func resetStats() {
        store.prefs.coinStats = CoinStats()
        coinResult = .none
        flipAngle = 0
    }
}

struct CoinFaceView: View {
    let isHeads: Bool

    var body: some View {
        if isHeads, let img = UIImage(named: "coin-heads") {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else if !isHeads, let img = UIImage(named: "coin-tails") {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            // Fallback text when images not in asset catalog
            Text(isHeads ? "H" : "T")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color(hex: "#8b7300"))
                .frame(width: 120, height: 120)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#f5d76e"), Color(hex: "#e6b800")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct StatCell: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(String(value))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.text)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
