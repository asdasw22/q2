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
                            Button { editing = student } label: { row(student) }
                                .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(s.name).font(.headline)
            Text("\(s.studentID) · \(store.classroomName(for: s.classroomId) ?? "-")").font(.caption).foregroundStyle(.secondary)
        }
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
