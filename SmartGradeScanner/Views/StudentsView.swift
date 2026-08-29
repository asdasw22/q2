import SwiftUI
import Foundation

struct StudentsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var search = ""
    @State private var adding = false

    private var filtered: [Student] {
        if search.isEmpty { return store.students }
        return store.students.filter { student in
            student.name.localizedCaseInsensitiveContains(search)
            || student.studentID.contains(search)
        }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(store.isArabic ? "الطلاب" : "Students")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { adding = true } label: { Image(systemName: "plus") }
                    }
                }
                .sheet(isPresented: $adding) {
                    StudentFormView(student: nil)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if filtered.isEmpty {
            EmptyStateView(
                title: store.isArabic ? "لا يوجد طلاب" : "No students",
                message: store.isArabic ? "أضف الطلاب حتى تظهر نتائج المسح بأسمائهم." : "Add students to connect scanned IDs to names.",
                systemImage: "person.crop.circle.badge.plus"
            )
        } else {
            List {
                ForEach(filtered) { student in
                    NavigationLink(value: student) {
                        StudentListRow(student: student)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            store.deleteStudent(student.id)
                        } label: {
                            Label(store.isArabic ? "حذف" : "Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: store.isArabic ? "ابحث عن طالب" : "Search students")
            .navigationDestination(for: Student.self) { student in
                StudentDetailsView(student: student)
            }
        }
    }
}

private struct StudentListRow: View {
    @EnvironmentObject private var store: SmartGradeStore
    let student: Student

    private var results: [ExamResult] { store.resultsForStudent(student) }
    private var average: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.percentage).reduce(0, +) / Double(results.count)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.headline)
                Text("\(student.studentID) · \(store.classroomName(for: student.classroomId) ?? "-")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !results.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", average))
                        .font(.headline.monospacedDigit())
                    Text("\(results.count) \(store.isArabic ? "نتائج" : "results")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct StudentDetailsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    let student: Student
    @State private var editing = false

    private var results: [ExamResult] { store.resultsForStudent(student) }
    private var average: Double {
        guard !results.isEmpty else { return 0 }
        return results.map(\.percentage).reduce(0, +) / Double(results.count)
    }
    private var totalScore: Double { results.map(\.score).reduce(0, +) }
    private var totalMaximumScore: Double { results.map(\.maximumScore).reduce(0, +) }

    var body: some View {
        List {
            StudentInfoSection(student: student)

            if results.isEmpty {
                NoStudentResultsSection()
            } else {
                StudentSummarySection(
                    count: results.count,
                    average: average,
                    totalScore: totalScore,
                    totalMaximumScore: totalMaximumScore
                )

                Section(store.isArabic ? "علامات الطالب" : "Student grades") {
                    ForEach(results) { result in
                        StudentResultRow(result: result)
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { results[$0].id }
                        ids.forEach(store.deleteResult)
                    }
                }
            }
        }
        .navigationTitle(store.isArabic ? "علامات الطالب" : "Student Grades")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(store.isArabic ? "تعديل" : "Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) {
            StudentFormView(student: student)
        }
    }
}

private struct StudentInfoSection: View {
    @EnvironmentObject private var store: SmartGradeStore
    let student: Student

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(student.name)
                    .font(.title2.bold())
                Text("\(store.isArabic ? "رقم الطالب" : "Student ID"): \(student.studentID)")
                    .foregroundStyle(.secondary)
                Text("\(store.isArabic ? "الصف" : "Class"): \(store.classroomName(for: student.classroomId) ?? "-")")
                    .foregroundStyle(.secondary)

                if let notes = student.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct NoStudentResultsSection: View {
    @EnvironmentObject private var store: SmartGradeStore

    var body: some View {
        Section {
            Text(store.isArabic ? "لا توجد علامات بعد. بعد مسح ورقة هذا الطالب وحفظ النتيجة ستظهر علامته هنا." : "No results yet. Scan and save this student's answer sheet to show the grade here.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct StudentSummarySection: View {
    @EnvironmentObject private var store: SmartGradeStore
    let count: Int
    let average: Double
    let totalScore: Double
    let totalMaximumScore: Double

    var body: some View {
        Section(store.isArabic ? "الملخص" : "Summary") {
            LabeledContent(store.isArabic ? "عدد النتائج" : "Results") {
                Text("\(count)")
            }
            LabeledContent(store.isArabic ? "المعدل" : "Average") {
                Text(String(format: "%.1f%%", average))
                    .fontWeight(.semibold)
            }
            LabeledContent(store.isArabic ? "مجموع العلامات" : "Total score") {
                Text(String(format: "%.1f / %.1f", totalScore, totalMaximumScore))
                    .fontWeight(.semibold)
            }
        }
    }
}

private struct StudentResultRow: View {
    @EnvironmentObject private var store: SmartGradeStore
    let result: ExamResult

    private var exam: Exam? { store.exam(for: result.examId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exam?.name ?? (store.isArabic ? "اختبار محذوف" : "Deleted exam"))
                        .font(.headline)
                    Text(exam?.subject ?? "-")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(result.scannedAt.smartDateTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "%.1f%%", result.percentage))
                        .font(.title3.bold())
                        .foregroundStyle(result.needsReview ? .orange : .primary)
                    Text(String(format: "%.1f / %.1f", result.score, result.maximumScore))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            StudentResultStats(result: result)

            if result.needsReview {
                Label(store.isArabic ? "تحتاج مراجعة" : "Needs review", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StudentResultStats: View {
    let result: ExamResult

    var body: some View {
        HStack(spacing: 12) {
            Label("\(result.correctCount)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Label("\(result.wrongCount)", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
            Label("\(result.emptyCount)", systemImage: "minus.circle")
                .foregroundStyle(.secondary)

            if result.multipleCount > 0 {
                Label("\(result.multipleCount)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption)
    }
}

struct StudentFormView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @Environment(\.dismiss) private var dismiss
    let student: Student?
    @State private var name = ""
    @State private var sid = ""
    @State private var classroom = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(store.isArabic ? "رقم الطالب" : "Student ID", text: $sid)
                    .keyboardType(.numberPad)
                TextField(store.isArabic ? "الاسم" : "Name", text: $name)
                Picker(store.isArabic ? "الصف" : "Class", selection: $classroom) {
                    ForEach(store.classrooms) { classroom in
                        Text(classroom.name).tag(classroom.id)
                    }
                }
                TextField(store.isArabic ? "ملاحظات" : "Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle(student == nil ? (store.isArabic ? "طالب جديد" : "New Student") : (store.isArabic ? "تعديل الطالب" : "Edit Student"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.isArabic ? "إلغاء" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.isArabic ? "حفظ" : "Save") { save() }
                        .disabled(name.isEmpty || sid.isEmpty)
                }
            }
            .onAppear { loadInitialValues() }
        }
    }

    private func loadInitialValues() {
        name = student?.name ?? ""
        sid = student?.studentID ?? "320\(Int.random(in: 100000...999999))"
        classroom = student?.classroomId ?? store.classrooms.first?.id ?? ""
        notes = student?.notes ?? ""
    }

    private func save() {
        let updated = Student(
            id: student?.id ?? "stu_\(UUID().uuidString)",
            name: name,
            studentID: sid,
            classroomId: classroom,
            createdAt: student?.createdAt ?? Date(),
            notes: notes.isEmpty ? nil : notes
        )
        store.saveStudent(updated)
        dismiss()
    }
}