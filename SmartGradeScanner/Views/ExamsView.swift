import SwiftUI

struct ExamsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    let onScan: (String) -> Void
    @State private var search = ""
    @State private var showingCreate = false

    var filtered: [Exam] {
        store.exams.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.subject.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    EmptyStateView(title: "No exams", message: "Create an exam and add its answer key to start scanning.", systemImage: "doc.text.magnifyingglass")
                } else {
                    List {
                        ForEach(filtered) { exam in
                            examRow(exam)
                                .swipeActions {
                                    Button(role: .destructive) { store.deleteExam(exam.id) } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    }
                    .searchable(text: $search, prompt: "Search exams")
                }
            }
            .navigationTitle(store.isArabic ? "الاختبارات" : "Exams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreate) { CreateExamView() }
        }
    }

    private func examRow(_ exam: Exam) -> some View {
        let rs = store.results(for: exam)
        let avg = rs.isEmpty ? 0 : rs.map(\.percentage).reduce(0, +) / Double(rs.count)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.name).font(.headline)
                    Text("\(exam.subject) · \(exam.questions.count) questions").font(.subheadline).foregroundStyle(.secondary)
                    Text(exam.date, style: .date).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(rs.count)").font(.headline.monospacedDigit())
                    Text("scans").font(.caption).foregroundStyle(.secondary)
                    if !rs.isEmpty { Text("Avg \(avg, specifier: "%.0f")%").font(.caption).foregroundStyle(.secondary) }
                }
            }
            Button { onScan(exam.id) } label: { Label("Scan", systemImage: "camera.viewfinder") }
                .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }
}

struct CreateExamView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var subject = ""
    @State private var questionCount = 20
    @State private var weight = 1.0
    @State private var answers: [Int: AnswerChoice] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section("Exam details") {
                    TextField("Exam name", text: $name)
                    TextField("Subject", text: $subject)
                    Picker("Questions", selection: $questionCount) {
                        Text("20 questions").tag(20)
                        Text("50 questions").tag(50)
                    }
                    Stepper("Question weight: \(weight, specifier: "%.1f")", value: $weight, in: 0.5...10, step: 0.5)
                }
                Section("Answer key") {
                    Button("Fill random answers") { for i in 1...questionCount { answers[i] = AnswerChoice.allCases.randomElement() ?? .A } }
                    ForEach(1...questionCount, id: \.self) { q in
                        Picker("Q\(q)", selection: Binding(get: { answers[q] ?? .A }, set: { answers[q] = $0 })) {
                            ForEach(AnswerChoice.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle(store.isArabic ? "اختبار جديد" : "New Exam")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.isArabic ? "إلغاء" : "Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(store.isArabic ? "حفظ" : "Save") { save() }.disabled(name.isEmpty || subject.isEmpty) }
            }
        }
    }

    func save() {
        var qs: [Question] = []
        var entries: [Int: AnswerChoice] = [:]
        for i in 1...questionCount {
            let ch = answers[i] ?? .A
            entries[i] = ch
            qs.append(Question(id: "q_\(UUID().uuidString)_\(i)", number: i, correctChoice: ch, weight: weight))
        }
        let exam = Exam(id: "exam_\(UUID().uuidString)", name: name, subject: subject, date: Date(), questions: qs, answerKey: AnswerKey(id: "key_\(UUID().uuidString)", name: "Key \(name)", entries: entries), templateId: questionCount <= 20 ? "default-20q-template" : "default-50q-template", maximumScore: Double(questionCount) * weight, createdAt: Date())
        store.saveExam(exam)
        dismiss()
    }
}
