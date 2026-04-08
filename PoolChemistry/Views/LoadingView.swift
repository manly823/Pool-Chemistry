import SwiftUI

// MARK: - Loading View (Pool Chemistry Theme)
struct LoadingView: View {
    let message: String

    @State private var dropAnimation: CGFloat = 0
    @State private var waveOffset: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Theme.bg, Color(red: 0.04, green: 0.10, blue: 0.22), Theme.bg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                backgroundElements()

                VStack(spacing: 30) {
                    Spacer()

                    dropIcon()

                    waveIndicator()
                        .padding(.top, -10)

                    VStack(spacing: 16) {
                        Text(message)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.gradient)

                        PoolLoadingDotsView()
                    }

                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Background Elements
    private func backgroundElements() -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: "drop.fill")
                    .font(.system(size: CGFloat.random(in: 14...24)))
                    .foregroundColor(Theme.pool.opacity(Double.random(in: 0.1...0.25)))
                    .offset(
                        x: CGFloat([-150, 140, -100, 160, -130, 120][index]),
                        y: CGFloat([-280, -180, 260, 300, -120, 180][index])
                    )
                    .rotationEffect(.degrees(Double(index * 60)))
            }

            ForEach(0..<8, id: \.self) { _ in
                Circle()
                    .fill(Theme.aqua.opacity(Double.random(in: 0.05...0.15)))
                    .frame(width: CGFloat.random(in: 4...10), height: CGFloat.random(in: 4...10))
                    .offset(
                        x: CGFloat.random(in: -170...170),
                        y: CGFloat.random(in: -350...350)
                    )
                    .scaleEffect(pulseScale)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.pool.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(y: -50)
                .opacity(glowOpacity + 0.3)
        }
    }

    // MARK: - Drop Icon
    private func dropIcon() -> some View {
        ZStack {
            Circle()
                .stroke(Theme.gradient, lineWidth: 4)
                .frame(width: 160, height: 160)
                .shadow(color: Theme.pool.opacity(0.5), radius: 15)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.surface.opacity(0.8), Theme.deep.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 130, height: 130)

            Image(systemName: "drop.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(Theme.aquaGrad)
                .shadow(color: Theme.pool.opacity(0.8), radius: 15)
                .offset(y: dropAnimation)

            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.aqua)
                    .offset(y: -85)
                    .rotationEffect(.degrees(Double(index) * 90 + waveOffset * 18))
                    .scaleEffect(pulseScale)
            }
        }
    }

    // MARK: - Wave Indicator
    private func waveIndicator() -> some View {
        HStack(spacing: 20) {
            ForEach(0..<5, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(Theme.pool.opacity(0.2))
                        .frame(width: 35, height: 35)
                        .blur(radius: 5)

                    Circle()
                        .fill(Theme.gradient)
                        .frame(width: 25, height: 25)
                        .shadow(color: Theme.pool.opacity(0.6), radius: 8)
                        .scaleEffect(waveOffset > Double(index) / 5.0 * 20 ? 1.0 : 0.6)
                        .opacity(waveOffset > Double(index) / 5.0 * 20 ? 1.0 : 0.4)
                }
            }
        }
    }

    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            dropAnimation = -12
        }
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            waveOffset = 20
        }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.7
        }
    }
}

// MARK: - Pool Loading Dots View
struct PoolLoadingDotsView: View {
    @State private var animatingDots = [false, false, false]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.gradient)
                    .frame(width: 12, height: 12)
                    .scaleEffect(animatingDots[index] ? 1.4 : 0.8)
                    .opacity(animatingDots[index] ? 1 : 0.5)
                    .shadow(color: Theme.pool.opacity(0.5), radius: 5)
            }
        }
        .onAppear {
            for index in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        animatingDots[index] = true
                    }
                }
            }
        }
    }
}
