import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var selectedExamId = ""

    var exam: Exam? { store.exams.first { $0.id == selectedExamId } ?? store.exams.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Exam", selection: $selectedExamId) {
                        Text("Select exam").tag("")
                        ForEach(store.exams) { Text($0.name).tag($0.id) }
                    }
                    .pickerStyle(.menu)

                    if let exam {
                        content(exam)
                    } else {
                        EmptyStateView(title: "Choose an exam", message: "Select an exam to see class performance and difficult questions.", systemImage: "chart.bar.xaxis")
                    }
                }
                .padding()
            }
            .navigationTitle(store.isArabic ? "الإحصائيات" : "Statistics")
        }
        .onAppear { selectedExamId = selectedExamId.isEmpty ? (store.exams.first?.id ?? "") : selectedExamId }
    }

    func content(_ exam: Exam) -> some View {
        let rs = store.results(for: exam)
        let stats = StatisticsService.compute(exam: exam, results: rs)

        return VStack(alignment: .leading, spacing: 18) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(title: "Students", value: "\(stats.totalScanned)", icon: "person.3.fill", tint: .blue)
                MetricTile(title: "Average", value: String(format: "%.1f%%", stats.averagePercentage), icon: "chart.line.uptrend.xyaxis", tint: .green)
                MetricTile(title: "Highest", value: String(format: "%.1f", stats.highestScore), icon: "trophy.fill", tint: .orange)
                MetricTile(title: "Pass rate", value: String(format: "%.1f%%", stats.passRate), icon: "checkmark.seal.fill", tint: .purple)
            }

            Button {
                SharePresenter.share(text: CSVExportService.generateCSV(exam: exam, results: rs), filename: "SmartGrade_Results.csv")
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Text("Score distribution").font(.title2.bold())
            VStack(spacing: 10) {
                ForEach(stats.distribution) { item in
                    HStack {
                        Text(item.range).frame(width: 75, alignment: .leading)
                        ProgressView(value: item.percentage / 100)
                        Text("\(item.count)").font(.caption.monospacedDigit())
                    }
                }
            }

            Text("Question analysis").font(.title2.bold())
            VStack(spacing: 10) {
                ForEach(stats.questionAnalytics) { q in
                    HStack {
                        Text("Q\(q.questionNumber)").frame(width: 42, alignment: .leading)
                        ProgressView(value: q.correctPercentage / 100)
                            .tint(q.correctPercentage < 50 ? .red : .blue)
                        Text("\(String(format: "%.0f", q.correctPercentage))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 46, alignment: .trailing)
                    }
                }
            }
        }
    }
}
