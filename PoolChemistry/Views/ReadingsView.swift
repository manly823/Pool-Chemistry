import SwiftUI

struct ReadingsView: View {
    @EnvironmentObject var manager: PoolManager
    @State private var showAddReading = false
    @State private var showChart = false
    @State private var selectedParam: WaterParameter = .pH

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                modeToggle
                if showChart { chartSection } else { listSection }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .overlay(alignment: .bottomTrailing) {
            Button { showAddReading = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Theme.gradient, in: Circle())
                    .shadow(color: Theme.pool.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.trailing, 20).padding(.bottom, 16)
        }
        .sheet(isPresented: $showAddReading) { AddReadingSheet() }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            toggleBtn("List", icon: "list.bullet", selected: !showChart) { showChart = false }
            toggleBtn("Charts", icon: "chart.xyaxis.line", selected: showChart) { showChart = true }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func toggleBtn(_ label: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { action() } }) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(label).font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(selected ? .white : Theme.sub)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? Theme.gradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - List

    private var listSection: some View {
        VStack(spacing: 10) {
            ForEach(manager.sortedReadings) { reading in
                readingCard(reading)
            }
        }
    }

    private func readingCard(_ r: WaterReading) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.text)
                    Text(r.date, format: .dateTime.hour().minute())
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Theme.sub)
                }
                Spacer()
                Button(role: .destructive) { withAnimation { manager.deleteReading(r) } } label: {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.dim)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                paramCell("pH", r.pH.map { String(format: "%.1f", $0) }, WaterParameter.pH)
                paramCell("Cl", r.freeChlorine.map { String(format: "%.1f", $0) }, WaterParameter.freeChlorine)
                paramCell("Alk", r.alkalinity.map { String(format: "%.0f", $0) }, WaterParameter.alkalinity)
                paramCell("CYA", r.cyanuricAcid.map { String(format: "%.0f", $0) }, WaterParameter.cyanuricAcid)
                paramCell("Ca", r.calciumHardness.map { String(format: "%.0f", $0) }, WaterParameter.calciumHardness)
                paramCell("Temp", r.temperature.map { String(format: "%.0f°", $0) }, WaterParameter.temperature)
            }

            if !r.notes.isEmpty {
                Text(r.notes)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Theme.sub)
                    .padding(.top, 2)
            }
        }
        .glassCard(padding: 14, radius: 16)
    }

    private func paramCell(_ label: String, _ value: String?, _ param: WaterParameter) -> some View {
        VStack(spacing: 3) {
            Text(value ?? "--")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(param.color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Theme.dim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(param.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Charts

    private var chartSection: some View {
        VStack(spacing: 16) {
            paramPicker
            chartCard
        }
    }

    private var paramPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([WaterParameter.pH, .freeChlorine, .alkalinity, .cyanuricAcid, .calciumHardness], id: \.self) { p in
                    Button {
                        withAnimation { selectedParam = p }
                    } label: {
                        Text(p.name)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedParam == p ? .white : Theme.sub)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedParam == p ? AnyShapeStyle(p.color) : AnyShapeStyle(Theme.surface))
                            .clipShape(Capsule(style: .continuous))
                            .overlay(Capsule(style: .continuous).stroke(selectedParam == p ? .clear : Theme.border, lineWidth: 1))
                    }
                }
            }
        }
    }

    private var chartCard: some View {
        let data = manager.chartData(for: selectedParam)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: selectedParam.icon)
                    .foregroundStyle(selectedParam.color)
                Text(selectedParam.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Spacer()
                if let last = data.last {
                    Text(selectedParam == .pH ? String(format: "%.1f", last.1) : String(format: "%.0f", last.1))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(selectedParam.color)
                    Text(selectedParam.unit)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Theme.sub)
                }
            }

            if data.count >= 2 {
                SimpleLineChart(
                    data: data.map { $0.1 },
                    color: selectedParam.color,
                    idealMin: selectedParam.idealMin,
                    idealMax: selectedParam.idealMax,
                    gaugeMin: selectedParam.gaugeMin,
                    gaugeMax: selectedParam.gaugeMax
                )
                .frame(height: 180)

                HStack {
                    Text("Ideal: \(selectedParam == .pH ? String(format: "%.1f", selectedParam.idealMin) : String(format: "%.0f", selectedParam.idealMin)) – \(selectedParam == .pH ? String(format: "%.1f", selectedParam.idealMax) : String(format: "%.0f", selectedParam.idealMax)) \(selectedParam.unit)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Theme.safe)
                    Spacer()
                    Text("\(data.count) readings")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Theme.sub)
                }
            } else {
                Text("Not enough data for chart. Add more readings.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Theme.sub)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            }
        }
        .glassCard()
    }
}

// MARK: - Simple Line Chart

struct SimpleLineChart: View {
    let data: [Double]
    let color: Color
    let idealMin: Double
    let idealMax: Double
    let gaugeMin: Double
    let gaugeMax: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minV = min(data.min() ?? gaugeMin, gaugeMin)
            let maxV = max(data.max() ?? gaugeMax, gaugeMax)
            let range = maxV - minV

            ZStack {
                let idealY1 = h - CGFloat((idealMin - minV) / range) * h
                let idealY2 = h - CGFloat((idealMax - minV) / range) * h
                Rectangle()
                    .fill(Theme.safe.opacity(0.06))
                    .frame(height: abs(idealY1 - idealY2))
                    .offset(y: min(idealY1, idealY2) - h / 2 + abs(idealY1 - idealY2) / 2)

                linePath(w: w, h: h, minV: minV, range: range)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                areaPath(w: w, h: h, minV: minV, range: range)
                    .fill(
                        LinearGradient(colors: [color.opacity(0.25), color.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                    )

                ForEach(Array(data.enumerated()), id: \.offset) { i, v in
                    let x = data.count > 1 ? CGFloat(i) / CGFloat(data.count - 1) * w : w / 2
                    let y = h - CGFloat((v - minV) / range) * h
                    Circle().fill(color).frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
    }

    private func linePath(w: CGFloat, h: CGFloat, minV: Double, range: Double) -> Path {
        var path = Path()
        for (i, v) in data.enumerated() {
            let x = data.count > 1 ? CGFloat(i) / CGFloat(data.count - 1) * w : w / 2
            let y = h - CGFloat((v - minV) / range) * h
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }

    private func areaPath(w: CGFloat, h: CGFloat, minV: Double, range: Double) -> Path {
        var path = linePath(w: w, h: h, minV: minV, range: range)
        let lastX = data.count > 1 ? w : w / 2
        path.addLine(to: CGPoint(x: lastX, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}
