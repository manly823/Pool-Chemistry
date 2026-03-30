import SwiftUI

struct Theme {
    static let bg = Color(red: 0.02, green: 0.04, blue: 0.10)
    static let surface = Color(red: 0.05, green: 0.08, blue: 0.16)
    static let card = Color.white.opacity(0.04)
    static let border = Color.white.opacity(0.07)

    static let pool = Color(red: 0.15, green: 0.65, blue: 0.88)
    static let aqua = Color(red: 0.10, green: 0.82, blue: 0.78)
    static let deep = Color(red: 0.12, green: 0.35, blue: 0.72)
    static let safe = Color(red: 0.25, green: 0.82, blue: 0.52)
    static let warn = Color(red: 0.95, green: 0.75, blue: 0.22)
    static let danger = Color(red: 0.92, green: 0.30, blue: 0.30)

    static let text = Color.white.opacity(0.92)
    static let sub = Color.white.opacity(0.50)
    static let dim = Color.white.opacity(0.25)

    static let gradient = LinearGradient(colors: [pool, deep], startPoint: .leading, endPoint: .trailing)
    static let aquaGrad = LinearGradient(colors: [aqua, pool], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let waterGrad = LinearGradient(colors: [
        Color(red: 0.05, green: 0.15, blue: 0.35),
        Color(red: 0.02, green: 0.08, blue: 0.22)
    ], startPoint: .top, endPoint: .bottom)
}

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content.padding(padding)
            .background(.ultraThinMaterial.opacity(0.25))
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }
}

struct AccentCard: ViewModifier {
    let color: Color
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content.padding(padding)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color.opacity(0.18), lineWidth: 1))
    }
}

struct WaveShape: Shape {
    var offset: Double
    var amplitude: Double = 8
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let mid = h * 0.5
        p.move(to: CGPoint(x: 0, y: mid))
        for x in stride(from: 0, through: w, by: 2) {
            let y = mid + Foundation.sin((x / w * 2 * .pi) + offset) * amplitude
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

struct GaugeArc: Shape {
    var startAngle: Double = -225
    var endAngle: Double = 45
    var lineWidth: CGFloat = 10
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: rect.width / 2 - lineWidth / 2,
                 startAngle: .degrees(startAngle),
                 endAngle: .degrees(endAngle),
                 clockwise: false)
        return p
    }
}

struct ParameterGaugeView: View {
    let parameter: WaterParameter
    let value: Double?
    var size: CGFloat = 130

    private var fraction: Double {
        guard let v = value else { return 0 }
        let clamped = min(max(v, parameter.gaugeMin), parameter.gaugeMax)
        return (clamped - parameter.gaugeMin) / (parameter.gaugeMax - parameter.gaugeMin)
    }

    private var status: ParameterStatus {
        guard let v = value else { return .warning }
        return parameter.status(for: v)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                GaugeArc(lineWidth: 8)
                    .stroke(Theme.dim, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: size, height: size)

                GaugeArc(endAngle: -225 + fraction * 270, lineWidth: 8)
                    .stroke(
                        AngularGradient(
                            colors: [parameter.color.opacity(0.5), parameter.color],
                            center: .center,
                            startAngle: .degrees(-225),
                            endAngle: .degrees(-225 + fraction * 270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: size, height: size)

                VStack(spacing: 2) {
                    Image(systemName: parameter.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(parameter.color)
                    if let v = value {
                        Text(parameter == .pH ? String(format: "%.1f", v) : String(format: "%.0f", v))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.text)
                    } else {
                        Text("--")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.dim)
                    }
                    Text(parameter.unit)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.sub)
                }
            }
            .shadow(color: status.color.opacity(0.3), radius: 8)

            Text(parameter.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Theme.sub)

            HStack(spacing: 4) {
                Circle().fill(status.color).frame(width: 6, height: 6)
                Text(status.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(status.color)
            }
        }
    }
}

struct QualityScoreView: View {
    let score: Int
    @State private var animatedFraction: Double = 0
    @State private var waveOffset: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.dim, lineWidth: 6)
                .frame(width: 140, height: 140)

            Circle()
                .trim(from: 0, to: animatedFraction)
                .stroke(scoreGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(Theme.surface)
                .frame(width: 120, height: 120)
                .overlay(
                    WaveShape(offset: waveOffset, amplitude: 5)
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                )

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text("QUALITY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.sub)
                    .tracking(2)
            }
        }
        .shadow(color: scoreColor.opacity(0.3), radius: 15)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { animatedFraction = Double(score) / 100.0 }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { waveOffset = .pi * 2 }
        }
    }

    private var scoreColor: Color {
        if score >= 80 { return Theme.safe }
        if score >= 50 { return Theme.warn }
        return Theme.danger
    }

    private var scoreGradient: AngularGradient {
        AngularGradient(colors: [scoreColor.opacity(0.3), scoreColor], center: .center)
    }
}

extension View {
    func glassCard(padding: CGFloat = 16, radius: CGFloat = 20) -> some View {
        modifier(GlassCard(padding: padding, radius: radius))
    }
    func accentCard(_ color: Color, padding: CGFloat = 16) -> some View {
        modifier(AccentCard(color: color, padding: padding))
    }
}
