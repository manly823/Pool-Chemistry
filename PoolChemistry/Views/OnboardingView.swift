import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var manager: PoolManager
    @State private var page = 0
    @State private var waveOffset: Double = 0

    private let pages: [(icon: String, title: String, desc: String, color: Color)] = [
        ("drop.circle.fill", "Pool Chemistry",
         "Your personal water quality lab. Monitor, analyze, and maintain crystal clear pool water with precision and ease.",
         Theme.pool),
        ("chart.line.uptrend.xyaxis", "Track Every Parameter",
         "Log pH, chlorine, alkalinity, CYA, calcium hardness and temperature. Watch trends over time with beautiful charts and smart gauges.",
         Color(red: 0.25, green: 0.82, blue: 0.52)),
        ("function", "Smart Dosage Calculator",
         "Enter your current and target values — get exact chemical amounts for your pool size. No guesswork, no overdosing.",
         Color(red: 0.95, green: 0.70, blue: 0.25)),
        ("bell.badge.fill", "Stay on Schedule",
         "Set your testing frequency and receive timely reminders. Consistent monitoring is the secret to a healthy pool.",
         Theme.aqua)
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            WaveShape(offset: waveOffset, amplitude: 12)
                .fill(Theme.pool.opacity(0.05))
                .ignoresSafeArea()
                .offset(y: 300)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        pageView(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                dotsIndicator
                    .padding(.bottom, 30)

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.spring(response: 0.4)) { page += 1 }
                    } else {
                        withAnimation { manager.onboardingDone = true }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(page == pages.count - 1 ? "Get Started" : "Continue")
                        Image(systemName: page == pages.count - 1 ? "checkmark" : "arrow.right")
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Theme.pool.opacity(0.3), radius: 12, y: 4)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)

                if page < pages.count - 1 {
                    Button("Skip") {
                        withAnimation { manager.onboardingDone = true }
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.sub)
                    .padding(.bottom, 20)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { waveOffset = .pi * 2 }
        }
    }

    private func pageView(_ p: (icon: String, title: String, desc: String, color: Color)) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(p.color.opacity(0.10)).frame(width: 160, height: 160).blur(radius: 30)
                Circle().fill(Theme.surface).frame(width: 130, height: 130)
                    .overlay(Circle().stroke(p.color.opacity(0.25), lineWidth: 2))
                Image(systemName: p.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [p.color, p.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .shadow(color: p.color.opacity(0.25), radius: 20)

            VStack(spacing: 12) {
                Text(p.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text(p.desc)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(Theme.sub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
            }
            Spacer()
            Spacer()
        }
    }

    private var dotsIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.pool : Theme.dim)
                    .frame(width: i == page ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
    }
}
