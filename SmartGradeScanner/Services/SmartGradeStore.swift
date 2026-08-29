import Foundation
import SwiftUI
import Combine

@MainActor
final class SmartGradeStore: ObservableObject {
    @Published var isArabic: Bool = true { didSet { saveLanguage() } }
    @Published var templates: [ExamTemplate] = [] { didSet { saveAll() } }
    @Published var classrooms: [Classroom] = [] { didSet { saveAll() } }
    @Published var students: [Student] = [] { didSet { saveAll() } }
    @Published var exams: [Exam] = [] { didSet { saveAll() } }
    @Published var results: [ExamResult] = [] { didSet { saveAll() } }

    private let defaults = UserDefaults.standard
    private let initializedKey = "smartgrade_initialized_v1"
    private let languageKey = "smartgrade_language_v1"
    private let payloadKey = "smartgrade_payload_v1"
    private var isBootstrapping = true

    struct Payload: Codable {
        var templates: [ExamTemplate]
        var classrooms: [Classroom]
        var students: [Student]
        var exams: [Exam]
        var results: [ExamResult]
    }

    init() { load() }

    func load() {
        isBootstrapping = true
        isArabic = defaults.string(forKey: languageKey) != "en"
        if defaults.bool(forKey: initializedKey), let data = defaults.data(forKey: payloadKey), let payload = try? JSONDecoder.smart.decode(Payload.self, from: data) {
            templates = payload.templates; classrooms = payload.classrooms; students = payload.students; exams = payload.exams; results = payload.results
        } else {
            resetToDefaults()
        }
        isBootstrapping = false
    }

    func resetToDefaults() {
        let seed = SampleDataSeeder.seed()
        templates = seed.templates; classrooms = seed.classrooms; students = seed.students; exams = seed.exams; results = seed.results
        defaults.set(true, forKey: initializedKey)
        saveAll(force: true)
    }

    func saveTemplate(_ template: ExamTemplate) { upsert(template, array: &templates) }
    func saveClassroom(_ classroom: Classroom) { upsert(classroom, array: &classrooms) }
    func deleteClassroom(_ id: String) { classrooms.removeAll { $0.id == id }; students = students.map { s in var x = s; if x.classroomId == id { x.classroomId = classrooms.first?.id ?? "" }; return x } }
    func saveStudent(_ student: Student) { upsert(student, array: &students) }
    func deleteStudent(_ id: String) { students.removeAll { $0.id == id } }
    func saveExam(_ exam: Exam) { upsert(exam, array: &exams) }
    func deleteExam(_ id: String) { exams.removeAll { $0.id == id }; results.removeAll { $0.examId == id } }
    func saveResult(_ result: ExamResult) { upsert(result, array: &results, prepend: true) }
    func deleteResult(_ id: String) { results.removeAll { $0.id == id } }
    func results(for exam: Exam) -> [ExamResult] { results.filter { $0.examId == exam.id } }
    func resultsForStudent(_ student: Student) -> [ExamResult] {
        results.filter { result in
            result.studentId == student.id
            || result.studentID == student.studentID
            || result.studentID.hasSuffix(student.studentID)
            || student.studentID.hasSuffix(result.studentID)
        }
    }
    func exam(for id: String) -> Exam? { exams.first { $0.id == id } }
    func findStudent(studentID: String) -> Student? { students.first { $0.studentID == studentID || $0.studentID.hasSuffix(studentID) || studentID.hasSuffix($0.studentID) } }
    func classroomName(for id: String) -> String? { classrooms.first { $0.id == id }?.name }

    private func upsert<T: Identifiable & Codable & Hashable>(_ item: T, array: inout [T], prepend: Bool = false) where T.ID: Equatable {
        if let idx = array.firstIndex(where: { $0.id == item.id }) { array[idx] = item }
        else { if prepend { array.insert(item, at: 0) } else { array.append(item) } }
    }

    private func saveLanguage() { defaults.set(isArabic ? "ar" : "en", forKey: languageKey) }

    private func saveAll(force: Bool = false) {
        guard !isBootstrapping || force else { return }
        let payload = Payload(templates: templates, classrooms: classrooms, students: students, exams: exams, results: results)
        if let data = try? JSONEncoder.smart.encode(payload) { defaults.set(data, forKey: payloadKey) }
    }
}

extension JSONEncoder {
    static var smart: JSONEncoder { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }
}
extension JSONDecoder {
    static var smart: JSONDecoder { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }
}


