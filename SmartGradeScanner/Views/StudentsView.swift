import SwiftUI

struct StudentsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var search = ""
    @State private var editing: Student?
    @State private var adding = false

    var filtered: [Student] {
        search.isEmpty ? store.students : store.students.filter {
            $0.name.localizedCaseInsensitiveContains(search) || $0.studentID.contains(search)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    EmptyStateView(
                        title: "No students",
                        message: "Add students to connect scanned IDs to names.",
                        systemImage: "person.crop.circle.badge.plus"
                    )
                } else {
                    List {
                        ForEach(filtered) { student in
                            NavigationLink {
                                StudentDetailsView(student: student)
                            } label: {
                                row(student)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.deleteStudent(student.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .searchable(text: $search, prompt: "Search students")
                }
            }
            .navigationTitle(store.isArabic ? "الطلاب" : "Students")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        adding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $adding) {
                StudentFormView(student: nil)
            }
            .sheet(item: $editing) {
                StudentFormView(student: $0)
            }
        }
    }

    private func row(_ s: Student) -> some View {
        let results = store.resultsForStudent(s)
        let average = results.isEmpty ? 0 : results.map(\.percentage).reduce(0, +) / Double(results.count)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.name)
                        .font(.headline)

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
