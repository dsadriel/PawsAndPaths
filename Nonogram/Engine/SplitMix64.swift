import Foundation

/// Fast, high-quality 64-bit deterministic pseudo-random number generator.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }

    /// Generates a random integer in 0..<upperBound.
    public mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    /// Generates a random Double in 0.0..<1.0.
    public mutating func nextDouble() -> Double {
        Double(next() &>> 11) / Double(1 << 53)
    }
}
