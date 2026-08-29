import SwiftUI
import UIKit

enum SGTab: String, CaseIterable, Identifiable {
    case scanner, exams, students, classrooms, analytics, templates
    var id: String { rawValue }
    func title(ar: Bool) -> String {
        switch self {
        case .scanner: return ar ? "المسح" : "Scan"
        case .exams: return ar ? "الاختبارات" : "Exams"
        case .students: return ar ? "الطلاب" : "Students"
        case .classrooms: return ar ? "الصفوف" : "Classes"
        case .analytics: return ar ? "التحليلات" : "Analytics"
        case .templates: return ar ? "القوالب" : "Templates"
        }
    }
    var icon: String {
        switch self {
        case .scanner: return "viewfinder"
        case .exams: return "book.closed.fill"
        case .students: return "person.3.fill"
        case .classrooms: return "building.columns.fill"
        case .analytics: return "chart.bar.xaxis"
        case .templates: return "square.grid.3x3.fill"
        }
    }
}

struct Palette {
    static let black = Color(red: 3/255, green: 3/255, blue: 6/255)
    static let black2 = Color(red: 9/255, green: 10/255, blue: 16/255)
    static let obsidian = Color(red: 14/255, green: 14/255, blue: 22/255)
    static let panel = Color(red: 20/255, green: 19/255, blue: 27/255)
    static let panel2 = Color(red: 30/255, green: 28/255, blue: 39/255)
    static let gold = Color(red: 212/255, green: 175/255, blue: 55/255)
    static let goldLight = Color(red: 255/255, green: 222/255, blue: 124/255)
    static let goldDark = Color(red: 129/255, green: 98/255, blue: 28/255)
    static let indigo = Color(red: 46/255, green: 38/255, blue: 128/255)
    static let indigoLight = Color(red: 93/255, green: 80/255, blue: 198/255)
    static let text = Color(red: 249/255, green: 246/255, blue: 235/255)
    static let muted = Color(red: 170/255, green: 160/255, blue: 135/255)
    static let stroke = Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.22)
    static let glass = Color(red: 255/255, green: 240/255, blue: 190/255).opacity(0.055)
    static let emerald = Color(red: 42/255, green: 157/255, blue: 116/255)
    static let rose = Color(red: 190/255, green: 64/255, blue: 82/255)
    static let amber = goldLight
    static let cyan = gold
    static let violet = indigoLight
    static let slate900 = text
    static let slate600 = muted
    static let slate100 = panel2
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .foregroundStyle(Palette.text)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.panel.opacity(0.94), Palette.black2.opacity(0.98)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.gold.opacity(0.10), .clear, Palette.indigo.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(LinearGradient(colors: [Palette.goldLight.opacity(0.36), Palette.gold.opacity(0.18), Palette.indigoLight.opacity(0.28)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.55), radius: 18, x: 0, y: 12)
            .shadow(color: Palette.gold.opacity(0.08), radius: 20, x: 0, y: 4)
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    var color: Color = Palette.gold
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .foregroundStyle(Palette.black)
                .background(LinearGradient(colors: [Palette.goldLight, Palette.gold, Palette.goldDark], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.24), lineWidth: 1))
                .shadow(color: Palette.gold.opacity(0.28), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = Palette.gold
    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(LinearGradient(colors: [Palette.indigo.opacity(0.55), Palette.black2], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.gold.opacity(0.26), lineWidth: 1))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.caption.weight(.semibold)).foregroundStyle(Palette.muted)
                    Text(value).font(.title3.bold()).foregroundStyle(Palette.text)
                }
                Spacer()
            }
        }
    }
}

struct StatusPill: View {
    let status: ResponseStatus
    var tint: Color { status.needsReview ? Palette.goldLight : status == .empty ? Palette.muted : Palette.emerald }
    var body: some View {
        Text(status.arabicTitle)
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.30), lineWidth: 1))
    }
}

struct NeonDivider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, Palette.gold.opacity(0.78), Palette.indigoLight.opacity(0.50), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
    }
}

extension View {
    func pageBackground() -> some View {
        self.background(
            ZStack {
                LinearGradient(colors: [Palette.black, Palette.black2, Palette.obsidian], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                Circle().fill(Palette.gold.opacity(0.10)).blur(radius: 85).frame(width: 310, height: 310).offset(x: -160, y: -280)
                Circle().fill(Palette.indigo.opacity(0.22)).blur(radius: 95).frame(width: 360, height: 360).offset(x: 180, y: 20)
                Circle().fill(Palette.goldDark.opacity(0.10)).blur(radius: 110).frame(width: 360, height: 360).offset(x: -100, y: 470)
            }
        )
    }
}
