import SwiftUI

struct NumbersView: View {
    @StateObject private var store = PrefsStore.shared
    @State private var minText: String = "1"
    @State private var maxText: String = "100"
    @State private var lastResult: String = ""
    @State private var resultRange: String = ""
    @State private var isShuffle: Bool = false
    @State private var error: String = ""
    @State private var popTrigger: Bool = false
    @State private var copyState: CopyState = .idle
    @State private var showDiag: Bool = false
    @State private var diagRunning: Bool = false
    @State private var diagText: String = ""

    enum CopyState { case idle, copied, failed }

    private var minVal: Int? { Int(minText) }
    private var maxVal: Int? { Int(maxText) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Min/Max fields
            HStack(spacing: 12) {
                BoundField(label: "Min", text: $minText, onCommit: {
                    persistBounds(); generateNumber()
                })
                BoundField(label: "Max", text: $maxText, onCommit: {
                    persistBounds(); generateNumber()
                })
            }

            if !error.isEmpty {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.danger)
                    .padding(.top, 8)
            }

            PrimaryButton(label: "Generate Number") { generateNumber() }
                .padding(.top, 12)

            SecondaryButton(label: "🔀 Shuffle Range") { shuffleRange() }
                .padding(.top, 8)

            // Result area
            VStack(spacing: 8) {
                Text("Last result")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(Theme.textMuted)

                CopyButton(state: copyState, disabled: lastResult.isEmpty) { copy() }

                if !lastResult.isEmpty {
                    Text(lastResult)
                        .font(.system(size: isShuffle ? 20 : 56, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accent)
                        .multilineTextAlignment(.center)
                        .scaleEffect(popTrigger ? 1.0 : 1.0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: popTrigger)
                }

                if !resultRange.isEmpty {
                    Text(resultRange)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .frame(minHeight: 80)

            // Diagnostic section
            Divider()
                .background(Theme.border)
                .padding(.top, 16)

            DiagnosticView(
                running: diagRunning,
                showOutput: showDiag,
                diagText: diagText,
                onRun: runDiagnostic
            )
            .padding(.top, 16)
        }
        .onAppear {
            minText = String(store.prefs.min)
            maxText = String(store.prefs.max)
        }
    }

    private func validateBounds() -> String? {
        guard let mn = minVal, let mx = maxVal else {
            return "Please enter numbers for both bounds."
        }
        if mn > mx { return "Min must be less than or equal to Max." }
        if mx - mn > 1_000_000 { return "Range too large. Max difference is 1,000,000." }
        return nil
    }

    private func generateNumber() {
        if let err = validateBounds() { error = err; return }
        error = ""
        let mn = minVal!, mx = maxVal!
        let result = CSPRNG.randomInt(min: mn, max: mx)
        lastResult = String(result)
        resultRange = "\(mn) – \(mx)"
        isShuffle = false
        triggerPop()
    }

    private func shuffleRange() {
        if let err = validateBounds() { error = err; return }
        error = ""
        let mn = minVal!, mx = maxVal!
        let values = Array(mn...mx)
        let shuffled = CSPRNG.shuffle(values)
        let displayCap = 1000
        if shuffled.count <= displayCap {
            lastResult = shuffled.map(String.init).joined(separator: " ")
        } else {
            let head = shuffled.prefix(20).map(String.init).joined(separator: " ")
            let tail = shuffled.suffix(20).map(String.init).joined(separator: " ")
            lastResult = head + " ... " + tail
        }
        resultRange = "\(mn) – \(mx)  (\(shuffled.count.formatted()) items)"
        isShuffle = true
        triggerPop()
    }

    private func triggerPop() {
        popTrigger = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation { popTrigger = true }
        }
    }

    private func persistBounds() {
        if let mn = minVal { store.prefs.min = mn }
        if let mx = maxVal { store.prefs.max = mx }
    }

    private func copy() {
        UIPasteboard.general.string = lastResult
        withAnimation { copyState = .copied }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { copyState = .idle }
        }
    }

    private func runDiagnostic() {
        if let err = validateBounds() { error = err; return }
        error = ""
        let mn = minVal!, mx = maxVal!
        diagRunning = true
        showDiag = false
        DispatchQueue.global(qos: .userInitiated).async {
            let n = 100_000
            let start = Date()
            var values = [Int](repeating: 0, count: n)
            for i in 0..<n { values[i] = CSPRNG.randomInt(min: mn, max: mx) }
            let elapsed = String(format: "%.2f", Date().timeIntervalSince(start))

            let range = mx - mn + 1
            var counts = [Int: Int]()
            for v in values { counts[v, default: 0] += 1 }
            let expected = Double(n) / Double(range)

            var lines = [String]()
            if range <= 20 {
                lines.append("Distribution:")
                for v in mn...mx {
                    let c = counts[v] ?? 0
                    let pct = String(format: "%.3f", Double(c) / Double(n) * 100)
                    let delta = String(format: "%.2f", (Double(c) - expected) / expected * 100)
                    lines.append("  \(v): \(c.formatted()) (\(pct)%) \(delta)%")
                }
            } else {
                lines.append("Distribution: \(range) values, expected ~\(Int(expected)) each")
            }

            // Streak analysis
            var streaks = [Int: Int]()
            var i = 0
            while i < values.count {
                var len = 1
                while i + len < values.count && values[i + len] == values[i] { len += 1 }
                if len >= 2 { streaks[len, default: 0] += 1 }
                i += len
            }
            lines.append("\nStreak lengths (observed vs expected):")
            let pSame = 1.0 / Double(range)
            let windows = n - 1
            for len in 2...8 {
                let obs = streaks[len] ?? 0
                let exp = Double(windows) * pow(pSame, Double(len - 1)) * (1 - pSame)
                if exp < 0.5 && obs == 0 { continue }
                lines.append("  Len \(len): \(obs.formatted()) (expected ~\(String(format: "%.1f", exp)))")
            }
            lines.append("\nGenerated: \(n.formatted()) values in \(elapsed)s")
            lines.append("Source: SecRandomCopyBytes — iOS CSPRNG")

            DispatchQueue.main.async {
                diagText = lines.joined(separator: "\n")
                showDiag = true
                diagRunning = false
            }
        }
    }
}

struct BoundField: View {
    let label: String
    @Binding var text: String
    let onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Theme.textMuted)
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onSubmit(onCommit)
        }
    }
}

struct CopyButton: View {
    let state: NumbersView.CopyState
    let disabled: Bool
    let action: () -> Void

    var label: String {
        switch state {
        case .idle: return "📋 Copy"
        case .copied: return "✓ Copied!"
        case .failed: return "⚠ Failed"
        }
    }
    var labelColor: Color {
        switch state {
        case .idle: return Theme.textMuted
        case .copied: return Theme.success
        case .failed: return Theme.danger
        }
    }
    var borderColor: Color {
        switch state {
        case .copied: return Theme.success
        default: return Theme.border
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(disabled ? Theme.textMuted.opacity(0.3) : labelColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(disabled ? Theme.border.opacity(0.3) : borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct DiagnosticView: View {
    let running: Bool
    let showOutput: Bool
    let diagText: String
    let onRun: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onRun) {
                Text(running ? "Running 100,000 iterations…" : "🔬 Verify Fairness (iOS CSPRNG)")
                    .font(.system(size: 14))
                    .foregroundColor(running ? Theme.textMuted : Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(running)

            if showOutput {
                ScrollView {
                    Text(diagText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .frame(maxHeight: 280)
                .background(Theme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct PrimaryButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surfaceHover)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
