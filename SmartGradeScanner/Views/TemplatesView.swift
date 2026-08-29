import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject private var store: SmartGradeStore

    var body: some View {
        NavigationStack {
            List {
                if store.templates.isEmpty {
                    EmptyStateView(title: "No templates", message: "Default OMR templates will appear here.", systemImage: "square.grid.3x3")
                } else {
                    Section {
                        ForEach(store.templates) { template in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(template.name).font(.headline)
                                Text("Revision \(template.definition.revision) · \(template.definition.questionsCount) Questions · A4 Ratio \(template.definition.pageAspectRatio, specifier: "%.3f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Student ID: \(template.definition.studentID.columns)x\(template.definition.studentID.rows) · Threshold \(template.definition.calibration.fillRatioThreshold, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    } footer: {
                        Text("Standard templates from the original SmartGrade project.")
                    }
                }
            }
            .navigationTitle(store.isArabic ? "القوالب" : "Templates")
        }
    }
}
