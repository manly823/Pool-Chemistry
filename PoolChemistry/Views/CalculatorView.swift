import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject var manager: PoolManager
    @State private var selectedParam: WaterParameter = .pH
    @State private var currentValue: String = ""
    @State private var targetValue: String = ""
    @State private var results: [DosageResult] = []
    @State private var hasCalculated = false

    private let adjustableParams: [WaterParameter] = [.pH, .freeChlorine, .alkalinity, .cyanuricAcid, .calciumHardness]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                infoCard
                parameterSelector
                inputSection
                calculateButton
                if hasCalculated { resultsSection }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Info

    private var infoCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.pool.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: "function")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.gradient)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Dosage Calculator")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text("Select a parameter, enter values, and get exact chemical amounts for your \(String(format: "%.0f", manager.pool.volume)) \(manager.pool.volumeUnit.short) pool.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Theme.sub)
                    .lineSpacing(2)
            }
        }
        .glassCard(padding: 14, radius: 16)
    }

    // MARK: - Parameter Selector

    private var parameterSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARAMETER")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.sub)
                .tracking(1.5)
                .padding(.leading, 4)

            VStack(spacing: 6) {
                ForEach(adjustableParams) { param in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedParam = param
                            prefillCurrent()
                            hasCalculated = false
                            results = []
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: param.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(param.color)
                                .frame(width: 28)
                            Text(param.name)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedParam == param ? Theme.text : Theme.sub)
                            Spacer()
                            Text("Ideal: \(param == .pH ? String(format: "%.1f–%.1f", param.idealMin, param.idealMax) : String(format: "%.0f–%.0f", param.idealMin, param.idealMax))\(param.unit.isEmpty ? "" : " \(param.unit)")")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Theme.dim)
                            if selectedParam == param {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(param.color)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(12)
                        .background(selectedParam == param ? param.color.opacity(0.08) : Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selectedParam == param ? param.color.opacity(0.2) : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        HStack(spacing: 12) {
            valueField("Current", text: $currentValue, color: Theme.warn)
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.dim)
            valueField("Target", text: $targetValue, color: Theme.safe)
        }
    }

    private func valueField(_ label: String, text: Binding<String>, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.sub)
            TextField(selectedParam == .pH ? "7.4" : "100", text: text)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.3), lineWidth: 1.5))
            Text(selectedParam.unit.isEmpty ? "value" : selectedParam.unit)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(Theme.dim)
        }
    }

    // MARK: - Calculate

    private var calculateButton: some View {
        Button {
            calculate()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "beaker").font(.system(size: 16, weight: .semibold))
                Text("Calculate Dosage").font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.pool.opacity(0.3), radius: 10, y: 4)
        }
        .disabled(currentValue.isEmpty || targetValue.isEmpty)
        .opacity(currentValue.isEmpty || targetValue.isEmpty ? 0.5 : 1.0)
    }

    private func calculate() {
        guard let current = Double(currentValue), let target = Double(targetValue) else { return }
        withAnimation(.spring(response: 0.4)) {
            results = manager.calculateDosage(parameter: selectedParam, currentValue: current, targetValue: target)
            hasCalculated = true
        }
    }

    private func prefillCurrent() {
        guard let last = manager.lastReading else { return }
        if let v = selectedParam.value(from: last) {
            currentValue = selectedParam == .pH ? String(format: "%.1f", v) : String(format: "%.0f", v)
        }
        let mid = (selectedParam.idealMin + selectedParam.idealMax) / 2
        targetValue = selectedParam == .pH ? String(format: "%.1f", mid) : String(format: "%.0f", mid)
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if results.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.safe)
                        .font(.system(size: 22))
                    Text("No adjustment needed — values are already at target or can only be changed by dilution.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Theme.sub)
                }
                .glassCard(padding: 14, radius: 14)
            } else {
                Text("RECOMMENDED TREATMENT")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.sub)
                    .tracking(1.5)
                    .padding(.leading, 4)

                ForEach(results) { result in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "flask.fill")
                                .foregroundStyle(selectedParam.color)
                            Text(result.chemical)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.text)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(formatAmount(result.amount))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(selectedParam.color)
                            Text(result.unit)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.sub)
                        }

                        Text(result.instructions)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Theme.sub)
                            .lineSpacing(2)
                    }
                    .accentCard(selectedParam.color, padding: 16)
                }
            }
        }
    }

    private func formatAmount(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.1f", v / 1000) + "k" }
        if v >= 100 { return String(format: "%.0f", v) }
        if v >= 10 { return String(format: "%.1f", v) }
        return String(format: "%.2f", v)
    }
}
