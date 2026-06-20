import SwiftUI

enum AppTab: String, CaseIterable {
    case numbers, coin
    var label: String {
        switch self {
        case .numbers: return "🎲 Numbers"
        case .coin: return "🪙 Coin Toss"
        }
    }
}

struct ContentView: View {
    @StateObject private var store = PrefsStore.shared
    @State private var activeTab: AppTab = .numbers

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Random Web")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(Theme.text)
                        Text("Cryptographically secure randomness")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(.top, 24)

                    // Tab bar
                    HStack(spacing: 8) {
                        ForEach(AppTab.allCases, id: \.self) { tab in
                            TabButton(label: tab.label, isActive: activeTab == tab) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    activeTab = tab
                                    store.prefs.tab = tab.rawValue
                                }
                            }
                        }
                    }

                    // Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.surface)
                        Group {
                            if activeTab == .numbers {
                                NumbersView()
                            } else {
                                CoinView()
                            }
                        }
                        .padding(24)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            activeTab = AppTab(rawValue: store.prefs.tab) ?? .numbers
        }
    }
}

struct TabButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isActive ? Theme.text : Theme.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? Theme.surfaceHover : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? Theme.accent : Theme.border, lineWidth: 1)
                        .shadow(color: isActive ? Theme.accentGlow : .clear, radius: 6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
