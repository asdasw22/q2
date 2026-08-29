import SwiftUI

struct ClassroomsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var add = false

    var body: some View {
        NavigationStack {
            Group {
                if store.classrooms.isEmpty {
                    EmptyStateView(title: "No classes", message: "Create a class to organize students and exams.", systemImage: "person.2.badge.plus")
                } else {
                    List {
                        ForEach(store.classrooms) { classroom in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(classroom.name).font(.headline)
                                Text("\(classroom.grade ?? "-") · \(store.students.filter { $0.classroomId == classroom.id }.count) students")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let description = classroom.description, !description.isEmpty {
                                    Text(description).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) { store.deleteClassroom(classroom.id) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .navigationTitle(store.isArabic ? "الصفوف" : "Classes")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { add = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $add) { ClassroomFormView() }
        }
    }
}

struct ClassroomFormView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var grade = "Grade 8"
    @State private var desc = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Class name", text: $name)
                TextField("Grade", text: $grade)
                TextField("Description", text: $desc, axis: .vertical)
            }
            .navigationTitle("New Class")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.saveClassroom(Classroom(id: "class_\(UUID().uuidString)", name: name, grade: grade, createdAt: Date(), description: desc))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
