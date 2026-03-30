import SwiftUI
import UserNotifications

final class PoolManager: ObservableObject {
    @Published var onboardingDone: Bool {
        didSet { UserDefaults.standard.set(onboardingDone, forKey: "pc_onboarding") }
    }
    @Published var pool: PoolProfile {
        didSet { Storage.shared.save(pool, forKey: "pc_pool") }
    }
    @Published var readings: [WaterReading] {
        didSet { Storage.shared.save(readings, forKey: "pc_readings") }
    }
    @Published var chemicals: [ChemicalItem] {
        didSet { Storage.shared.save(chemicals, forKey: "pc_chemicals") }
    }
    @Published var frequency: ReadingFrequency {
        didSet {
            Storage.shared.save(frequency, forKey: "pc_frequency")
            scheduleNotification()
        }
    }
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "pc_notif") }
    }

    init() {
        onboardingDone = UserDefaults.standard.bool(forKey: "pc_onboarding")
        pool = Storage.shared.load(forKey: "pc_pool", default: PoolProfile())
        readings = Storage.shared.load(forKey: "pc_readings", default: Self.sampleReadings)
        chemicals = Storage.shared.load(forKey: "pc_chemicals", default: Self.sampleChemicals)
        frequency = Storage.shared.load(forKey: "pc_frequency", default: .everyOtherDay)
        notificationsEnabled = UserDefaults.standard.bool(forKey: "pc_notif")
    }

    // MARK: - Readings

    var lastReading: WaterReading? { readings.sorted { $0.date > $1.date }.first }

    var sortedReadings: [WaterReading] { readings.sorted { $0.date > $1.date } }

    func addReading(_ r: WaterReading) {
        readings.append(r)
        scheduleNotification()
    }

    func deleteReading(_ r: WaterReading) {
        readings.removeAll { $0.id == r.id }
    }

    // MARK: - Quality Score

    var qualityScore: Int {
        guard let last = lastReading else { return 0 }
        let params: [WaterParameter] = [.pH, .freeChlorine, .alkalinity, .cyanuricAcid, .calciumHardness]
        var total: Double = 0
        var count: Double = 0
        for p in params {
            guard let v = p.value(from: last) else { continue }
            count += 1
            let mid = (p.idealMin + p.idealMax) / 2.0
            let range = p.idealMax - p.idealMin
            let dist = abs(v - mid)
            if dist <= range / 2 {
                total += 100
            } else {
                let overBy = dist - range / 2
                let penalty = min(overBy / (range * 0.5) * 50, 100)
                total += max(100 - penalty, 0)
            }
        }
        return count > 0 ? Int(total / count) : 0
    }

    // MARK: - Alerts

    struct ParameterAlert: Identifiable {
        let id = UUID()
        let parameter: WaterParameter
        let value: Double
        let status: ParameterStatus
        let message: String
    }

    var alerts: [ParameterAlert] {
        guard let last = lastReading else { return [] }
        var result: [ParameterAlert] = []
        for p in WaterParameter.allCases where p != .temperature && p != .totalChlorine {
            guard let v = p.value(from: last) else { continue }
            let s = p.status(for: v)
            guard s != .ideal else { continue }
            let dir = v < p.idealMin ? "low" : "high"
            result.append(ParameterAlert(parameter: p, value: v, status: s,
                                         message: "\(p.name) is \(dir) (\(p == .pH ? String(format: "%.1f", v) : String(format: "%.0f", v)) \(p.unit))"))
        }
        return result
    }

    // MARK: - Dosage Calculator

    static let dosageDatabase: [WaterParameter: [DosageChemical]] = [
        .pH: [
            DosageChemical(name: "Muriatic Acid (31.45%)", category: .phAdjuster,
                           dosePer10kLitersPerUnit: 180, unit: "mL",
                           instructions: "Add slowly to deep end with pump running. Lowers pH by ~0.2 per dose."),
            DosageChemical(name: "Sodium Bisulfate (Dry Acid)", category: .phAdjuster,
                           dosePer10kLitersPerUnit: 170, unit: "g",
                           instructions: "Dissolve in bucket first. Lowers pH by ~0.2 per dose."),
            DosageChemical(name: "Soda Ash (Sodium Carbonate)", category: .phAdjuster,
                           dosePer10kLitersPerUnit: 170, unit: "g",
                           instructions: "Pre-dissolve in warm water. Raises pH by ~0.2 per dose.")
        ],
        .freeChlorine: [
            DosageChemical(name: "Liquid Chlorine (12.5%)", category: .sanitizer,
                           dosePer10kLitersPerUnit: 100, unit: "mL",
                           instructions: "Pour along edges in evening. Raises FC by ~1 ppm per dose."),
            DosageChemical(name: "Cal-Hypo Granular (65%)", category: .sanitizer,
                           dosePer10kLitersPerUnit: 15, unit: "g",
                           instructions: "Pre-dissolve in bucket. Raises FC by ~1 ppm per dose. Also raises calcium."),
            DosageChemical(name: "Trichlor Tablets (90%)", category: .sanitizer,
                           dosePer10kLitersPerUnit: 8, unit: "g",
                           instructions: "Use in floater or feeder. Raises FC by ~1 ppm per dose. Also lowers pH and raises CYA.")
        ],
        .alkalinity: [
            DosageChemical(name: "Sodium Bicarbonate (Baking Soda)", category: .alkalinityAdjuster,
                           dosePer10kLitersPerUnit: 170, unit: "g",
                           instructions: "Broadcast over surface. Raises alkalinity by ~10 ppm per dose."),
            DosageChemical(name: "Muriatic Acid (31.45%)", category: .alkalinityAdjuster,
                           dosePer10kLitersPerUnit: 250, unit: "mL",
                           instructions: "Add at one spot with pump off, then aerate. Lowers alkalinity by ~10 ppm per dose.")
        ],
        .cyanuricAcid: [
            DosageChemical(name: "Cyanuric Acid (Stabilizer)", category: .stabilizer,
                           dosePer10kLitersPerUnit: 130, unit: "g",
                           instructions: "Dissolve in warm water or add to skimmer sock. Raises CYA by ~10 ppm per dose. Allow 48h to dissolve.")
        ],
        .calciumHardness: [
            DosageChemical(name: "Calcium Chloride (77%)", category: .calciumAdjuster,
                           dosePer10kLitersPerUnit: 110, unit: "g",
                           instructions: "Pre-dissolve in bucket of pool water. Raises calcium by ~10 ppm per dose. Add slowly.")
        ]
    ]

    func calculateDosage(parameter: WaterParameter, currentValue: Double, targetValue: Double) -> [DosageResult] {
        guard let chems = Self.dosageDatabase[parameter] else { return [] }
        let diff = abs(targetValue - currentValue)
        let needsIncrease = targetValue > currentValue
        let volumeFactor = pool.volumeInLiters / 10000.0

        var unitDiff: Double
        switch parameter {
        case .pH: unitDiff = diff / 0.2
        case .freeChlorine: unitDiff = diff / 1.0
        case .alkalinity, .cyanuricAcid, .calciumHardness: unitDiff = diff / 10.0
        default: unitDiff = diff
        }

        return chems.compactMap { chem in
            let isRaiser: Bool
            switch parameter {
            case .pH:
                isRaiser = chem.name.contains("Soda Ash")
            case .alkalinity:
                isRaiser = chem.name.contains("Bicarbonate")
            default:
                isRaiser = true
            }

            guard isRaiser == needsIncrease || parameter == .freeChlorine else { return nil }

            let amount = chem.dosePer10kLitersPerUnit * unitDiff * volumeFactor
            guard amount > 0 else { return nil }

            return DosageResult(
                chemical: chem.name,
                amount: amount,
                unit: chem.unit,
                instructions: chem.instructions
            )
        }
    }

    // MARK: - Chemicals Inventory

    func addChemical(_ item: ChemicalItem) { chemicals.append(item) }
    func deleteChemical(_ item: ChemicalItem) { chemicals.removeAll { $0.id == item.id } }
    func useChemical(id: UUID, amount: Double) {
        if let i = chemicals.firstIndex(where: { $0.id == id }) {
            chemicals[i].amountRemaining = max(0, chemicals[i].amountRemaining - amount)
        }
    }

    var lowStockChemicals: [ChemicalItem] {
        chemicals.filter { $0.amountRemaining < 500 && $0.unit == "g" || $0.amountRemaining < 1 && $0.unit == "L" }
    }

    // MARK: - Notifications

    func scheduleNotification() {
        guard notificationsEnabled else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pool_reading_reminder"])
        let content = UNMutableNotificationContent()
        content.title = "Pool Chemistry"
        content.body = "Time to test your pool water! Keep it crystal clear."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(frequency.hours * 3600), repeats: true)
        let request = UNNotificationRequest(identifier: "pool_reading_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if granted { self.scheduleNotification() }
            }
        }
    }

    // MARK: - Data Management

    func resetAllData() {
        readings = Self.sampleReadings
        chemicals = Self.sampleChemicals
        pool = PoolProfile()
    }

    // MARK: - Chart Data

    func chartData(for param: WaterParameter, days: Int = 30) -> [(Date, Double)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sortedReadings
            .filter { $0.date >= cutoff }
            .compactMap { r in
                guard let v = param.value(from: r) else { return nil }
                return (r.date, v)
            }
            .reversed()
    }

    // MARK: - Sample Data

    private static var sampleReadings: [WaterReading] {
        let cal = Calendar.current
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: Date())! }

        return [
            WaterReading(date: ago(0), pH: 7.4, freeChlorine: 2.5, totalChlorine: 3.0, alkalinity: 95, cyanuricAcid: 40, calciumHardness: 280, temperature: 27, notes: "Water looks crystal clear"),
            WaterReading(date: ago(2), pH: 7.5, freeChlorine: 2.0, totalChlorine: 2.5, alkalinity: 90, cyanuricAcid: 38, calciumHardness: 275, temperature: 26),
            WaterReading(date: ago(4), pH: 7.6, freeChlorine: 1.5, totalChlorine: 2.0, alkalinity: 88, cyanuricAcid: 38, calciumHardness: 270, temperature: 26),
            WaterReading(date: ago(6), pH: 7.3, freeChlorine: 3.0, totalChlorine: 3.5, alkalinity: 100, cyanuricAcid: 42, calciumHardness: 290, temperature: 27, notes: "Added chlorine after pool party"),
            WaterReading(date: ago(8), pH: 7.8, freeChlorine: 0.8, totalChlorine: 1.5, alkalinity: 110, cyanuricAcid: 42, calciumHardness: 290, temperature: 28, notes: "pH drifted high after rain"),
            WaterReading(date: ago(10), pH: 7.4, freeChlorine: 2.2, totalChlorine: 2.8, alkalinity: 95, cyanuricAcid: 40, calciumHardness: 285, temperature: 27),
            WaterReading(date: ago(12), pH: 7.5, freeChlorine: 1.8, totalChlorine: 2.5, alkalinity: 92, cyanuricAcid: 39, calciumHardness: 280, temperature: 26),
            WaterReading(date: ago(14), pH: 7.2, freeChlorine: 3.5, totalChlorine: 4.0, alkalinity: 105, cyanuricAcid: 45, calciumHardness: 300, temperature: 28, notes: "Shock treatment after algae spot"),
            WaterReading(date: ago(17), pH: 7.6, freeChlorine: 1.2, totalChlorine: 2.0, alkalinity: 85, cyanuricAcid: 35, calciumHardness: 260, temperature: 25),
            WaterReading(date: ago(20), pH: 7.3, freeChlorine: 2.8, totalChlorine: 3.2, alkalinity: 98, cyanuricAcid: 41, calciumHardness: 285, temperature: 26),
            WaterReading(date: ago(23), pH: 7.7, freeChlorine: 1.0, totalChlorine: 1.8, alkalinity: 115, cyanuricAcid: 43, calciumHardness: 295, temperature: 27, notes: "Alkalinity crept up"),
            WaterReading(date: ago(26), pH: 7.4, freeChlorine: 2.5, totalChlorine: 3.0, alkalinity: 100, cyanuricAcid: 40, calciumHardness: 280, temperature: 26),
            WaterReading(date: ago(29), pH: 7.5, freeChlorine: 2.0, totalChlorine: 2.5, alkalinity: 95, cyanuricAcid: 38, calciumHardness: 275, temperature: 25),
        ]
    }

    private static var sampleChemicals: [ChemicalItem] {
        [
            ChemicalItem(name: "Liquid Chlorine (12.5%)", category: .sanitizer, amountRemaining: 8.5, unit: "L",
                         purchaseDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())),
            ChemicalItem(name: "Cal-Hypo Granular (65%)", category: .sanitizer, amountRemaining: 2500, unit: "g",
                         purchaseDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())),
            ChemicalItem(name: "Muriatic Acid (31.45%)", category: .phAdjuster, amountRemaining: 4.0, unit: "L",
                         purchaseDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())),
            ChemicalItem(name: "Soda Ash", category: .phAdjuster, amountRemaining: 1800, unit: "g"),
            ChemicalItem(name: "Sodium Bicarbonate", category: .alkalinityAdjuster, amountRemaining: 3000, unit: "g"),
            ChemicalItem(name: "Cyanuric Acid", category: .stabilizer, amountRemaining: 1500, unit: "g"),
            ChemicalItem(name: "Calcium Chloride (77%)", category: .calciumAdjuster, amountRemaining: 2000, unit: "g"),
            ChemicalItem(name: "Pool Shock (Cal-Hypo 73%)", category: .shock, amountRemaining: 1200, unit: "g",
                         purchaseDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())),
            ChemicalItem(name: "Algaecide 60%", category: .algaecide, amountRemaining: 1.5, unit: "L"),
            ChemicalItem(name: "Water Clarifier", category: .clarifier, amountRemaining: 0.8, unit: "L"),
            ChemicalItem(name: "Sodium Bisulfate (Dry Acid)", category: .phAdjuster, amountRemaining: 2200, unit: "g"),
            ChemicalItem(name: "Trichlor Tablets (90%)", category: .sanitizer, amountRemaining: 3500, unit: "g",
                         purchaseDate: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())),
        ]
    }
}
