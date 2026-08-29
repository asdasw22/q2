import Foundation

struct SampleDataSeeder {
    struct Seed { var templates: [ExamTemplate]; var classrooms: [Classroom]; var students: [Student]; var exams: [Exam]; var results: [ExamResult] }

    static func seed() -> Seed {
        let t20 = DefaultTemplateFactory.make20QuestionTemplate()
        let t50 = DefaultTemplateFactory.make50QuestionTemplate()
        let templates = [ExamTemplate(id: t20.id, name: t20.name, definition: t20), ExamTemplate(id: t50.id, name: t50.name, definition: t50)]
        let classrooms = [
            Classroom(id: "class_10a", name: "الصف العاشر - أ (Grade 10-A)", grade: "10", createdAt: Date(), description: "شعبة العلوم الطبيعية والفيزياء"),
            Classroom(id: "class_11b", name: "الصف الحادي عشر - ب (Grade 11-B)", grade: "11", createdAt: Date(), description: "شعبة الرياضيات المتقدمة")
        ]
        let students = [
            Student(id: "stu_1", name: "أحمد محمود العتيبي", studentID: "320145892", classroomId: "class_10a", createdAt: Date(), notes: "طالب متفوق"),
            Student(id: "stu_2", name: "سارة خالد المنصور", studentID: "320882194", classroomId: "class_10a", createdAt: Date(), notes: nil),
            Student(id: "stu_3", name: "عمر ياسين الدوسري", studentID: "320501239", classroomId: "class_10a", createdAt: Date(), notes: nil),
            Student(id: "stu_4", name: "فاطمة عبد الله القحطاني", studentID: "320773910", classroomId: "class_10a", createdAt: Date(), notes: nil),
            Student(id: "stu_5", name: "فيصل عبد الرحمن السعيد", studentID: "320921448", classroomId: "class_10a", createdAt: Date(), notes: nil),
            Student(id: "stu_6", name: "نورة إبراهيم الشمري", studentID: "320334812", classroomId: "class_11b", createdAt: Date(), notes: nil)
        ]
        let defaults: [Int: AnswerChoice] = [1:.A,2:.B,3:.C,4:.A,5:.D,6:.B,7:.C,8:.A,9:.E,10:.B,11:.A,12:.C,13:.D,14:.B,15:.A,16:.E,17:.B,18:.C,19:.A,20:.D]
        let questions = (1...20).map { Question(id: "q_\($0)", number: $0, correctChoice: defaults[$0] ?? .A, weight: 1) }
        let exam1 = Exam(id: "exam_physics_midterm", name: "اختبار الفيزياء النصفي (Midterm Physics)", subject: "الفيزياء (Physics)", date: Date(), questions: questions, answerKey: AnswerKey(id: "key_physics_1", name: "مفتاح إجابات الفيزياء الرئيسي", entries: defaults), templateId: t20.id, maximumScore: 20, createdAt: Date())
        let exam2Questions = (1...20).map { Question(id: "mq_\($0)", number: $0, correctChoice: AnswerChoice.allCases.randomElement() ?? .A, weight: 1) }
        let exam2Answers = Dictionary(uniqueKeysWithValues: exam2Questions.map { ($0.number, $0.correctChoice) })
        let exam2 = Exam(id: "exam_math_quiz", name: "اختبار الجبر والتحليل (Math Quiz)", subject: "الرياضيات (Mathematics)", date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), questions: exam2Questions, answerKey: AnswerKey(id: "key_math", name: "مفتاح الرياضيات", entries: exam2Answers), templateId: t20.id, maximumScore: 20, createdAt: Date())
        let result1 = makeResult(id: "res_1", exam: exam1, student: students[0], classroom: classrooms[0].name, wrong: [20], empty: [], multiple: [])
        let result2 = makeResult(id: "res_2", exam: exam1, student: students[1], classroom: classrooms[0].name, wrong: [2,4,8,17], empty: [10], multiple: [])
        let result3 = makeResult(id: "res_3", exam: exam1, student: students[2], classroom: classrooms[0].name, wrong: [12,19], empty: [], multiple: [3], weakCorrect: [6])
        return Seed(templates: templates, classrooms: classrooms, students: students, exams: [exam1, exam2], results: [result1, result2, result3])
    }

    private static func makeResult(id: String, exam: Exam, student: Student, classroom: String, wrong: Set<Int>, empty: Set<Int>, multiple: Set<Int>, weakCorrect: Set<Int> = []) -> ExamResult {
        var score = 0.0, correct = 0, wrongCount = 0, emptyCount = 0, multipleCount = 0
        let responses = exam.questions.map { q -> StudentResponse in
            let selected: [AnswerChoice]; let status: ResponseStatus; let isCorrect: Bool
            if empty.contains(q.number) { selected = []; status = .empty; isCorrect = false; emptyCount += 1 }
            else if multiple.contains(q.number) { selected = [.A, .C]; status = .multiple; isCorrect = false; multipleCount += 1; wrongCount += 1 }
            else if wrong.contains(q.number) { selected = [AnswerChoice.allCases.first { $0 != q.correctChoice } ?? .A]; status = .selected; isCorrect = false; wrongCount += 1 }
            else { selected = [q.correctChoice]; status = weakCorrect.contains(q.number) ? .weak : .selected; isCorrect = true; correct += 1; score += q.weight }
            return StudentResponse(id: "resp_\(id)_\(q.number)", questionNumber: q.number, selectedChoices: selected, correctChoice: q.correctChoice, status: status, confidence: status == .weak ? 55 : 92, manuallyEdited: false, isCorrect: isCorrect)
        }
        return ExamResult(id: id, examId: exam.id, studentId: student.id, studentID: student.studentID, studentName: student.name, classroomName: classroom, scannedAt: Date(), score: score, maximumScore: exam.maximumScore, percentage: round(score / exam.maximumScore * 1000) / 10, correctCount: correct, wrongCount: wrongCount, emptyCount: emptyCount, multipleCount: multipleCount, needsReview: !multiple.isEmpty || !weakCorrect.isEmpty, correctedImageJPEGData: nil, responses: responses)
    }
}

