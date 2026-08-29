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
        case .analytics: return ar ? "الإحصائيات" : "Statistics"
        case .templates: return ar ? "القوالب" : "Templates"
        }
    }
    var icon: String {
        switch self {
        case .scanner: return "camera.viewfinder"
        case .exams: return "list.clipboard.fill"
        case .students: return "person.3.fill"
        case .classrooms: return "person.2.fill"
        case .analytics: return "chart.bar.fill"
        case .templates: return "square.grid.3x3.fill"
        }
    }
}

struct Palette {
    static let text = Color.primary
    static let muted = Color.secondary
    static let surface = Color(.secondarySystemGroupedBackground)
    static let surface2 = Color(.tertiarySystemGroupedBackground)
    static let glass = Color(.secondarySystemGroupedBackground)
    static let stroke = Color(.separator).opacity(0.35)
    static let bgTop = Color(.systemGroupedBackground)
    static let bgMid = Color(.systemGroupedBackground)
    static let bgBottom = Color(.systemGroupedBackground)
    static let indigo = Color.accentColor
    static let indigoLight = Color.accentColor
    static let cyan = Color.blue
    static let violet = Color.purple
    static let emerald = Color.green
    static let rose = Color.red
    static let amber = Color.orange
    static let gold = Color.orange
    static let goldLight = Color.orange
    static let goldDark = Color.brown
    static let black = Color.black
    static let black2 = Color.black.opacity(0.85)
    static let obsidian = Color.black.opacity(0.92)
    static let panel = Color(.secondarySystemGroupedBackground)
    static let panel2 = Color(.tertiarySystemGroupedBackground)
    static let slate900 = Color.primary
    static let slate600 = Color.secondary
    static let slate100 = Color(.secondarySystemGroupedBackground)
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    var color: Color = .accentColor
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = .accentColor
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct StatusPill: View {
    let status: ResponseStatus
    private var label: String { status.arabicTitle }
    private var icon: String {
        switch status {
        case .selected: return "checkmark.circle.fill"
        case .empty: return "minus.circle"
        case .multiple: return "exclamationmark.triangle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    private var color: Color {
        switch status {
        case .selected: return .green
        case .empty: return .secondary
        case .multiple: return .red
        default: return .orange
        }
    }
    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct NeonDivider: View {
    var body: some View { Divider() }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}

extension View {
    func pageBackground() -> some View {
        self.background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
