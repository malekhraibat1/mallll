import SwiftUI

// ═══════════════════════════════════════════════
// MARK: - MODELS
// ═══════════════════════════════════════════════

struct LoadItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var watts: Double
    var hours: Double
    var quantity: Int
    
    var dailyWh: Double { watts * hours * Double(quantity) }
}

struct Project: Identifiable, Codable {
    var id = UUID()
    var clientName: String
    var siteName: String
    var loads: [LoadItem]
    var createdAt: Date
    
    var totalDailyWh: Double {
        loads.reduce(0) { $0 + $1.dailyWh }
    }
    
    var peakWatts: Double {
        loads.reduce(0) { $0 + $1.watts * Double($1.quantity) }
    }
}

// ═══════════════════════════════════════════════
// MARK: - STORE
// ═══════════════════════════════════════════════

class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    
    private let key = "saved_projects_v1"
    
    init() { load() }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func add(_ project: Project) {
        projects.append(project)
        save()
    }
    
    func delete(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        save()
    }
    
    func update(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            save()
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - APP
// ═══════════════════════════════════════════════

@main
struct SolarEngineerApp: App {
    @StateObject private var store = ProjectStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - ROOT
// ═══════════════════════════════════════════════

struct ContentView: View {
    var body: some View {
        TabView {
            ProjectsListView()
                .tabItem { Label("المشاريع", systemImage: "folder.fill") }
            
            QuickCalcView()
                .tabItem { Label("حاسبة سريعة", systemImage: "function") }
            
            AboutView()
                .tabItem { Label("حول", systemImage: "info.circle.fill") }
        }
        .accentColor(.orange)
    }
}

// ═══════════════════════════════════════════════
// MARK: - PROJECTS LIST
// ═══════════════════════════════════════════════

struct ProjectsListView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showingNew = false
    @State private var newName = ""
    @State private var newSite = ""
    
    var body: some View {
        NavigationView {
            Group {
                if store.projects.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.projects) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                projectRow(project)
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { store.delete(store.projects[$0]) }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("المشاريع", displayMode: .large)
            .navigationBarItems(trailing:
                Button(action: { showingNew = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            )
            .sheet(isPresented: $showingNew) {
                newProjectSheet
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)
            Text("لا توجد مشاريع بعد")
                .font(.title3)
                .fontWeight(.semibold)
            Text("اضغط + لإضافة أول مشروع")
                .foregroundColor(.secondary)
        }
    }
    
    func projectRow(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(p.clientName.isEmpty ? "بدون اسم" : p.clientName)
                .font(.headline)
            if !p.siteName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                    Text(p.siteName)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                    Text("\(Int(p.totalDailyWh)) Wh")
                }
                .font(.caption2)
                .foregroundColor(.orange)
                
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                    Text("\(p.loads.count) جهاز")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    var newProjectSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("معلومات المشروع")) {
                    TextField("اسم العميل", text: $newName)
                    TextField("الموقع", text: $newSite)
                }
                
                Section {
                    Button("إضافة المشروع") {
                        let p = Project(
                            clientName: newName.isEmpty ? "بدون اسم" : newName,
                            siteName: newSite,
                            loads: [],
                            createdAt: Date()
                        )
                        store.add(p)
                        newName = ""
                        newSite = ""
                        showingNew = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.orange)
                }
            }
            .navigationBarTitle("مشروع جديد", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إلغاء") { showingNew = false }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// ═══════════════════════════════════════════════
// MARK: - PROJECT DETAIL
// ═══════════════════════════════════════════════

struct ProjectDetailView: View {
    @EnvironmentObject var store: ProjectStore
    let project: Project
    
    @State private var showingAddLoad = false
    
    var currentProject: Project {
        store.projects.first { $0.id == project.id } ?? project
    }
    
    var body: some View {
        List {
            Section(header: Text("ملخص")) {
                HStack {
                    Text("الطاقة اليومية")
                    Spacer()
                    Text("\(Int(currentProject.totalDailyWh)) Wh")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                HStack {
                    Text("القدرة القصوى")
                    Spacer()
                    Text("\(Int(currentProject.peakWatts)) W")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("kWh يوميًا")
                    Spacer()
                    Text(String(format: "%.2f", currentProject.totalDailyWh / 1000))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            Section(header: Text("الأحمال (\(currentProject.loads.count))")) {
                if currentProject.loads.isEmpty {
                    Text("لا توجد أحمال بعد — اضغط + للإضافة")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(currentProject.loads) { load in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(load.name).font(.body)
                                Text("\(Int(load.watts))W × \(Int(load.hours))س × \(load.quantity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(Int(load.dailyWh)) Wh")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                    .onDelete { idx in
                        var p = currentProject
                        idx.forEach { p.loads.remove(at: $0) }
                        store.update(p)
                    }
                }
            }
            
            if !currentProject.loads.isEmpty {
                Section(header: Text("نتائج سريعة")) {
                    resultRow(
                        title: "حجم المصفوفة",
                        value: String(format: "%.2f kWp",
                                      currentProject.totalDailyWh / 1000 / (5 * 0.75)),
                        color: .orange
                    )
                    resultRow(
                        title: "عدد الألواح (550W)",
                        value: "\(Int(ceil(currentProject.totalDailyWh / 1000 / (5 * 0.75) * 1000 / 550))) لوح",
                        color: .blue
                    )
                    resultRow(
                        title: "سعة البطارية (48V)",
                        value: "\(Int(ceil(currentProject.totalDailyWh / 48 / 0.8))) Ah",
                        color: .green
                    )
                    resultRow(
                        title: "حجم الإنفرتر",
                        value: String(format: "%.1f kW",
                                      currentProject.peakWatts * 1.25 / 1000),
                        color: .purple
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(currentProject.clientName, displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { showingAddLoad = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
        )
        .sheet(isPresented: $showingAddLoad) {
            AddLoadSheet(project: currentProject)
        }
    }
    
    func resultRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - ADD LOAD SHEET
// ═══════════════════════════════════════════════

struct AddLoadSheet: View {
    @EnvironmentObject var store: ProjectStore
    @Environment(\.presentationMode) var presentationMode
    
    let project: Project
    
    @State private var name = ""
    @State private var watts: String = "100"
    @State private var hours: String = "4"
    @State private var qty: String = "1"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("الجهاز")) {
                    TextField("الاسم (مثلًا: ثلاجة)", text: $name)
                }
                
                Section(header: Text("المواصفات")) {
                    HStack {
                        Text("القدرة (W)")
                        Spacer()
                        TextField("100", text: $watts)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("ساعات التشغيل/يوم")
                        Spacer()
                        TextField("4", text: $hours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("الكمية")
                        Spacer()
                        TextField("1", text: $qty)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section {
                    Button("إضافة") {
                        guard !name.isEmpty,
                              let w = Double(watts),
                              let h = Double(hours),
                              let q = Int(qty) else { return }
                        
                        let load = LoadItem(
                            name: name,
                            watts: w,
                            hours: h,
                            quantity: q
                        )
                        var p = project
                        p.loads.append(load)
                        store.update(p)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.orange)
                }
            }
            .navigationBarTitle("حمل جديد", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// ═══════════════════════════════════════════════
// MARK: - QUICK CALC
// ═══════════════════════════════════════════════

struct QuickCalcView: View {
    @State private var dailyKWh: String = "20"
    @State private var sunHours: String = "5.5"
    @State private var panelW: String = "550"
    
    var dailyKWhValue: Double { Double(dailyKWh) ?? 0 }
    var sunHoursValue: Double { Double(sunHours) ?? 5 }
    var panelWValue: Double { Double(panelW) ?? 550 }
    
    var arrayKWp: Double { dailyKWhValue / sunHoursValue }
    var panelCount: Int {
        guard panelWValue > 0 else { return 0 }
        return Int(ceil(arrayKWp * 1000 / panelWValue))
    }
    var inverterKW: Double { arrayKWp * 1.25 }
    var batteryAh: Double { dailyKWhValue * 1000 / 48 / 0.8 }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("المدخلات")) {
                    HStack {
                        Text("الاستهلاك اليومي (kWh)")
                        Spacer()
                        TextField("20", text: $dailyKWh)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("ساعات الشمس/يوم")
                        Spacer()
                        TextField("5.5", text: $sunHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("قدرة اللوح (W)")
                        Spacer()
                        TextField("550", text: $panelW)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section(header: Text("النتائج")) {
                    resultRow("حجم المصفوفة",
                              String(format: "%.2f kWp", arrayKWp),
                              .orange)
                    resultRow("عدد الألواح",
                              "\(panelCount)",
                              .blue)
                    resultRow("حجم الإنفرتر المقترح",
                              String(format: "%.1f kW", inverterKW),
                              .purple)
                    resultRow("سعة البطارية (48V)",
                              "\(Int(batteryAh)) Ah",
                              .green)
                }
                
                Section(header: Text("ملاحظات")) {
                    Text("• الحسابات تفترض معامل أداء 75%")
                    Text("• الألواح 550W افتراضية")
                    Text("• البطارية بنظام 48V")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationBarTitle("حاسبة سريعة", displayMode: .large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func resultRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - ABOUT
// ═══════════════════════════════════════════════

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("عن التطبيق")) {
                    HStack {
                        Text("الاسم")
                        Spacer()
                        Text("SolarEngineer")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("الميزات الحالية")) {
                    featureRow("إدارة المشاريع", "folder.fill")
                    featureRow("حاسبة الأحمال", "function")
                    featureRow("حفظ تلقائي محلي", "internaldrive.fill")
                }
                
                Section(header: Text("قادم قريبًا")) {
                    featureRow("إدارة العملاء", "person.2.fill")
                    featureRow("الفواتير", "doc.text.fill")
                    featureRow("الكتالوج والأسعار", "shippingbox.fill")
                    featureRow("تقارير PDF", "doc.richtext")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("حول", displayMode: .large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func featureRow(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(title)
        }
    }
}
