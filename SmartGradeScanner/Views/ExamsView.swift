import SwiftUI

struct ExamsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    let onScan: (String) -> Void
    @State private var search = ""
    @State private var showingCreate = false
    var filtered: [Exam] { store.exams.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.subject.localizedCaseInsensitiveContains(search) } }
    var body: some View { ScrollView { VStack(spacing: 16) { GlassCard { HStack { VStack(alignment: .leading) { Text("قائمة الاختبارات والامتحانات").font(.title3.bold()); Text("إدارة مفاتيح الإجابة وقوالب OMR ونتائج الطلاب").font(.caption).foregroundStyle(.secondary) }; Spacer(); PrimaryButton(title: "اختبار جديد", icon: "plus") { showingCreate = true } } }; TextField("البحث باسم الاختبار أو المادة...", text: $search).textFieldStyle(.roundedBorder).padding(.horizontal); LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 14) { ForEach(filtered) { examCard($0) } }.padding(.horizontal) }.padding(.vertical) }.sheet(isPresented: $showingCreate) { CreateExamView() }.pageBackground() }
    func examCard(_ exam: Exam) -> some View { let rs = store.results(for: exam); let avg = rs.isEmpty ? 0 : rs.map(\.percentage).reduce(0,+)/Double(rs.count); return GlassCard { VStack(alignment: .leading, spacing: 12) { HStack { Text(exam.subject).font(.caption.bold()).padding(7).background(Palette.indigo.opacity(0.1), in: Capsule()); Spacer(); Button(role: .destructive) { store.deleteExam(exam.id) } label: { Image(systemName: "trash") } }; Text(exam.name).font(.headline); Text("\(exam.date.smartDate) • \(exam.questions.count) سؤال • \(exam.maximumScore, specifier: "%.0f") درجة").font(.caption).foregroundStyle(.secondary); HStack { Text("\(rs.count) ورقة مصححة").font(.caption.bold()); if !rs.isEmpty { Text("متوسط \(avg, specifier: "%.1f")%").font(.caption).foregroundStyle(Palette.emerald) }; Spacer(); Button("مسح") { onScan(exam.id) }.buttonStyle(.borderedProminent) } } } }
}

struct CreateExamView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""; @State private var subject = ""; @State private var questionCount = 20; @State private var weight = 1.0; @State private var answers: [Int: AnswerChoice] = [:]
    var body: some View { NavigationStack { Form { Section("تفاصيل الاختبار") { TextField("اسم الاختبار", text: $name); TextField("المادة", text: $subject); Picker("عدد الأسئلة", selection: $questionCount) { Text("20 سؤالاً").tag(20); Text("50 سؤالاً").tag(50) }; Stepper("درجة كل سؤال: \(weight, specifier: "%.1f")", value: $weight, in: 0.5...10, step: 0.5) }; Section("مفتاح الإجابات") { Button("تعبئة عشوائية") { for i in 1...questionCount { answers[i] = AnswerChoice.allCases.randomElement() ?? .A } }; ForEach(1...questionCount, id: \.self) { q in Picker("سؤال \(q)", selection: Binding(get: { answers[q] ?? .A }, set: { answers[q] = $0 })) { ForEach(AnswerChoice.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented) } } }.navigationTitle("إنشاء اختبار جديد").toolbar { ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("حفظ") { save() }.disabled(name.isEmpty || subject.isEmpty) } } } }
    func save() { var qs: [Question] = []; var entries: [Int: AnswerChoice] = [:]; for i in 1...questionCount { let ch = answers[i] ?? .A; entries[i] = ch; qs.append(Question(id: "q_\(UUID().uuidString)_\(i)", number: i, correctChoice: ch, weight: weight)) }; let exam = Exam(id: "exam_\(UUID().uuidString)", name: name, subject: subject, date: Date(), questions: qs, answerKey: AnswerKey(id: "key_\(UUID().uuidString)", name: "مفتاح \(name)", entries: entries), templateId: questionCount <= 20 ? "default-20q-template" : "default-50q-template", maximumScore: Double(questionCount) * weight, createdAt: Date()); store.saveExam(exam); dismiss() }
}

