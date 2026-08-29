import SwiftUI

struct ScanReviewView: View {
    @EnvironmentObject private var store: SmartGradeStore
    let omr: OMRProcessingResult
    let exam: Exam
    let onSave: (ExamResult) -> Void
    let onDiscard: () -> Void
    @State private var studentID: String = ""
    @State private var responses: [StudentResponse] = []
    @State private var current: ExamResult?

    var body: some View {
        NavigationStack {
            ScrollView { VStack(spacing: 16) {
                if let current {
                    scoreCard(current)
                    GlassCard { VStack(alignment: .leading, spacing: 12) { Text("بيانات الطالب").font(.headline); TextField("رقم الطالب", text: $studentID).textFieldStyle(.roundedBorder); if let s = store.findStudent(studentID: studentID) { Label(s.name, systemImage: "checkmark.circle.fill").foregroundStyle(Palette.emerald) } else { Label("رقم طالب غير مسجل", systemImage: "exclamationmark.triangle.fill").foregroundStyle(Palette.amber) } } }
                    GlassCard { LazyVGrid(columns: [GridItem(.adaptive(minimum: 155))], spacing: 12) { ForEach(responses) { resp in responseCell(resp) } } }
                }
            }.padding() }
            .navigationTitle("مراجعة نتيجة المسح")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { onDiscard() } }; ToolbarItem(placement: .confirmationAction) { Button("حفظ") { save() }.fontWeight(.bold) } }
            .onAppear { buildInitial() }
            .pageBackground()
        }
    }

    func scoreCard(_ r: ExamResult) -> some View {
        GlassCard { VStack(spacing: 12) { HStack { Text("النتيجة الإجمالية").font(.headline); Spacer(); Text(r.percentage >= 50 ? "ناجح" : "راسب").font(.caption.bold()).padding(8).background((r.percentage >= 50 ? Palette.emerald : Palette.rose).opacity(0.15), in: Capsule()) }; HStack(alignment: .firstTextBaseline) { Text("\(r.score, specifier: "%.1f")").font(.system(size: 44, weight: .black)); Text("/ \(r.maximumScore, specifier: "%.1f")").foregroundStyle(.secondary); Spacer(); Text("\(r.percentage, specifier: "%.1f")%").font(.title.bold()).foregroundStyle(Palette.indigo) }; ProgressView(value: r.percentage / 100).tint(r.percentage >= 80 ? Palette.emerald : r.percentage >= 50 ? Palette.indigo : Palette.rose); HStack { Label("\(r.correctCount) صحيح", systemImage: "checkmark.circle"); Label("\(r.wrongCount) خطأ", systemImage: "xmark.circle"); Label("\(r.emptyCount) فارغ", systemImage: "circle"); Label("\(r.multipleCount) متعدد", systemImage: "exclamationmark.circle") }.font(.caption).foregroundStyle(.secondary) } }
    }

    func responseCell(_ resp: StudentResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("سؤال \(resp.questionNumber)").font(.headline); Spacer(); StatusPill(status: resp.status) }
            HStack { ForEach(AnswerChoice.allCases) { ch in Button(ch.rawValue) { toggle(resp.questionNumber, ch) }.font(.caption.bold()).frame(width: 32, height: 32).background(resp.selectedChoices.contains(ch) ? Palette.indigo : Color.gray.opacity(0.12), in: Circle()).foregroundStyle(resp.selectedChoices.contains(ch) ? .white : .primary) } }
            Text("الصحيح: \(resp.correctChoice.rawValue) • ثقة: \(Int(resp.confidence))%").font(.caption2).foregroundStyle(.secondary)
        }.padding(12).background((resp.isCorrect == true ? Palette.emerald : Palette.rose).opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }

    func buildInitial() { let student = store.findStudent(studentID: omr.studentID); studentID = omr.studentID; let result = GradingService.grade(omr, exam: exam, matchedStudent: student, classroomName: student.flatMap { store.classroomName(for: $0.classroomId) }); current = result; responses = result.responses }
    func toggle(_ q: Int, _ choice: AnswerChoice) { responses = responses.map { r in var x = r; if x.questionNumber == q { x.selectedChoices = x.selectedChoices.contains(choice) ? [] : [choice]; x.status = x.selectedChoices.isEmpty ? .empty : .selected; x.confidence = 100; x.manuallyEdited = true }; return x }; if let c = current { current = GradingService.recalculate(c, exam: exam, updatedResponses: responses) } }
    func save() { guard var result = current else { return }; let student = store.findStudent(studentID: studentID); result.studentID = studentID; result.studentId = student?.id; result.studentName = student?.name ?? result.studentName; result.classroomName = student.flatMap { store.classroomName(for: $0.classroomId) }; onSave(result) }
}

