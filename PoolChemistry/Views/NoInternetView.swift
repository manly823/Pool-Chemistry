import SwiftUI

// MARK: - No Internet View (Pool Chemistry Theme)
struct NoInternetView: View {
    let onRetry: () -> Void

    @State private var isAnimating = false
    @State private var bubbleOffset: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Theme.bg, Color(red: 0.04, green: 0.10, blue: 0.22), Theme.bg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Decorative background
                ZStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(Theme.pool.opacity(0.1))
                        .rotationEffect(.degrees(-15))
                        .offset(x: -120, y: -250)

                    Image(systemName: "drop.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(Theme.aqua.opacity(0.08))
                        .rotationEffect(.degrees(15))
                        .offset(x: 130, y: 280)
                }

                VStack(spacing: 30) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.surface.opacity(0.5))
                            .frame(width: 180, height: 180)

                        Circle()
                            .fill(Theme.card)
                            .frame(width: 140, height: 140)

                        // Bubbles
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(Theme.pool.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .offset(y: -80)
                                .rotationEffect(.degrees(Double(index) * 90 + bubbleOffset))
                        }

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.surface, Theme.deep.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "wifi.slash")
                            .font(.system(size: 45, weight: .medium))
                            .foregroundColor(Theme.pool)
                            .offset(y: isAnimating ? -3 : 3)
                    }

                    VStack(spacing: 16) {
                        Text("No Internet Connection")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.text)

                        Text("Please check your connection to continue using Pool Chemistry!")
                            .font(.body)
                            .foregroundColor(Theme.sub)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                bubbleOffset = 360
            }
        }
    }
}
