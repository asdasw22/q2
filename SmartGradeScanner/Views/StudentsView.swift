import SwiftUI

struct StudentsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var search = ""
    @State private var selectedClassroom = "all"
    @State private var editing: Student?
    @State private var adding = false
    var filtered: [Student] { store.students.filter { s in (search.isEmpty || s.name.localizedCaseInsensitiveContains(search) || s.studentID.contains(search)) && (selectedClassroom == "all" || s.classroomId == selectedClassroom) } }
    var body: some View { ScrollView { VStack(spacing: 16) { GlassCard { HStack { VStack(alignment: .leading) { Text("سجل الطلاب والأرقام الأكاديمية").font(.title3.bold()); Text("ربط تلقائي بين رقم الطالب ونتيجة ورقة الإجابة").font(.caption).foregroundStyle(.secondary) }; Spacer(); PrimaryButton(title: "إضافة", icon: "person.badge.plus") { adding = true } } }; HStack { TextField("بحث باسم الطالب أو رقمه...", text: $search).textFieldStyle(.roundedBorder); Picker("الصف", selection: $selectedClassroom) { Text("الكل").tag("all"); ForEach(store.classrooms) { Text($0.name).tag($0.id) } }.pickerStyle(.menu) }.padding(.horizontal); LazyVStack(spacing: 12) { ForEach(filtered) { row($0) } }.padding(.horizontal) }.padding(.vertical) }.sheet(isPresented: $adding) { StudentFormView(student: nil) }.sheet(item: $editing) { StudentFormView(student: $0) }.pageBackground() }
    func row(_ s: Student) -> some View { GlassCard(padding: 14) { HStack(spacing: 12) { Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(Palette.indigo); VStack(alignment: .leading, spacing: 4) { Text(s.name).font(.headline); Text(s.studentID).font(.system(.subheadline, design: .monospaced).bold()).foregroundStyle(Palette.indigo); Text(store.classroomName(for: s.classroomId) ?? "-").font(.caption).foregroundStyle(.secondary) }; Spacer(); Button { editing = s } label: { Image(systemName: "pencil") }; Button(role: .destructive) { store.deleteStudent(s.id) } label: { Image(systemName: "trash") } } } }
}

struct StudentFormView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @Environment(\.dismiss) private var dismiss
    let student: Student?
    @State private var name = ""; @State private var sid = ""; @State private var classroom = ""; @State private var notes = ""
    var body: some View { NavigationStack { Form { TextField("اسم الطالب الكامل", text: $name); TextField("الرقم الأكاديمي 9 أرقام", text: $sid).keyboardType(.numberPad); Picker("الصف", selection: $classroom) { ForEach(store.classrooms) { Text($0.name).tag($0.id) } }; TextField("ملاحظات", text: $notes, axis: .vertical) }.navigationTitle(student == nil ? "طالب جديد" : "تعديل طالب").toolbar { ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("حفظ") { save() }.disabled(name.isEmpty || sid.isEmpty) } }.onAppear { name = student?.name ?? ""; sid = student?.studentID ?? "320\(Int.random(in: 100000...999999))"; classroom = student?.classroomId ?? store.classrooms.first?.id ?? ""; notes = student?.notes ?? "" } } }
    func save() { store.saveStudent(Student(id: student?.id ?? "stu_\(UUID().uuidString)", name: name, studentID: sid, classroomId: classroom, createdAt: student?.createdAt ?? Date(), notes: notes.isEmpty ? nil : notes)); dismiss() }
}

