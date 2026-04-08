import SwiftUI

// MARK: - Gambling Theme Colors
private struct GamblingTheme {
    static let darkBackground = Color(red: 0.08, green: 0.05, blue: 0.15)
    static let purple = Color(red: 0.4, green: 0.2, blue: 0.6)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let brightGold = Color(red: 1.0, green: 0.9, blue: 0.4)
    static let red = Color(red: 0.9, green: 0.2, blue: 0.3)
    static let hotPink = Color(red: 1.0, green: 0.2, blue: 0.5)
    static let neonPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
}

// MARK: - Push Permission View
struct PushPermissionView: View {
    let onAccept: () -> Void
    let onSkip: () -> Void

    @State private var isAnimating = false
    @State private var bellOffset: CGFloat = 0
    @State private var starRotation: Double = 0
    @State private var coinScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        GamblingTheme.darkBackground,
                        Color(red: 0.12, green: 0.08, blue: 0.25),
                        GamblingTheme.darkBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                backgroundElements()

                if isLandscape {
                    landscapeContent(geometry: geometry)
                } else {
                    portraitContent(geometry: geometry)
                }
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Background Elements
    private func backgroundElements() -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: CGFloat.random(in: 8...20)))
                    .foregroundColor(GamblingTheme.gold.opacity(Double.random(in: 0.1...0.3)))
                    .offset(
                        x: CGFloat.random(in: -180...180),
                        y: CGFloat.random(in: -350...350)
                    )
                    .rotationEffect(.degrees(starRotation + Double(index * 30)))
            }

            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [GamblingTheme.brightGold, GamblingTheme.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 15...25), height: CGFloat.random(in: 15...25))
                    .overlay(
                        Text("$")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.0))
                    )
                    .offset(
                        x: CGFloat([-150, 160, -130, 140, -100, 120][index]),
                        y: CGFloat([-280, -200, 250, 300, -100, 150][index])
                    )
                    .scaleEffect(coinScale)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [GamblingTheme.gold.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: -50)
                .opacity(glowOpacity)
        }
    }

    // MARK: - Portrait Layout
    private func portraitContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            notificationIcon(size: .large).padding(.bottom, 40)
            textContent()
            Spacer()
            buttonsSection().padding(.horizontal, 30).padding(.bottom, 50)
        }
    }

    // MARK: - Landscape Layout
    private func landscapeContent(geometry: GeometryProxy) -> some View {
        HStack(spacing: 20) {
            notificationIcon(size: .small)
                .frame(maxWidth: geometry.size.width * 0.35)
            VStack(spacing: 16) {
                Spacer()
                textContent(compact: true)
                Spacer()
                buttonsSection(compact: true).padding(.bottom, 20)
            }
            .frame(maxWidth: geometry.size.width * 0.55)
            .padding(.trailing, 20)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Notification Icon
    enum IconSize {
        case large, small
        var outerCircle: CGFloat { self == .large ? 220 : 140 }
        var innerCircle: CGFloat { self == .large ? 160 : 100 }
        var bellCircle: CGFloat { self == .large ? 100 : 65 }
        var bellFont: CGFloat { self == .large ? 42 : 28 }
        var badgeSize: CGFloat { self == .large ? 32 : 22 }
        var badgeOffset: CGFloat { self == .large ? 38 : 24 }
    }

    private func notificationIcon(size: IconSize) -> some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [GamblingTheme.gold.opacity(0.5), GamblingTheme.hotPink.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size.outerCircle, height: size.outerCircle)
                .blur(radius: 2)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [GamblingTheme.purple.opacity(0.4), GamblingTheme.neonPurple.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.innerCircle, height: size.innerCircle)

            ForEach(0..<6, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size == .large ? 16 : 10))
                    .foregroundColor(GamblingTheme.gold)
                    .offset(y: -(size.innerCircle / 2 + 20))
                    .rotationEffect(.degrees(Double(index) * 60 + starRotation))
            }

            ZStack {
                Circle()
                    .fill(GamblingTheme.gold.opacity(0.3))
                    .frame(width: size.bellCircle + 20, height: size.bellCircle + 20)
                    .blur(radius: 15)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [GamblingTheme.brightGold, GamblingTheme.gold, Color(red: 0.7, green: 0.5, blue: 0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.bellCircle, height: size.bellCircle)
                    .shadow(color: GamblingTheme.gold.opacity(0.6), radius: 15)

                Image(systemName: "bell.fill")
                    .font(.system(size: size.bellFont, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 1.0, green: 0.95, blue: 0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                    .rotationEffect(.degrees(bellOffset))
            }

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [GamblingTheme.red, GamblingTheme.hotPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.badgeSize, height: size.badgeSize)
                    .shadow(color: GamblingTheme.red.opacity(0.8), radius: 8)

                Text("🎰")
                    .font(.system(size: size.badgeSize * 0.55))
            }
            .offset(x: size.badgeOffset, y: -size.badgeOffset)
            .scaleEffect(isAnimating ? 1.15 : 1.0)
        }
    }

    // MARK: - Text Content
    private func textContent(compact: Bool = false) -> some View {
        VStack(spacing: compact ? 8 : 16) {
            HStack(spacing: 8) {
                Text("🎁")
                    .font(.system(size: compact ? 24 : 30))
                Text("EXCLUSIVE BONUSES")
                    .font(compact ? .title3 : .title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GamblingTheme.brightGold, GamblingTheme.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("🎁")
                    .font(.system(size: compact ? 24 : 30))
            }

            Text("Enable notifications to receive\nFREE SPINS, BONUSES & VIP OFFERS!")
                .font(compact ? .subheadline : .body)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, compact ? 10 : 30)
                .lineSpacing(compact ? 2 : 6)
        }
    }

    // MARK: - Buttons Section
    private func buttonsSection(compact: Bool = false) -> some View {
        VStack(spacing: compact ? 10 : 16) {
            Button(action: onAccept) {
                HStack(spacing: 12) {
                    Text("🔔")
                        .font(.system(size: compact ? 20 : 24))
                    Text("GET MY BONUSES!")
                        .font(compact ? .headline : .title3)
                        .fontWeight(.heavy)
                }
                .foregroundColor(GamblingTheme.darkBackground)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 50 : 60)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [GamblingTheme.brightGold, GamblingTheme.gold, Color(red: 0.85, green: 0.65, blue: 0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .cornerRadius(compact ? 14 : 18)
                .shadow(color: GamblingTheme.gold.opacity(0.6), radius: 15, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 14 : 18)
                        .stroke(GamblingTheme.brightGold.opacity(0.5), lineWidth: 2)
                )
            }
            .scaleEffect(isAnimating ? 1.02 : 1.0)

            Button(action: onSkip) {
                Text("Skip")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 32 : 44)
            }
        }
    }

    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.12).repeatCount(8, autoreverses: true)) {
            bellOffset = 18
        }
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            bellOffset = 0
            withAnimation(.easeInOut(duration: 0.12).repeatCount(8, autoreverses: true)) {
                bellOffset = 18
            }
        }
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            starRotation = 360
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            coinScale = 1.2
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
    }
}
