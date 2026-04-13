import SwiftUI

enum PoolType: String, Codable, CaseIterable, Identifiable {
    case inground = "In-Ground"
    case aboveground = "Above-Ground"
    case hotTub = "Hot Tub"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .inground: return "rectangle.inset.filled"
        case .aboveground: return "circle.bottomhalf.filled"
        case .hotTub: return "bathtub.fill"
        }
    }
}

enum SurfaceType: String, Codable, CaseIterable, Identifiable {
    case plaster = "Plaster"
    case vinyl = "Vinyl"
    case fiberglass = "Fiberglass"
    case tile = "Tile"
    var id: String { rawValue }
}

enum VolumeUnit: String, Codable, CaseIterable {
    case liters = "Liters"
    case gallons = "Gallons"
    var short: String { self == .liters ? "L" : "gal" }
    var conversionToLiters: Double { self == .liters ? 1.0 : 3.78541 }
}

struct PoolProfile: Codable {
    var name: String = "My Pool"
    var volume: Double = 40000
    var volumeUnit: VolumeUnit = .liters
    var type: PoolType = .inground
    var surface: SurfaceType = .plaster
    var volumeInLiters: Double { volume * volumeUnit.conversionToLiters }
}

struct WaterReading: Identifiable, Codable {
    var id = UUID()
    var date: Date = Date()
    var pH: Double?
    var freeChlorine: Double?
    var totalChlorine: Double?
    var alkalinity: Double?
    var cyanuricAcid: Double?
    var calciumHardness: Double?
    var temperature: Double?
    var notes: String = ""
}

enum WaterParameter: String, CaseIterable, Identifiable {
    case pH, freeChlorine, totalChlorine, alkalinity, cyanuricAcid, calciumHardness, temperature
    var id: String { rawValue }

    var name: String {
        switch self {
        case .pH: return "pH"
        case .freeChlorine: return "Free Chlorine"
        case .totalChlorine: return "Total Chlorine"
        case .alkalinity: return "Alkalinity"
        case .cyanuricAcid: return "CYA"
        case .calciumHardness: return "Calcium"
        case .temperature: return "Temp"
        }
    }

    var unit: String {
        switch self {
        case .pH: return ""
        case .temperature: return "°C"
        default: return "ppm"
        }
    }

    var icon: String {
        switch self {
        case .pH: return "drop.fill"
        case .freeChlorine: return "shield.checkered"
        case .totalChlorine: return "shield.fill"
        case .alkalinity: return "water.waves"
        case .cyanuricAcid: return "sun.max.fill"
        case .calciumHardness: return "diamond.fill"
        case .temperature: return "thermometer.medium"
        }
    }

    var color: Color {
        switch self {
        case .pH: return Color(red: 0.40, green: 0.50, blue: 0.95)
        case .freeChlorine: return Color(red: 0.20, green: 0.78, blue: 0.55)
        case .totalChlorine: return Color(red: 0.30, green: 0.70, blue: 0.65)
        case .alkalinity: return Color(red: 0.60, green: 0.40, blue: 0.90)
        case .cyanuricAcid: return Color(red: 0.95, green: 0.70, blue: 0.25)
        case .calciumHardness: return Color(red: 0.25, green: 0.75, blue: 0.90)
        case .temperature: return Color(red: 0.90, green: 0.45, blue: 0.30)
        }
    }

    var idealMin: Double {
        switch self {
        case .pH: return 7.2
        case .freeChlorine: return 1.0
        case .totalChlorine: return 1.0
        case .alkalinity: return 80
        case .cyanuricAcid: return 30
        case .calciumHardness: return 200
        case .temperature: return 25
        }
    }

    var idealMax: Double {
        switch self {
        case .pH: return 7.6
        case .freeChlorine: return 3.0
        case .totalChlorine: return 5.0
        case .alkalinity: return 120
        case .cyanuricAcid: return 50
        case .calciumHardness: return 400
        case .temperature: return 28
        }
    }

    var gaugeMin: Double {
        switch self {
        case .pH: return 6.0
        case .freeChlorine: return 0
        case .totalChlorine: return 0
        case .alkalinity: return 0
        case .cyanuricAcid: return 0
        case .calciumHardness: return 0
        case .temperature: return 15
        }
    }

    var gaugeMax: Double {
        switch self {
        case .pH: return 9.0
        case .freeChlorine: return 10
        case .totalChlorine: return 10
        case .alkalinity: return 300
        case .cyanuricAcid: return 150
        case .calciumHardness: return 800
        case .temperature: return 40
        }
    }

    var step: Double {
        switch self {
        case .pH: return 0.1
        case .temperature: return 0.5
        default: return 1.0
        }
    }

    func value(from reading: WaterReading) -> Double? {
        switch self {
        case .pH: return reading.pH
        case .freeChlorine: return reading.freeChlorine
        case .totalChlorine: return reading.totalChlorine
        case .alkalinity: return reading.alkalinity
        case .cyanuricAcid: return reading.cyanuricAcid
        case .calciumHardness: return reading.calciumHardness
        case .temperature: return reading.temperature
        }
    }

    func status(for value: Double) -> ParameterStatus {
        if value >= idealMin && value <= idealMax { return .ideal }
        let warnLo = idealMin - (idealMax - idealMin) * 0.5
        let warnHi = idealMax + (idealMax - idealMin) * 0.5
        if value >= warnLo && value <= warnHi { return .warning }
        return .danger
    }
}

