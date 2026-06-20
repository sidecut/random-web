import Foundation
import Security

enum CSPRNG {
    /// Rejection-sampled uniform integer in [min, max] with no modulo bias.
    static func randomInt(min: Int, max: Int) -> Int {
        precondition(min <= max)
        let range = UInt64(max - min) + 1
        let maxUInt64 = UInt64.max
        let maxValid = maxUInt64 - (maxUInt64 % range)

        var val: UInt64 = 0
        repeat {
            var raw: UInt64 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt64>.size, &raw)
            val = raw
        } while val >= maxValid

        return min + Int(val % range)
    }

    /// Bit-0 of a single random byte — true = heads.
    static func randomBoolean() -> Bool {
        var byte: UInt8 = 0
        _ = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
        return (byte & 1) == 0
    }

    /// Fisher-Yates shuffle using CSPRNG.
    static func shuffle<T>(_ array: [T]) -> [T] {
        var a = array
        for i in stride(from: a.count - 1, through: 1, by: -1) {
            let j = randomInt(min: 0, max: i)
            a.swapAt(i, j)
        }
        return a
    }
}
