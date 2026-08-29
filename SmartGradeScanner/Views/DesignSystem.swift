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
        case .scanner: return "camera.viewfinder"
        case .exams: return "book.closed.fill"
        case .students: return "person.3.fill"
        case .classrooms: return "building.columns.fill"
        case .analytics: return "chart.bar.xaxis"
        case .templates: return "square.grid.3x3.fill"
        }
    }
}

struct Palette {
    static let bgTop = Color(red: 5/255, green: 8/255, blue: 22/255)
    static let bgMid = Color(red: 12/255, green: 16/255, blue: 38/255)
    static let bgBottom = Color(red: 2/255, green: 6/255, blue: 23/255)
    static let surface = Color(red: 15/255, green: 23/255, blue: 42/255)
    static let surface2 = Color(red: 30/255, green: 41/255, blue: 59/255)
    static let glass = Color.white.opacity(0.075)
    static let stroke = Color.white.opacity(0.13)
    static let text = Color(red: 241/255, green: 245/255, blue: 249/255)
    static let muted = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let indigo = Color(red: 99/255, green: 102/255, blue: 241/255)
    static let cyan = Color(red: 34/255, green: 211/255, blue: 238/255)
    static let violet = Color(red: 168/255, green: 85/255, blue: 247/255)
    static let emerald = Color(red: 52/255, green: 211/255, blue: 153/255)
    static let rose = Color(red: 251/255, green: 113/255, blue: 133/255)
    static let amber = Color(red: 251/255, green: 191/255, blue: 36/255)
    static let slate900 = text
    static let slate600 = muted
    static let slate100 = surface2
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
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.12), Palette.indigo.opacity(0.055), Color.black.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(LinearGradient(colors: [Color.white.opacity(0.28), Palette.cyan.opacity(0.14), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: Palette.indigo.opacity(0.15), radius: 22, x: 0, y: 14)
            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    var color: Color = Palette.indigo
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(LinearGradient(colors: [color, Palette.violet.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.white.opacity(0.22), lineWidth: 1))
                .shadow(color: color.opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = Palette.indigo
    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.28), lineWidth: 1))
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
    var tint: Color { status.needsReview ? Palette.amber : status == .empty ? Palette.muted : Palette.emerald }
    var body: some View {
        Text(status.arabicTitle)
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(tint)
            .background(tint.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.32), lineWidth: 1))
    }
}

struct NeonDivider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, Palette.cyan.opacity(0.7), Palette.violet.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
    }
}

extension View {
    func pageBackground() -> some View {
        self.background(
            ZStack {
                LinearGradient(colors: [Palette.bgTop, Palette.bgMid, Palette.bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                Circle().fill(Palette.indigo.opacity(0.18)).blur(radius: 70).frame(width: 280, height: 280).offset(x: -150, y: -260)
                Circle().fill(Palette.cyan.opacity(0.10)).blur(radius: 85).frame(width: 330, height: 330).offset(x: 170, y: 60)
                Circle().fill(Palette.violet.opacity(0.12)).blur(radius: 90).frame(width: 300, height: 300).offset(x: -80, y: 420)
            }
        )
    }
}
