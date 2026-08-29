import SwiftUI

struct ClassroomsView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @State private var adding = false
    var body: some View { ScrollView { VStack(spacing: 16) { GlassCard { HStack { VStack(alignment: .leading) { Text("إدارة الصفوف والشعب").font(.title3.bold()); Text("تنظيم الطلاب حسب الصف وربط النتائج تلقائياً").font(.caption).foregroundStyle(.secondary) }; Spacer(); PrimaryButton(title: "صف جديد", icon: "plus") { adding = true } } }; LazyVGrid(columns: [GridItem(.adaptive(minimum: 260))], spacing: 14) { ForEach(store.classrooms) { c in classroomCard(c) } }.padding(.horizontal) }.padding(.vertical) }.sheet(isPresented: $adding) { ClassroomFormView() }.pageBackground() }
    func classroomCard(_ c: Classroom) -> some View { let count = store.students.filter { $0.classroomId == c.id }.count; return GlassCard { VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: "building.columns.fill").foregroundStyle(Palette.indigo); Spacer(); Button(role: .destructive) { store.deleteClassroom(c.id) } label: { Image(systemName: "trash") } }; Text(c.name).font(.headline); Text(c.description ?? "-").font(.caption).foregroundStyle(.secondary); MetricTile(title: "عدد الطلاب", value: "\(count)", icon: "person.3.fill", tint: Palette.emerald) } } }
}

struct ClassroomFormView: View {
    @EnvironmentObject private var store: SmartGradeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""; @State private var grade = ""; @State private var desc = ""
    var body: some View { NavigationStack { Form { TextField("اسم الصف", text: $name); TextField("المرحلة", text: $grade); TextField("وصف", text: $desc, axis: .vertical) }.navigationTitle("صف جديد").toolbar { ToolbarItem(placement: .cancellationAction) { Button("إلغاء") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("حفظ") { store.saveClassroom(Classroom(id: "class_\(UUID().uuidString)", name: name, grade: grade, createdAt: Date(), description: desc)); dismiss() }.disabled(name.isEmpty) } } } }
}

