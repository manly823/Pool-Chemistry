import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: PoolManager
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                poolProfileSection
                scheduleSection
                dataSection
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { manager.resetAllData() }
        } message: {
            Text("This will restore sample data and clear all your readings and chemicals. This cannot be undone.")
        }
    }

    // MARK: - Pool Profile

    private var poolProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("POOL PROFILE", icon: "drop.circle")

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil").foregroundColor(Theme.pool).frame(width: 22)
                    TextField("Pool Name", text: $manager.pool.name)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.text)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))

                HStack(spacing: 12) {
                    Image(systemName: "ruler").foregroundColor(Theme.pool).frame(width: 22)
                    TextField("Volume", value: $manager.pool.volume, format: .number)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.text)
                        .keyboardType(.numberPad)
                    Picker("", selection: $manager.pool.volumeUnit) {
                        ForEach(VolumeUnit.allCases, id: \.self) { u in Text(u.rawValue).tag(u) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))

                HStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2").foregroundColor(Theme.pool).frame(width: 22)
                    Text("Type").font(.system(size: 14, design: .rounded)).foregroundColor(Theme.sub)
                    Spacer()
                    Picker("", selection: $manager.pool.type) {
                        ForEach(PoolType.allCases) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    .tint(Theme.pool)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))

                HStack(spacing: 12) {
                    Image(systemName: "square.3.layers.3d").foregroundColor(Theme.pool).frame(width: 22)
                    Text("Surface").font(.system(size: 14, design: .rounded)).foregroundColor(Theme.sub)
                    Spacer()
                    Picker("", selection: $manager.pool.surface) {
                        ForEach(SurfaceType.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                    .tint(Theme.pool)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("TESTING SCHEDULE", icon: "bell.badge")

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "clock").foregroundColor(Theme.aqua).frame(width: 22)
                    Text("Frequency").font(.system(size: 14, design: .rounded)).foregroundColor(Theme.sub)
                    Spacer()
                    Picker("", selection: $manager.frequency) {
                        ForEach(ReadingFrequency.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                    .tint(Theme.aqua)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))

                Toggle(isOn: $manager.notificationsEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill").foregroundColor(Theme.aqua).frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Reminders")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.text)
                            Text("Get notified when it's time to test")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Theme.sub)
                        }
                    }
                }
                .tint(Theme.pool)
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
                .onChange(of: manager.notificationsEnabled) { _, newVal in
                    if newVal { manager.requestNotificationPermission() }
                }
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DATA", icon: "externaldrive")

            VStack(spacing: 10) {
                infoRow("Readings", "\(manager.readings.count)", Theme.pool)
                infoRow("Chemicals", "\(manager.chemicals.count)", Theme.aqua)
                if let first = manager.sortedReadings.last {
                    infoRow("Since", first.date.formatted(.dateTime.month(.abbreviated).day().year()), Theme.safe)
                }

                Button { showResetConfirm = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise").foregroundColor(Theme.danger)
                        Text("Reset All Data")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.danger)
                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.danger.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.danger.opacity(0.15), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("ABOUT", icon: "info.circle")

            VStack(spacing: 0) {
                infoRow("App", "Pool Chemistry", Theme.pool)
                infoRow("Version", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", Theme.sub)
            }

            Text("Pool Chemistry helps you maintain crystal clear and safe pool water by tracking chemical parameters, calculating exact dosages, and keeping you on a consistent testing schedule. All data is stored locally on your device.")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Theme.dim)
                .lineSpacing(3)
                .padding(.top, 4)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(Theme.pool)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.sub)
                .tracking(1.5)
        }
        .padding(.leading, 4)
    }

    private func infoRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Theme.sub)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }
}
