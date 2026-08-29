import SwiftUI

struct StudentsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var search = ""
    @State private var editing: Student?
    @State private var adding = false

    var filtered: [Student] {
        search.isEmpty ? store.students : store.students.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.studentID.contains(search) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    EmptyStateView(title: "No students", message: "Add students to connect scanned IDs to names.", systemImage: "person.crop.circle.badge.plus")
                } else {
                    List {
                        ForEach(filtered) { student in
                            NavigationLink {
                                StudentDetailsView(student: student)
                            } label: {
                                row(student)
                            }
                                .swipeActions {
                                    Button(role: .destructive) { store.deleteStudent(student.id) } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    }
                    .searchable(text: $search, prompt: "Search students")
                }
            }
            .navigationTitle(store.isArabic ? "الطلاب" : "Students")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { adding = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $adding) { StudentFormView(student: nil) }
            .sheet(item: $editing) { StudentFormView(student: $0) }
        }
    }

    private func row(_ s: Student) -> some View {
        let results = store.resultsForStudent(s)
        let average = results.isEmpty ? 0 : results.map(\.percentage).reduce(0, +) / Double(results.count)

        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.name).font(.headline)
                    Text("\(s.studentID) · \(store.classroomName(for: s.classroomId) ?? "-")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !results.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(average, specifier: "%.0f")%")
                            .font(.headline.monospacedDigit())
                        Text("\(results.count) \(store.isArabic ? "نتائج" : "results")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct StudentDetailsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    let student: Student
    @State private var editing = false

    private var results: [ExamResult] {
        store.resultsForStudent(student)
    }

    private var average: Double {
        results.isEmpty ? 0 : results.map(\.percentage).reduce(0, +) / Double(results.count)
    }

    private var totalScore: Double {
        results.map(\.score).reduce(0, +)
    }

    private var totalMaximumScore: Double {
        results.map(\.maximumScore).reduce(0, +)
    }

    var body: some View {
        List {
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
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }

            if results.isEmpty {
                Section {
                    ContentUnavailableView(
                        store.isArabic ? "لا توجد علامات بعد" : "No results yet",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(store.isArabic ? "بعد مسح ورقة هذا الطالب وحفظ النتيجة ستظهر علامته هنا." : "Scan and save this student's answer sheet to show the grade here.")
                    )
                }
            } else {
                Section(store.isArabic ? "الملخص" : "Summary") {
                    LabeledContent(store.isArabic ? "عدد النتائج" : "Results") {
                        Text("\(results.count)")
                    }
                    LabeledContent(store.isArabic ? "المعدل" : "Average") {
                        Text("\(average, specifier: "%.1f")%")
                            .fontWeight(.semibold)
                    }
                    LabeledContent(store.isArabic ? "مجموع العلامات" : "Total score") {
                        Text("\(totalScore, specifier: "%.1f") / \(totalMaximumScore, specifier: "%.1f")")
                            .fontWeight(.semibold)
                    }
                }

                Section(store.isArabic ? "علامات الطالب" : "Student grades") {
                    ForEach(results) { result in
                        StudentResultRow(result: result, exam: store.exam(for: result.examId))
                    }
                    .onDelete { offsets in
                        offsets.map { results[$0].id }.forEach(store.deleteResult)
                    }
                }
            }
        }
        .navigationTitle(store.isArabic ? "علامات الطالب" : "Student Grades")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(store.isArabic ? "تعديل" : "Edit") {
                    editing = true
                }
            }
        }
        .sheet(isPresented: $editing) {
            StudentFormView(student: student)
        }
    }
}

private struct StudentResultRow: View {
    @EnvironmentObject private var store: SmartGradeStore
    let result: ExamResult
    let exam: Exam?

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
                    Text("\(result.percentage, specifier: "%.1f")%")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(result.needsReview ? .orange : .primary)
                    Text("\(result.score, specifier: "%.1f") / \(result.maximumScore, specifier: "%.1f")")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

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

            if result.needsReview {
                Label(
                    store.isArabic ? "تحتاج مراجعة" : "Needs review",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
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
                TextField("Student ID", text: $sid).keyboardType(.numberPad)
                TextField("Name", text: $name)
                Picker("Class", selection: $classroom) { ForEach(store.classrooms) { Text($0.name).tag($0.id) } }
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle(student == nil ? "New Student" : "Edit Student")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(name.isEmpty || sid.isEmpty) }
            }
            .onAppear {
                name = student?.name ?? ""
                sid = student?.studentID ?? "320\(Int.random(in: 100000...999999))"
                classroom = student?.classroomId ?? store.classrooms.first?.id ?? ""
                notes = student?.notes ?? ""
            }
        }
    }

    func save() {
        store.saveStudent(Student(id: student?.id ?? "stu_\(UUID().uuidString)", name: name, studentID: sid, classroomId: classroom, createdAt: student?.createdAt ?? Date(), notes: notes.isEmpty ? nil : notes))
        dismiss()
    }
}
