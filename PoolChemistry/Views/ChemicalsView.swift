import SwiftUI

struct ChemicalsView: View {
    @EnvironmentObject var manager: PoolManager
    @State private var showAddChemical = false
    @State private var selectedCategory: ChemicalCategory?

    private var categories: [ChemicalCategory] {
        let present = Set(manager.chemicals.map(\.category))
        return ChemicalCategory.allCases.filter { present.contains($0) }
    }

    private func items(for cat: ChemicalCategory) -> [ChemicalItem] {
        manager.chemicals.filter { $0.category == cat }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCard
                categoryFilter
                chemicalsList
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .overlay(alignment: .bottomTrailing) {
            Button { showAddChemical = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Theme.gradient, in: Circle())
                    .shadow(color: Theme.pool.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.trailing, 20).padding(.bottom, 16)
        }
        .sheet(isPresented: $showAddChemical) { AddChemicalSheet() }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 20) {
            statBubble("\(manager.chemicals.count)", "Total", Theme.pool)
            statBubble("\(categories.count)", "Types", Theme.aqua)
            statBubble("\(manager.lowStockChemicals.count)", "Low", manager.lowStockChemicals.isEmpty ? Theme.safe : Theme.warn)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func statBubble(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Theme.sub)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", selected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(categories) { cat in
                    filterChip(cat.rawValue, icon: cat.icon, selected: selectedCategory == cat) { selectedCategory = cat }
                }
            }
        }
    }

    private func filterChip(_ label: String, icon: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.spring(response: 0.3)) { action() } } label: {
            HStack(spacing: 5) {
                if let ic = icon { Image(systemName: ic).font(.system(size: 11)) }
                Text(label).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1)
            }
            .foregroundColor(selected ? .white : Theme.sub)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.surface))
            .clipShape(Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).stroke(selected ? .clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - List

    private var chemicalsList: some View {
        let filteredCats = selectedCategory == nil ? categories : categories.filter { $0 == selectedCategory }
        return ForEach(filteredCats) { cat in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: cat.icon).font(.system(size: 12)).foregroundColor(Theme.pool)
                    Text(cat.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.sub)
                        .tracking(1)
                }
                .padding(.leading, 4)

                ForEach(items(for: cat)) { item in
                    chemicalRow(item)
                }
            }
        }
    }

    private func chemicalRow(_ item: ChemicalItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(stockColor(item).opacity(0.1))
                    .frame(width: 42, height: 42)
                Image(systemName: item.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(stockColor(item))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(formatRemaining(item))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(stockColor(item))
                    if let exp = item.expiryDate {
                        Text("Exp: \(exp, format: .dateTime.month(.abbreviated).year())")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(Theme.dim)
                    }
                }
            }
            Spacer()
            Button(role: .destructive) { withAnimation { manager.deleteChemical(item) } } label: {
                Image(systemName: "trash").font(.system(size: 12)).foregroundColor(Theme.dim)
            }
        }
        .glassCard(padding: 12, radius: 14)
    }

    private func formatRemaining(_ item: ChemicalItem) -> String {
        if item.unit == "L" { return String(format: "%.1f L remaining", item.amountRemaining) }
        if item.amountRemaining >= 1000 { return String(format: "%.1f kg remaining", item.amountRemaining / 1000) }
        return String(format: "%.0f g remaining", item.amountRemaining)
    }

    private func stockColor(_ item: ChemicalItem) -> Color {
        let isLow = (item.unit == "g" && item.amountRemaining < 500) || (item.unit == "L" && item.amountRemaining < 1)
        return isLow ? Theme.warn : Theme.safe
    }
}

// MARK: - Add Chemical Sheet

struct AddChemicalSheet: View {
    @EnvironmentObject var manager: PoolManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var category: ChemicalCategory = .sanitizer
    @State private var amount = ""
    @State private var unit = "g"
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        field("Chemical Name", text: $name, icon: "flask.fill")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.sub)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(ChemicalCategory.allCases) { cat in
                                    Button {
                                        withAnimation { category = cat }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon).font(.system(size: 12))
                                            Text(cat.rawValue).font(.system(size: 12, weight: .medium, design: .rounded)).lineLimit(1)
                                        }
                                        .foregroundColor(category == cat ? .white : Theme.sub)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(category == cat ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.surface))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(category == cat ? .clear : Theme.border, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            field("Amount", text: $amount, icon: "scalemass", keyboard: .decimalPad)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Unit")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.sub)
                                Picker("", selection: $unit) {
                                    Text("grams").tag("g")
                                    Text("liters").tag("L")
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        field("Notes", text: $notes, icon: "note.text")
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Chemical")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.sub)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = ChemicalItem(name: name, category: category,
                                                amountRemaining: Double(amount) ?? 0, unit: unit, notes: notes)
                        manager.addChemical(item)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.pool)
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
            .toolbarBackground(Theme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func field(_ label: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.sub)
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(Theme.pool).frame(width: 22)
                TextField(label, text: text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Theme.text)
                    .keyboardType(keyboard)
            }
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
        }
    }
}