enum ParameterStatus {
    case ideal, warning, danger
    var color: Color {
        switch self {
        case .ideal: return Color(red: 0.25, green: 0.82, blue: 0.52)
        case .warning: return Color(red: 0.95, green: 0.75, blue: 0.22)
        case .danger: return Color(red: 0.92, green: 0.30, blue: 0.30)
        }
    }
    var label: String {
        switch self {
        case .ideal: return "Ideal"
        case .warning: return "Warning"
        case .danger: return "Danger"
        }
    }
    var icon: String {
        switch self {
        case .ideal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.octagon.fill"
        }
    }
}

enum ChemicalCategory: String, Codable, CaseIterable, Identifiable {
    case sanitizer = "Sanitizer"
    case phAdjuster = "pH Adjuster"
    case alkalinityAdjuster = "Alkalinity"
    case stabilizer = "Stabilizer"
    case calciumAdjuster = "Calcium"
    case shock = "Shock Treatment"
    case algaecide = "Algaecide"
    case clarifier = "Clarifier"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .sanitizer: return "shield.checkered"
        case .phAdjuster: return "drop.fill"
        case .alkalinityAdjuster: return "water.waves"
        case .stabilizer: return "sun.max.fill"
        case .calciumAdjuster: return "diamond.fill"
        case .shock: return "bolt.fill"
        case .algaecide: return "leaf.fill"
        case .clarifier: return "sparkles"
        }
    }
}

struct ChemicalItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var category: ChemicalCategory
    var amountRemaining: Double
    var unit: String
    var purchaseDate: Date?
    var expiryDate: Date?
    var notes: String = ""
}

struct DosageChemical: Identifiable {
    let id = UUID()
    let name: String
    let category: ChemicalCategory
    let dosePer10kLitersPerUnit: Double
    let unit: String
    let instructions: String
}

struct DosageResult: Identifiable {
    let id = UUID()
    let chemical: String
    let amount: Double
    let unit: String
    let instructions: String
}

// MARK: - Maintenance Log

enum MaintenanceType: String, Codable, CaseIterable, Identifiable {
    case filterClean = "Filter Clean"
    case filterReplace = "Filter Replace"
    case vacuuming = "Vacuuming"
    case brushing = "Brushing"
    case skimming = "Skimming"
    case pumpCheck = "Pump Check"
    case winterize = "Winterize"
    case springOpen = "Spring Opening"
    case coverClean = "Cover Clean"
    case other = "Other"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .filterClean: return "arrow.triangle.2.circlepath"
        case .filterReplace: return "arrow.3.trianglepath"
        case .vacuuming: return "wind"
        case .brushing: return "paintbrush.fill"
        case .skimming: return "leaf.arrow.triangle.circlepath"
        case .pumpCheck: return "gearshape.fill"
        case .winterize: return "snowflake"
        case .springOpen: return "sun.max.fill"
        case .coverClean: return "rectangle.inset.filled"
        case .other: return "wrench.fill"
        }
    }
}

struct MaintenanceEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date = Date()
    var type: MaintenanceType
    var notes: String = ""
    var durationMinutes: Int = 0
}

// MARK: - Seasonal Tips

struct SeasonalTip: Identifiable {
    let id: Int
    let text: String
    let icon: String
    let season: String

    static var current: SeasonalTip {
        let month = Calendar.current.component(.month, from: Date())
        let season: String
        switch month {
        case 3...5: season = "Spring"
        case 6...8: season = "Summer"
        case 9...11: season = "Fall"
        default: season = "Winter"
        }
        let seasonal = all.filter { $0.season == season || $0.season == "All" }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return seasonal[day % seasonal.count]
    }

    static let all: [SeasonalTip] = [
        SeasonalTip(id: 0, text: "Test your water at least twice a week during swimming season for safe conditions.", icon: "drop.fill", season: "All"),
        SeasonalTip(id: 1, text: "Run your pump 8-12 hours per day to ensure proper circulation and filtration.", icon: "arrow.triangle.2.circlepath", season: "All"),
        SeasonalTip(id: 2, text: "Shock your pool weekly during heavy use periods to eliminate combined chlorine.", icon: "bolt.fill", season: "Summer"),
        SeasonalTip(id: 3, text: "Skim debris daily in summer — organic matter consumes chlorine rapidly.", icon: "leaf.arrow.triangle.circlepath", season: "Summer"),
        SeasonalTip(id: 4, text: "Keep CYA (stabilizer) levels 30-50 ppm to protect chlorine from UV degradation.", icon: "sun.max.fill", season: "Summer"),
        SeasonalTip(id: 5, text: "Lower water level and add winterizing chemicals before covering for the season.", icon: "snowflake", season: "Fall"),
        SeasonalTip(id: 6, text: "Clean and store pool accessories before temperatures drop below freezing.", icon: "archivebox.fill", season: "Fall"),
        SeasonalTip(id: 7, text: "Check your pool cover monthly during winter for tears and standing water.", icon: "eye.fill", season: "Winter"),
        SeasonalTip(id: 8, text: "Order replacement chemicals and parts in winter to be ready for spring opening.", icon: "shippingbox.fill", season: "Winter"),
        SeasonalTip(id: 9, text: "Balance pH and alkalinity first when opening your pool — other chemicals follow.", icon: "water.waves", season: "Spring"),
        SeasonalTip(id: 10, text: "Deep clean your filter at the start of the season for maximum flow rate.", icon: "arrow.3.trianglepath", season: "Spring"),
        SeasonalTip(id: 11, text: "Brush walls and floor weekly to prevent algae buildup, especially in shady areas.", icon: "paintbrush.fill", season: "All"),
    ]
}

enum ReadingFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case everyOtherDay = "Every 2 Days"
    case twiceWeek = "Twice a Week"
    case weekly = "Weekly"
    var hours: Int {
        switch self {
        case .daily: return 24
        case .everyOtherDay: return 48
        case .twiceWeek: return 84
        case .weekly: return 168
        }
    }
}
