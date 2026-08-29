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
            List {
                if let current {
                    SwiftUI.Section("") {
                        LabeledContent("Student", value: studentID.isEmpty ? "Needs review" : studentID)
                        
                        LabeledContent(
                            "Score",
                            value: "\(current.score, specifier: "%.1f") / \(current.maximumScore, specifier: "%.1f")"
                        )
                        
                        LabeledContent(
                            "Percentage",
                            value: "\(current.percentage, specifier: "%.1f")%"
                        )
                        
                        if current.needsReview {
                            Label(
                                "Some answers need manual review",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(.orange)
                        }
                    }

                    SwiftUI.Section("Student") {
                        TextField("Student ID", text: $studentID)
                            .keyboardType(.numberPad)
                        
                        if let s = store.findStudent(studentID: studentID) {
                            Label(s.name, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label(
                                "Unregistered student ID",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(.orange)
                        }
                    }

                    SwiftUI.Section("Questions") {
                        ForEach(responses) { resp in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Q\(resp.questionNumber)")
                                        .frame(width: 42, alignment: .leading)
                                    
                                    Text(
                                        resp.selectedChoices
                                            .map { $0.rawValue }
                                            .joined(separator: " + ")
                                            .ifEmpty("Empty")
                                    )
                                    
                                    Spacer()
                                    
                                    StatusPill(status: resp.status)
                                    
                                    Text("\(resp.confidence, specifier: "%.0f")%")
                                        .font(.caption.monospacedDigit())
                                }
                                
                                HStack {
                                    ForEach(AnswerChoice.allCases) { ch in
                                        Button(ch.rawValue) {
                                            toggle(resp.questionNumber, ch)
                                        }
                                        .font(.caption.bold())
                                        .frame(width: 32, height: 32)
                                        .background(
                                            resp.selectedChoices.contains(ch)
                                            ? Color.accentColor
                                            : Color.gray.opacity(0.12),
                                            in: Circle()
                                        )
                                        .foregroundStyle(
                                            resp.selectedChoices.contains(ch)
                                            ? .white
                                            : .primary
                                        )
                                    }
                                }
                                
                                Text("Correct: \(resp.correctChoice.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(store.isArabic ? "مراجعة المسح" : "Review Scan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        onDiscard()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Result") {
                        save()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                buildInitial()
            }
        }
    }

    func buildInitial() {
        let student = store.findStudent(studentID: omr.studentID)
        studentID = omr.studentID
        
        let result = GradingService.grade(
            omr,
            exam: exam,
            matchedStudent: student,
            classroomName: student.flatMap {
                store.classroomName(for: $0.classroomId)
            }
        )
        
        current = result
        responses = result.responses
    }

    func toggle(_ q: Int, _ choice: AnswerChoice) {
        responses = responses.map { r in
            var x = r
            
            if x.questionNumber == q {
                x.selectedChoices = x.selectedChoices.contains(choice)
                    ? []
                    : [choice]
                
                x.status = x.selectedChoices.isEmpty
                    ? .empty
                    : .selected
                
                x.confidence = 100
                x.manuallyEdited = true
            }
            
            return x
        }
        
        if let c = current {
            current = GradingService.recalculate(
                c,
                exam: exam,
                updatedResponses: responses
            )
        }
    }

    func save() {
        guard var result = current else { return }
        
        let student = store.findStudent(studentID: studentID)
        
        result.studentID = studentID
        result.studentId = student?.id
        result.studentName = student?.name ?? result.studentName
        result.classroomName = student.flatMap {
            store.classroomName(for: $0.classroomId)
        }
        
        onSave(result)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
