import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var manager: PoolManager
    @State private var showAddReading = false
    @State private var waveOffset: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                scoreSection
                gaugesSection
                alertsSection
                recentSection
                poolInfoCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .overlay(alignment: .bottomTrailing) { addButton }
        .sheet(isPresented: $showAddReading) { AddReadingSheet() }
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: 12) {
            QualityScoreView(score: manager.qualityScore)
            Text(scoreLabel)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.sub)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }

    private var scoreLabel: String {
        let s = manager.qualityScore
        if s >= 90 { return "Excellent — your pool is in perfect condition!" }
        if s >= 75 { return "Good — minor adjustments may be needed" }
        if s >= 50 { return "Fair — some parameters need attention" }
        return "Poor — immediate action recommended"
    }

    // MARK: - Gauges

    private var gaugesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WATER PARAMETERS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.sub)
                .tracking(1.5)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach([WaterParameter.pH, .freeChlorine, .alkalinity, .cyanuricAcid, .calciumHardness, .temperature], id: \.self) { param in
                        ParameterGaugeView(
                            parameter: param,
                            value: param.value(from: manager.lastReading ?? WaterReading()),
                            size: 110
                        )
                        .glassCard(padding: 12, radius: 16)
                    }
                }
            }
        }
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        Group {
            if !manager.alerts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ALERTS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.sub)
                        .tracking(1.5)
                        .padding(.leading, 4)

                    ForEach(manager.alerts) { alert in
                        HStack(spacing: 12) {
                            Image(systemName: alert.status.icon)
                                .font(.system(size: 18))
                                .foregroundColor(alert.status.color)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.parameter.name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.text)
                                Text(alert.message)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(Theme.sub)
                            }
                            Spacer()
                            Text(alert.parameter == .pH ? String(format: "%.1f", alert.value) : String(format: "%.0f", alert.value))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(alert.status.color)
                        }
                        .accentCard(alert.status.color, padding: 14)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.safe)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Clear")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.text)
                        Text("All parameters are within ideal range")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Theme.sub)
                    }
                    Spacer()
                }
                .accentCard(Theme.safe)
            }
        }
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT READINGS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.sub)
                .tracking(1.5)
                .padding(.leading, 4)

            ForEach(Array(manager.sortedReadings.prefix(5))) { reading in
                readingRow(reading)
            }
        }
    }

    private func readingRow(_ r: WaterReading) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(r.date, style: .date)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text(r.date, style: .time)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Theme.sub)
            }
            Spacer()
            HStack(spacing: 8) {
                miniStat("pH", r.pH.map { String(format: "%.1f", $0) } ?? "--", WaterParameter.pH.color)
                miniStat("Cl", r.freeChlorine.map { String(format: "%.1f", $0) } ?? "--", WaterParameter.freeChlorine.color)
                miniStat("Alk", r.alkalinity.map { String(format: "%.0f", $0) } ?? "--", WaterParameter.alkalinity.color)
            }
        }
        .glassCard(padding: 12, radius: 14)
    }

    private func miniStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(Theme.dim)
        }
        .frame(width: 42)
    }

    // MARK: - Pool Info

    private var poolInfoCard: some View {
        HStack(spacing: 16) {
            Image(systemName: manager.pool.type.icon)
                .font(.system(size: 28))
                .foregroundStyle(Theme.gradient)
            VStack(alignment: .leading, spacing: 3) {
                Text(manager.pool.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text("\(String(format: "%.0f", manager.pool.volume)) \(manager.pool.volumeUnit.short) • \(manager.pool.type.rawValue) • \(manager.pool.surface.rawValue)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Theme.sub)
            }
            Spacer()
        }
        .glassCard(padding: 14, radius: 16)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button { showAddReading = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                Text("New Reading").font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Theme.gradient, in: Capsule(style: .continuous))
            .shadow(color: Theme.pool.opacity(0.4), radius: 12, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Add Reading Sheet

struct AddReadingSheet: View {
    @EnvironmentObject var manager: PoolManager
    @Environment(\.dismiss) var dismiss
    @State private var pH: String = ""
    @State private var freeChlorine: String = ""
    @State private var totalChlorine: String = ""
    @State private var alkalinity: String = ""
    @State private var cya: String = ""
    @State private var calcium: String = ""
    @State private var temperature: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        paramField("pH", icon: "drop.fill", color: WaterParameter.pH.color, text: $pH, hint: "7.2 - 7.6")
                        paramField("Free Chlorine (ppm)", icon: "shield.checkered", color: WaterParameter.freeChlorine.color, text: $freeChlorine, hint: "1.0 - 3.0")
                        paramField("Total Chlorine (ppm)", icon: "shield.fill", color: WaterParameter.totalChlorine.color, text: $totalChlorine, hint: "1.0 - 5.0")
                        paramField("Alkalinity (ppm)", icon: "water.waves", color: WaterParameter.alkalinity.color, text: $alkalinity, hint: "80 - 120")
                        paramField("CYA (ppm)", icon: "sun.max.fill", color: WaterParameter.cyanuricAcid.color, text: $cya, hint: "30 - 50")
                        paramField("Calcium (ppm)", icon: "diamond.fill", color: WaterParameter.calciumHardness.color, text: $calcium, hint: "200 - 400")
                        paramField("Temperature (°C)", icon: "thermometer.medium", color: WaterParameter.temperature.color, text: $temperature, hint: "25 - 28")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.sub)
                            TextField("Optional notes...", text: $notes)
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(Theme.text)
                                .padding(12)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.sub)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveReading() }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.pool)
                }
            }
            .toolbarBackground(Theme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func paramField(_ label: String, icon: String, color: Color, text: Binding<String>, hint: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.sub)
                TextField(hint, text: text)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.text)
                    .keyboardType(.decimalPad)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func saveReading() {
        let reading = WaterReading(
            pH: Double(pH),
            freeChlorine: Double(freeChlorine),
            totalChlorine: Double(totalChlorine),
            alkalinity: Double(alkalinity),
            cyanuricAcid: Double(cya),
            calciumHardness: Double(calcium),
            temperature: Double(temperature),
            notes: notes
        )
        manager.addReading(reading)
        dismiss()
    }
}
