import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject private var store: SmartGradeStore
    var body: some View { ScrollView { VStack(spacing: 16) { GlassCard { VStack(alignment: .leading, spacing: 6) { Text("قوالب OMR القياسية").font(.title3.bold()); Text("نفس قوالب المشروع الأصلي: 20 سؤال و50 سؤال، شبكة رقم طالب 9 خانات، علامات تسجيل زوايا، وعتبات معايرة.").font(.caption).foregroundStyle(.secondary) } }; ForEach(store.templates) { t in GlassCard { VStack(alignment: .leading, spacing: 10) { Text(t.name).font(.headline); Text("Revision \(t.definition.revision) • \(t.definition.questionsCount) Questions • A4 Ratio \(t.definition.pageAspectRatio, specifier: "%.3f")").font(.caption).foregroundStyle(.secondary); HStack { Text("Student ID: \(t.definition.studentID.columns)x\(t.definition.studentID.rows)"); Spacer(); Text("Threshold \(t.definition.calibration.fillRatioThreshold, specifier: "%.2f")") }.font(.caption.bold()) } }.padding(.horizontal) } }.padding(.vertical) }.pageBackground() }
}

