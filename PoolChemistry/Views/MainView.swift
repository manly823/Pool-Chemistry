import SwiftUI

enum PoolTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case readings = "Readings"
    case calculator = "Calculator"
    case chemicals = "Chemicals"
    case settings = "Settings"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dashboard: return "drop.fill"
        case .readings: return "chart.line.uptrend.xyaxis"
        case .calculator: return "function"
        case .chemicals: return "flask.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainView: View {
    @EnvironmentObject var manager: PoolManager
    @State private var selectedTab: PoolTab = .dashboard
    @Namespace private var pillNS

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                pillBar
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                (Text("Pool")
                    .foregroundColor(Theme.text)
                 + Text(" Chemistry")
                    .foregroundColor(Theme.pool))
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                if let last = manager.lastReading {
                    Text("Last test: \(last.date, style: .relative) ago")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Theme.sub)
                }
            }
            Spacer()
            ZStack {
                Circle().fill(Theme.surface).frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                Text("\(manager.qualityScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(manager.qualityScore >= 80 ? Theme.safe :
                                        manager.qualityScore >= 50 ? Theme.warn : Theme.danger)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var pillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(PoolTab.allCases) { tab in
                    pillButton(tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func pillButton(_ tab: PoolTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedTab = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .semibold))
                if selectedTab == tab {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(selectedTab == tab ? .white : Theme.sub)
            .padding(.horizontal, selectedTab == tab ? 16 : 12)
            .padding(.vertical, 10)
            .background {
                if selectedTab == tab {
                    Capsule(style: .continuous)
                        .fill(Theme.gradient)
                        .shadow(color: Theme.pool.opacity(0.35), radius: 8, y: 2)
                        .matchedGeometryEffect(id: "pill", in: pillNS)
                } else {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .overlay(Capsule(style: .continuous).stroke(Theme.border, lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .dashboard: DashboardView()
        case .readings: ReadingsView()
        case .calculator: CalculatorView()
        case .chemicals: ChemicalsView()
        case .settings: SettingsView()
        }
    }
}
