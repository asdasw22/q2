import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var selectedExamId = ""

    var exam: Exam? {
        store.exams.first { $0.id == selectedExamId } ?? store.exams.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("لوحة التحليلات والإحصائيات التربوية")
                                .font(.title3.bold())
                            Text("مستوى صعوبة الأسئلة وتوزيع درجات الطلاب")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                if let exam {
                    content(exam)
                } else {
                    Text("لا توجد اختبارات")
                }
            }
            .padding()
        }
        .onAppear {
            selectedExamId = store.exams.first?.id ?? ""
        }
        .pageBackground()
    }

    func content(_ exam: Exam) -> some View {
        let rs = store.results(for: exam)
        let stats = StatisticsService.compute(exam: exam, results: rs)

        return VStack(spacing: 16) {
            Picker("الاختبار", selection: $selectedExamId) {
                ForEach(store.exams) {
                    Text($0.name).tag($0.id)
                }
            }
            .pickerStyle(.menu)

            HStack {
                PrimaryButton(
                    title: "CSV",
                    icon: "tablecells",
                    color: Palette.emerald
                ) {
                    SharePresenter.share(
                        text: CSVExportService.generateCSV(exam: exam, results: rs),
                        filename: "SmartGrade_Results.csv"
                    )
                }

                Spacer()
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 155))],
                spacing: 12
            ) {
                MetricTile(
                    title: "الأوراق",
                    value: "\(stats.totalScanned)",
                    icon: "doc.text"
                )

                MetricTile(
                    title: "المتوسط",
                    value: String(format: "%.1f%%", stats.averagePercentage),
                    icon: "chart.line.uptrend.xyaxis",
                    tint: Palette.emerald
                )

                MetricTile(
                    title: "نسبة النجاح",
                    value: String(format: "%.1f%%", stats.passRate),
                    icon: "checkmark.seal",
                    tint: Palette.indigo
                )

                MetricTile(
                    title: "أعلى/أدنى",
                    value: String(
                        format: "%.0f / %.0f",
                        stats.highestScore,
                        stats.lowestScore
                    ),
                    icon: "arrow.up.arrow.down",
                    tint: Palette.amber
                )
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("توزيع الدرجات")
                        .font(.headline)

                    ForEach(stats.distribution) { item in
                        HStack {
                            Text(item.range)
                                .frame(width: 75, alignment: .leading)

                            ProgressView(value: item.percentage / 100)
                                .tint(Palette.indigo)

                            Text("\(item.count)")
                                .font(.caption.bold())
                        }
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("تحليل الأسئلة")
                        .font(.headline)

                    ForEach(stats.questionAnalytics) { q in
                        HStack {
                            Text("Q\(q.questionNumber)")
                                .font(.caption.bold())
                                .frame(width: 42)

                            ProgressView(value: q.correctPercentage / 100)
                                .tint(
                                    q.correctPercentage < 40
                                    ? Palette.rose
                                    : Palette.emerald
                                )

                            Text(
                                "\(String(format: "%.0f", q.correctPercentage))% • \(q.difficulty)"
                            )
                            .font(.caption)
                            .frame(width: 90, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}
