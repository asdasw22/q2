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
    static let indigo = Color(red: 79/255, green: 70/255, blue: 229/255)
    static let slate900 = Color(red: 15/255, green: 23/255, blue: 42/255)
    static let slate600 = Color(red: 71/255, green: 85/255, blue: 105/255)
    static let slate100 = Color(red: 241/255, green: 245/255, blue: 249/255)
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
    static let rose = Color(red: 244/255, green: 63/255, blue: 94/255)
    static let amber = Color(red: 245/255, green: 158/255, blue: 11/255)
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.black.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

struct PrimaryButton: View {
    let title: String; let icon: String; var color: Color = Palette.indigo; let action: () -> Void
    var body: some View { Button(action: action) { Label(title, systemImage: icon).font(.headline).padding(.horizontal, 18).padding(.vertical, 12).foregroundStyle(.white).background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous)) }.buttonStyle(.plain) }
}

struct MetricTile: View {
    let title: String; let value: String; let icon: String; var tint: Color = Palette.indigo
    var body: some View {
        GlassCard(padding: 14) { HStack(spacing: 12) { Image(systemName: icon).font(.title2).foregroundStyle(tint).frame(width: 38, height: 38).background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading, spacing: 3) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.bold()).foregroundStyle(Palette.slate900) }; Spacer() } }
    }
}

struct StatusPill: View {
    let status: ResponseStatus
    var body: some View {
        Text(status.arabicTitle).font(.caption2.bold()).padding(.horizontal, 9).padding(.vertical, 5)
            .foregroundStyle(status.needsReview ? Palette.amber : status == .empty ? .secondary : Palette.emerald)
            .background((status.needsReview ? Palette.amber : status == .empty ? Color.gray : Palette.emerald).opacity(0.12), in: Capsule())
    }
}

extension View {
    func pageBackground() -> some View { self.background(LinearGradient(colors: [Color(red: 248/255, green: 250/255, blue: 252/255), Color(red: 238/255, green: 242/255, blue: 255/255)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()) }
}

