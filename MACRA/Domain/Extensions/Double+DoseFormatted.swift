import Foundation

extension Double {
    /// Formats a supplement/compound dose for display.
    /// - Values >= 1000 use comma grouping (e.g., "1,000", "2,500.5")
    /// - Whole-number values omit the decimal (e.g., "250" instead of "250.0")
    /// - Fractional values retain their natural precision (e.g., "0.25", "12.5")
    /// Formats a weight value: suppresses .0 for whole numbers, 1 decimal otherwise.
    var cleanWeightString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    var doseFormatted: String {
        if self >= 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
            return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        }
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        }
        return String(self)
    }
}
