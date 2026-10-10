import SwiftUI
import UIKit

// ═══════════════════════════════════════════════════════════
// MARK: - MODELS
// ═══════════════════════════════════════════════════════════

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
    var clientId: UUID?
    var clientName: String
    var siteName: String
    var notes: String = ""
    var loads: [LoadItem] = []
    var createdAt: Date = Date()
    
    var totalDailyWh: Double { loads.reduce(0) { $0 + $1.dailyWh } }
    var peakWatts: Double { loads.reduce(0) { $0 + $1.watts * Double($1.quantity) } }
    var suggestedKWp: Double { totalDailyWh / 1000 / (5 * 0.75) }
    var panelCount: Int {
        guard totalDailyWh > 0 else { return 0 }
        return Int(ceil(suggestedKWp * 1000 / 550))
    }
    var batteryAh: Int {
        guard totalDailyWh > 0 else { return 0 }
        return Int(ceil(totalDailyWh / 48 / 0.8))
    }
    var inverterKW: Double { peakWatts * 1.25 / 1000 }
}

struct Client: Identifiable, Codable {
    var id = UUID()
    var fullName: String
    var companyName: String = ""
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
}

struct InvoiceItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var detail: String = ""
    var quantity: Double = 1
    var unitPrice: Double = 0
    var unit: String = "قطعة"
    var lineTotal: Double { quantity * unitPrice }
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "مسودة"
    case sent = "مُرسلة"
    case paid = "مدفوعة"
    case overdue = "متأخرة"
    case cancelled = "ملغاة"
}

struct Invoice: Identifiable, Codable {
    var id = UUID()
    var number: String
    var clientId: UUID?
    var clientName: String = ""
    var clientAddress: String = ""
    var items: [InvoiceItem] = []
    var statusRaw: String = InvoiceStatus.draft.rawValue
    var issuedAt: Date = Date()
    var dueAt: Date = Date().addingTimeInterval(30 * 86400)
    var taxRate: Double = 15
    var discount: Double = 0
    var notes: String = ""
    var paidAmount: Double = 0
    
    var status: InvoiceStatus {
        get { InvoiceStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
    var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    var taxAmount: Double { (subtotal - discount) * (taxRate / 100) }
    var total: Double { max(subtotal - discount, 0) + taxAmount }
    var balanceDue: Double { max(total - paidAmount, 0) }
    var paidRatio: Double { total > 0 ? min(paidAmount / total, 1) : 0 }
}

struct Product: Identifiable, Codable {
    var id = UUID()
    var name: String
    var brand: String = ""
    var category: String = "لوح شمسي"
    var unit: String = "قطعة"
    var costPrice: Double = 0
    var salePrice: Double = 0
    var stock: Double = 0
    var notes: String = ""
    
    var profit: Double { salePrice - costPrice }
    var profitMargin: Double {
        guard salePrice > 0 else { return 0 }
        return (profit / salePrice) * 100
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - STORE
// ═══════════════════════════════════════════════════════════

class AppStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var clients: [Client] = []
    @Published var invoices: [Invoice] = []
    @Published var products: [Product] = []
    @Published var baseCurrency: String = "SAR"
    
    private let projectsKey = "solar_projects_v1"
    private let clientsKey = "solar_clients_v1"
    private let invoicesKey = "solar_invoices_v1"
    private let productsKey = "solar_products_v1"
    private let currencyKey = "solar_currency_v1"
    
    init() {
        loadAll()
        if products.isEmpty { seedProducts() }
    }
    
    func loadAll() {
        projects = load(projectsKey) ?? []
        clients = load(clientsKey) ?? []
        invoices = load(invoicesKey) ?? []
        products = load(productsKey) ?? []
        baseCurrency = UserDefaults.standard.string(forKey: currencyKey) ?? "SAR"
    }
    
    private func load<T: Codable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func save<T: Codable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func addProject(_ p: Project) { projects.append(p); save(projects, key: projectsKey) }
    func updateProject(_ p: Project) {
        if let i = projects.firstIndex(where: { $0.id == p.id }) {
            projects[i] = p; save(projects, key: projectsKey)
        }
    }
    func deleteProject(_ p: Project) {
        projects.removeAll { $0.id == p.id }; save(projects, key: projectsKey)
    }
    
    func addClient(_ c: Client) { clients.append(c); save(clients, key: clientsKey) }
    func updateClient(_ c: Client) {
        if let i = clients.firstIndex(where: { $0.id == c.id }) {
            clients[i] = c; save(clients, key: clientsKey)
        }
    }
    func deleteClient(_ c: Client) {
        clients.removeAll { $0.id == c.id }; save(clients, key: clientsKey)
    }
    
    func addInvoice(_ inv: Invoice) { invoices.append(inv); save(invoices, key: invoicesKey) }
    func updateInvoice(_ inv: Invoice) {
        if let i = invoices.firstIndex(where: { $0.id == inv.id }) {
            invoices[i] = inv; save(invoices, key: invoicesKey)
        }
    }
    func deleteInvoice(_ inv: Invoice) {
        invoices.removeAll { $0.id == inv.id }; save(invoices, key: invoicesKey)
    }
    
    func nextInvoiceNumber() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let prefix = "INV-\(year)-"
        let seq = invoices.filter { $0.number.hasPrefix(prefix) }.count + 1
        return "\(prefix)\(String(format: "%03d", seq))"
    }
    
    func addProduct(_ p: Product) { products.append(p); save(products, key: productsKey) }
    func updateProduct(_ p: Product) {
        if let i = products.firstIndex(where: { $0.id == p.id }) {
            products[i] = p; save(products, key: productsKey)
        }
    }
    func deleteProduct(_ p: Product) {
        products.removeAll { $0.id == p.id }; save(products, key: productsKey)
    }
    
    func setBaseCurrency(_ c: String) {
        baseCurrency = c
        UserDefaults.standard.set(c, forKey: currencyKey)
    }
    
    private func seedProducts() {
        let samples: [(String, String, String, Double, Double)] = [
            ("لوح شمسي 550W", "Generic", "لوح شمسي", 480, 720),
            ("لوح شمسي 450W", "Generic", "لوح شمسي", 380, 580),
            ("إنفرتر هجين 5kW", "Generic", "إنفرتر", 2800, 4200),
            ("إنفرتر هجين 8kW", "Generic", "إنفرتر", 4200, 6100),
            ("بطارية ليثيوم 48V 100Ah", "Generic", "بطارية", 4800, 6800),
            ("بطارية جل 12V 200Ah", "Generic", "بطارية", 1200, 1800),
            ("قاعدة تركيب أسطح", "Generic", "قواعد", 85, 140),
            ("كابل DC 6mm", "Generic", "كابل", 8, 15),
            ("مانع صواعق DC", "Generic", "حمايات", 180, 320),
            ("قاطع DC", "Generic", "حمايات", 90, 180),
            ("أعمال تركيب", "Generic", "خدمات", 0, 350),
        ]
        for s in samples {
            let p = Product(name: s.0, brand: s.1, category: s.2,
                            costPrice: s.3, salePrice: s.4)
            products.append(p)
        }
        save(products, key: productsKey)
    }
    
    var totalRevenue: Double {
        invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
    }
    var totalOutstanding: Double {
        invoices.filter { $0.balanceDue > 0 }.reduce(0) { $0 + $1.balanceDue }
    }
    var totalKWp: Double {
        projects.reduce(0) { $0 + $1.suggestedKWp }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - APP
// ═══════════════════════════════════════════════════════════

@main
struct SolarEngineerApp: App {
    @StateObject private var store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - ROOT
// ═══════════════════════════════════════════════════════════

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }
            ProjectsListView()
                .tabItem { Label("المشاريع", systemImage: "folder.fill") }
            ClientsListView()
                .tabItem { Label("العملاء", systemImage: "person.2.fill") }
            InvoicesListView()
                .tabItem { Label("الفواتير", systemImage: "doc.text.fill") }
            MoreView()
                .tabItem { Label("المزيد", systemImage: "ellipsis.circle.fill") }
        }
        .accentColor(.orange)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - DASHBOARD
// ═══════════════════════════════════════════════════════════

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("مرحبًا 👋")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                Text("مهندس الطاقة")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        
                        Divider().background(Color.white.opacity(0.3))
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("\(store.projects.count)")
                                    .font(.title).fontWeight(.bold).foregroundColor(.white)
                                Text("مشروع").font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            VStack(alignment: .leading) {
                                Text("\(store.clients.count)")
                                    .font(.title).fontWeight(.bold).foregroundColor(.white)
                                Text("عميل").font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            VStack(alignment: .leading) {
                                Text(String(format: "%.1f", store.totalKWp))
                                    .font(.title).fontWeight(.bold).foregroundColor(.white)
                                Text("kWp").font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        statCard(title: "المحصّل",
                                 value: "\(Int(store.totalRevenue))",
                                 unit: store.baseCurrency,
                                 icon: "checkmark.circle.fill",
                                 color: .green)
                        statCard(title: "المستحق",
                                 value: "\(Int(store.totalOutstanding))",
                                 unit: store.baseCurrency,
                                 icon: "clock.fill",
                                 color: .orange)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("إجراءات سريعة").font(.headline).padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            NavigationLink(destination: QuickCalcView()) {
                                quickAction(icon: "function", title: "حاسبة PV", color: .blue)
                            }
                            NavigationLink(destination: BatteryCalcView()) {
                                quickAction(icon: "battery.100", title: "بطاريات", color: .green)
                            }
                            NavigationLink(destination: CableCalcView()) {
                                quickAction(icon: "ruler", title: "كابلات", color: .purple)
                            }
                            NavigationLink(destination: CatalogView()) {
                                quickAction(icon: "shippingbox.fill", title: "الكتالوج", color: .orange)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if !store.projects.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("أحدث المشاريع").font(.headline).padding(.horizontal)
                            
                            ForEach(store.projects.suffix(3).reversed()) { p in
                                NavigationLink(destination: ProjectDetailView(project: p)) {
                                    HStack {
                                        Image(systemName: "sun.max.fill")
                                            .foregroundColor(.orange)
                                            .frame(width: 36, height: 36)
                                            .background(Color.orange.opacity(0.15))
                                            .cornerRadius(10)
                                        VStack(alignment: .leading) {
                                            Text(p.clientName).font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("\(p.loads.count) حمل · \(Int(p.totalDailyWh)) Wh")
                                                .font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitle("لوحة التحكم", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func statCard(title: String, value: String, unit: String,
                  icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.title3)
            Text(title).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title2).fontWeight(.bold)
                Text(unit).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }
    
    func quickAction(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(title).font(.subheadline).foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - PROJECTS
// ═══════════════════════════════════════════════════════════

struct ProjectsListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingNew = false
    @State private var newName = ""
    @State private var newSite = ""
    
    var body: some View {
        NavigationView {
            Group {
                if store.projects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 70)).foregroundColor(.orange)
                        Text("لا توجد مشاريع").font(.title3).fontWeight(.semibold)
                        Text("اضغط + لإضافة أول مشروع")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(store.projects) { p in
                            NavigationLink(destination: ProjectDetailView(project: p)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(p.clientName).font(.headline)
                                    if !p.siteName.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin")
                                            Text(p.siteName)
                                        }
                                        .font(.caption).foregroundColor(.secondary)
                                    }
                                    HStack(spacing: 12) {
                                        Label("\(Int(p.totalDailyWh)) Wh",
                                              systemImage: "bolt.fill")
                                            .font(.caption2).foregroundColor(.orange)
                                        Label("\(p.loads.count) جهاز",
                                              systemImage: "list.bullet")
                                            .font(.caption2).foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { store.deleteProject(store.projects[$0]) }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("المشاريع", displayMode: .large)
            .navigationBarItems(trailing:
                Button(action: { showingNew = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundColor(.orange)
                }
            )
            .sheet(isPresented: $showingNew) {
                NavigationView {
                    Form {
                        Section(header: Text("معلومات المشروع")) {
                            TextField("اسم العميل", text: $newName)
                            TextField("الموقع", text: $newSite)
                        }
                        Section {
                            Button("إضافة") {
                                let p = Project(
                                    clientName: newName.isEmpty ? "بدون اسم" : newName,
                                    siteName: newSite
                                )
                                store.addProject(p)
                                newName = ""; newSite = ""
                                showingNew = false
                            }
                            .frame(maxWidth: .infinity).foregroundColor(.orange)
                        }
                    }
                    .navigationBarTitle("مشروع جديد", displayMode: .inline)
                    .navigationBarItems(trailing: Button("إلغاء") { showingNew = false })
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ProjectDetailView: View {
    @EnvironmentObject var store: AppStore
    let project: Project
    @State private var showingAddLoad = false
    @State private var showingPDF = false
    
    var current: Project {
        store.projects.first { $0.id == project.id } ?? project
    }
    
    var body: some View {
        List {
            Section(header: Text("ملخص")) {
                row("الطاقة اليومية", "\(Int(current.totalDailyWh)) Wh", .orange)
                row("القدرة القصوى", "\(Int(current.peakWatts)) W", .blue)
                row("kWh/يوم", String(format: "%.2f", current.totalDailyWh / 1000), .green)
            }
            
            Section(header: Text("الأحمال (\(current.loads.count))")) {
                if current.loads.isEmpty {
                    Text("اضغط + لإضافة حمل").font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(current.loads) { load in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(load.name)
                                Text("\(Int(load.watts))W × \(Int(load.hours))س × \(load.quantity)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(Int(load.dailyWh)) Wh")
                                .font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                        }
                    }
                    .onDelete { idx in
                        var p = current
                        idx.forEach { p.loads.remove(at: $0) }
                        store.updateProject(p)
                    }
                }
            }
            
            if !current.loads.isEmpty {
                Section(header: Text("نتائج سريعة")) {
                    row("حجم المصفوفة",
                        String(format: "%.2f kWp", current.suggestedKWp), .orange)
                    row("عدد الألواح (550W)", "\(current.panelCount)", .blue)
                    row("البطارية (48V)", "\(current.batteryAh) Ah", .green)
                    row("الإنفرتر",
                        String(format: "%.1f kW", current.inverterKW), .purple)
                }
            }
            
            Section {
                Button(action: { showingPDF = true }) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("معاينة التقرير")
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(current.clientName, displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { showingAddLoad = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundColor(.orange)
            }
        )
        .sheet(isPresented: $showingAddLoad) {
            AddLoadSheet(project: current)
        }
        .sheet(isPresented: $showingPDF) {
            PDFPreview(project: current)
        }
    }
    
    func row(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.bold).foregroundColor(color)
        }
    }
}

struct AddLoadSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    let project: Project
    
    @State private var name = ""
    @State private var watts = "100"
    @State private var hours = "4"
    @State private var qty = "1"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("الجهاز")) {
                    TextField("الاسم", text: $name)
                }
                Section(header: Text("المواصفات")) {
                    fieldRow("القدرة (W)", $watts, .decimalPad)
                    fieldRow("ساعات/يوم", $hours, .decimalPad)
                    fieldRow("الكمية", $qty, .numberPad)
                }
                Section {
                    Button("إضافة") {
                        guard !name.isEmpty,
                              let w = Double(watts),
                              let h = Double(hours),
                              let q = Int(qty) else { return }
                        var p = project
                        p.loads.append(LoadItem(name: name, watts: w,
                                                 hours: h, quantity: q))
                        store.updateProject(p)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity).foregroundColor(.orange)
                }
            }
            .navigationBarTitle("حمل جديد", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func fieldRow(_ label: String, _ binding: Binding<String>,
                  _ kb: UIKeyboardType) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: binding)
                .keyboardType(kb)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - CLIENTS
// ═══════════════════════════════════════════════════════════

struct ClientsListView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var showingNew = false
    @State private var newName = ""
    
    var filtered: [Client] {
        if search.isEmpty { return store.clients }
        return store.clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(search) ||
            $0.phone.contains(search)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if store.clients.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 70)).foregroundColor(.orange)
                        Text("لا يوجد عملاء").font(.title3).fontWeight(.semibold)
                        Text("اضغط + لإضافة أول عميل")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(filtered) { c in
                            NavigationLink(destination: ClientDetailView(client: c)) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange,
                                                         Color.orange.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(initials(c.fullName))
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                        )
                                    VStack(alignment: .leading) {
                                        Text(c.fullName).font(.headline)
                                        if !c.phone.isEmpty {
                                            Text(c.phone).font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { store.deleteClient(filtered[$0]) }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("العملاء", displayMode: .large)
            .navigationBarItems(trailing:
                Button(action: { showingNew = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundColor(.orange)
                }
            )
            .sheet(isPresented: $showingNew) {
                NavigationView {
                    Form {
                        TextField("الاسم الكامل", text: $newName)
                        Section {
                            Button("إضافة") {
                                store.addClient(Client(fullName: newName))
                                newName = ""
                                showingNew = false
                            }
                            .frame(maxWidth: .infinity).foregroundColor(.orange)
                        }
                    }
                    .navigationBarTitle("عميل جديد", displayMode: .inline)
                    .navigationBarItems(trailing:
                        Button("إلغاء") { showingNew = false }
                    )
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func initials(_ s: String) -> String {
        let parts = s.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }
}

struct ClientDetailView: View {
    @EnvironmentObject var store: AppStore
    let client: Client
    @State private var edited: Client
    
    init(client: Client) {
        self.client = client
        self._edited = State(initialValue: client)
    }
    
    var body: some View {
        Form {
            Section(header: Text("المعلومات")) {
                TextField("الاسم", text: $edited.fullName)
                TextField("الشركة", text: $edited.companyName)
                TextField("الهاتف", text: $edited.phone).keyboardType(.phonePad)
                TextField("البريد", text: $edited.email).keyboardType(.emailAddress)
                TextField("العنوان", text: $edited.address)
            }
            Section(header: Text("ملاحظات")) {
                TextField("ملاحظات", text: $edited.notes)
            }
            Section {
                Button("حفظ") { store.updateClient(edited) }
                    .foregroundColor(.orange)
            }
        }
        .navigationBarTitle(client.fullName, displayMode: .inline)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - INVOICES
// ═══════════════════════════════════════════════════════════

struct InvoicesListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingNew = false
    
    var body: some View {
        NavigationView {
            Group {
                if store.invoices.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 70)).foregroundColor(.orange)
                        Text("لا توجد فواتير").font(.title3).fontWeight(.semibold)
                        Text("اضغط + لإنشاء أول فاتورة")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(store.invoices.sorted(by: { $0.issuedAt > $1.issuedAt })) { inv in
                            NavigationLink(destination: InvoiceEditorView(invoiceId: inv.id)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(inv.number).font(.subheadline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("\(Int(inv.total)) \(store.baseCurrency)")
                                            .font(.subheadline).fontWeight(.bold)
                                            .foregroundColor(.orange)
                                    }
                                    HStack {
                                        Text(inv.clientName.isEmpty ? "بدون عميل" : inv.clientName)
                                            .font(.caption).foregroundColor(.secondary)
                                        Spacer()
                                        statusBadge(inv.status)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { idx in
                            let sorted = store.invoices.sorted(by: { $0.issuedAt > $1.issuedAt })
                            idx.forEach { store.deleteInvoice(sorted[$0]) }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("الفواتير", displayMode: .large)
            .navigationBarItems(trailing:
                Button(action: { showingNew = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundColor(.orange)
                }
            )
            .sheet(isPresented: $showingNew) {
                NavigationView { InvoiceEditorView(invoiceId: nil) }
                    .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func statusBadge(_ s: InvoiceStatus) -> some View {
        Text(s.rawValue)
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(colorFor(s).opacity(0.15))
            .foregroundColor(colorFor(s))
            .cornerRadius(6)
    }
    
    func colorFor(_ s: InvoiceStatus) -> Color {
        switch s {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .secondary
        }
    }
}

struct InvoiceEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    
    let invoiceId: UUID?
    @State private var invoice: Invoice = Invoice(number: "")
    @State private var showingAddItem = false
    @State private var showingPDF = false
    @State private var isNew = true
    @State private var hasSetup = false
    
    var body: some View {
        Form {
            Section(header: Text("الفاتورة")) {
                TextField("الرقم", text: $invoice.number)
                DatePicker("التاريخ", selection: $invoice.issuedAt,
                           displayedComponents: .date)
                DatePicker("الاستحقاق", selection: $invoice.dueAt,
                           displayedComponents: .date)
                Picker("الحالة", selection: Binding(
                    get: { invoice.status },
                    set: { invoice.status = $0 }
                )) {
                    ForEach(InvoiceStatus.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
            }
            
            Section(header: Text("العميل")) {
                Picker("اختر العميل", selection: Binding(
                    get: { invoice.clientId },
                    set: { newId in
                        invoice.clientId = newId
                        if let c = store.clients.first(where: { $0.id == newId }) {
                            invoice.clientName = c.fullName
                            invoice.clientAddress = c.address
                        }
                    }
                )) {
                    Text("بدون").tag(UUID?.none)
                    ForEach(store.clients) { c in
                        Text(c.fullName).tag(c.id as UUID?)
                    }
                }
            }
            
            Section(header: Text("البنود (\(invoice.items.count))")) {
                ForEach(invoice.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.title).font(.subheadline)
                            Text("\(item.quantity, specifier: "%.0f") × \(item.unitPrice, specifier: "%.0f") \(item.unit)")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(item.lineTotal, specifier: "%.0f")")
                            .fontWeight(.semibold)
                    }
                }
                .onDelete { idx in
                    idx.forEach { invoice.items.remove(at: $0) }
                }
                Button(action: { showingAddItem = true }) {
                    Label("إضافة بند", systemImage: "plus.circle")
                }
                .foregroundColor(.orange)
            }
            
            Section(header: Text("الضرائب")) {
                HStack {
                    Text("ضريبة %")
                    Spacer()
                    TextField("15", value: $invoice.taxRate, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                HStack {
                    Text("خصم")
                    Spacer()
                    TextField("0", value: $invoice.discount, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            Section(header: Text("الملخص")) {
                row("المجموع", invoice.subtotal, .primary)
                row("خصم", invoice.discount, .red)
                row("ضريبة", invoice.taxAmount, .secondary)
                HStack {
                    Text("الإجمالي").fontWeight(.bold)
                    Spacer()
                    Text("\(Int(invoice.total)) \(store.baseCurrency)")
                        .fontWeight(.bold).foregroundColor(.orange)
                }
            }
            
            Section(header: Text("الدفع")) {
                HStack {
                    Text("مدفوع")
                    Spacer()
                    TextField("0", value: $invoice.paidAmount, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("المتبقي")
                    Spacer()
                    Text("\(Int(invoice.balanceDue)) \(store.baseCurrency)")
                        .fontWeight(.bold)
                        .foregroundColor(invoice.balanceDue > 0 ? .red : .green)
                }
            }
            
            Section {
                Button(action: { showingPDF = true }) {
                    Label("معاينة الفاتورة", systemImage: "doc.richtext")
                }
                .foregroundColor(.orange)
                Button("حفظ") {
                    save()
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity).foregroundColor(.orange)
            }
        }
        .navigationBarTitle(isNew ? "فاتورة جديدة" : invoice.number, displayMode: .inline)
        .navigationBarItems(trailing:
            Button("تم") {
                save()
                presentationMode.wrappedValue.dismiss()
            }
        )
        .onAppear {
            if !hasSetup {
                setupInitial()
                hasSetup = true
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInvoiceItemSheet(invoice: $invoice)
        }
        .sheet(isPresented: $showingPDF) {
            InvoicePDFPreview(invoice: invoice, currency: store.baseCurrency)
        }
    }
    
    func row(_ title: String, _ value: Double, _ color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value, specifier: "%.2f")").foregroundColor(color)
        }
    }
    
    func setupInitial() {
        if let id = invoiceId,
           let existing = store.invoices.first(where: { $0.id == id }) {
            invoice = existing
            isNew = false
        } else {
            invoice.number = store.nextInvoiceNumber()
        }
    }
    
    func save() {
        if isNew {
            store.addInvoice(invoice)
            isNew = false
        } else {
            store.updateInvoice(invoice)
        }
    }
}

struct AddInvoiceItemSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var invoice: Invoice
    
    @State private var title = ""
    @State private var detail = ""
    @State private var quantity = "1"
    @State private var price = "0"
    @State private var unit = "قطعة"
    
    var body: some View {
        NavigationView {
            Form {
                TextField("العنوان", text: $title)
                TextField("الوصف", text: $detail)
                Picker("الوحدة", selection: $unit) {
                    ForEach(["قطعة", "متر", "ساعة", "لوح", "كيلوواط", "خدمة"],
                            id: \.self) {
                        Text($0)
                    }
                }
                HStack {
                    Text("الكمية")
                    Spacer()
                    TextField("1", text: $quantity)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("السعر")
                    Spacer()
                    TextField("0", text: $price)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                Section {
                    Button("إضافة") {
                        guard !title.isEmpty,
                              let q = Double(quantity),
                              let p = Double(price) else { return }
                        invoice.items.append(InvoiceItem(
                            title: title, detail: detail,
                            quantity: q, unitPrice: p, unit: unit
                        ))
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity).foregroundColor(.orange)
                }
            }
            .navigationBarTitle("بند جديد", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - MORE MENU
// ═══════════════════════════════════════════════════════════

struct MoreView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("الحاسبات")) {
                    NavigationLink(destination: QuickCalcView()) {
                        Label("حاسبة PV", systemImage: "function")
                    }
                    NavigationLink(destination: BatteryCalcView()) {
                        Label("حاسبة البطاريات", systemImage: "battery.100")
                    }
                    NavigationLink(destination: CableCalcView()) {
                        Label("حاسبة الكابلات", systemImage: "ruler")
                    }
                }
                Section(header: Text("الإدارة")) {
                    NavigationLink(destination: CatalogView()) {
                        Label("كتالوج المنتجات", systemImage: "shippingbox.fill")
                    }
                    NavigationLink(destination: ReportsView()) {
                        Label("التقارير", systemImage: "chart.bar.fill")
                    }
                }
                Section(header: Text("الإعدادات")) {
                    NavigationLink(destination: SettingsView()) {
                        Label("الإعدادات", systemImage: "gearshape.fill")
                    }
                    NavigationLink(destination: AboutView()) {
                        Label("حول التطبيق", systemImage: "info.circle.fill")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("المزيد", displayMode: .large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - CATALOG
// ═══════════════════════════════════════════════════════════

struct CatalogView: View {
    @EnvironmentObject var store: AppStore
    @State private var search = ""
    @State private var selectedCategory: String? = nil
    @State private var showingNew = false
    @State private var editing: Product?
    
    var categories: [String] {
        Array(Set(store.products.map { $0.category })).sorted()
    }
    
    var filtered: [Product] {
        var list = store.products
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }
        if !search.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(search) ||
                $0.brand.localizedCaseInsensitiveContains(search)
            }
        }
        return list
    }
    
    var body: some View {
        List {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    chip("الكل", selectedCategory == nil) { selectedCategory = nil }
                    ForEach(categories, id: \.self) { c in
                        chip(c, selectedCategory == c) { selectedCategory = c }
                    }
                }
                .padding(.vertical, 6)
            }
            .listRowInsets(EdgeInsets())
            
            ForEach(filtered) { p in
                Button(action: { editing = p }) {
                    HStack(spacing: 12) {
                        Image(systemName: iconFor(p.category))
                            .foregroundColor(.orange)
                            .frame(width: 40, height: 40)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(10)
                        VStack(alignment: .leading) {
                            Text(p.name).font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.primary)
                            if !p.brand.isEmpty {
                                Text(p.brand).font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(Int(p.salePrice))").font(.subheadline)
                                .fontWeight(.bold).foregroundColor(.orange)
                            if p.profitMargin > 0 {
                                Text("+\(Int(p.profitMargin))%")
                                    .font(.caption2).foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .onDelete { idx in
                idx.forEach { store.deleteProduct(filtered[$0]) }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("الكتالوج", displayMode: .large)
        .navigationBarItems(trailing:
            Button(action: { showingNew = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundColor(.orange)
            }
        )
        .sheet(isPresented: $showingNew) {
            NavigationView { ProductEditorView(product: nil) }
        }
        .sheet(item: $editing) { p in
            NavigationView { ProductEditorView(product: p) }
        }
    }
    
    func chip(_ title: String, _ selected: Bool,
              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(selected ? Color.orange : Color.gray.opacity(0.15))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    func iconFor(_ category: String) -> String {
        switch category {
        case "لوح شمسي": return "sun.max.fill"
        case "إنفرتر": return "bolt.fill"
        case "بطارية": return "battery.100"
        case "قواعد": return "wrench.fill"
        case "كابل": return "cable.connector"
        case "حمايات": return "shield.fill"
        case "خدمات": return "hammer.fill"
        default: return "shippingbox.fill"
        }
    }
}

struct ProductEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    
    let product: Product?
    @State private var draft = Product(name: "")
    @State private var isNew = true
    @State private var hasSetup = false
    
    let categories = ["لوح شمسي", "إنفرتر", "بطارية", "قواعد",
                      "كابل", "حمايات", "ملحقات", "خدمات"]
    
    var body: some View {
        Form {
            Section(header: Text("معلومات")) {
                TextField("الاسم", text: $draft.name)
                TextField("العلامة التجارية", text: $draft.brand)
                Picker("التصنيف", selection: $draft.category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
                Picker("الوحدة", selection: $draft.unit) {
                    ForEach(["قطعة", "متر", "متر مربع", "كيلوواط", "خدمة"],
                            id: \.self) {
                        Text($0)
                    }
                }
            }
            Section(header: Text("الأسعار")) {
                HStack {
                    Text("التكلفة")
                    Spacer()
                    TextField("0", value: $draft.costPrice,
                              formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                HStack {
                    Text("سعر البيع")
                    Spacer()
                    TextField("0", value: $draft.salePrice,
                              formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                HStack {
                    Text("الهامش")
                    Spacer()
                    Text("\(Int(draft.profitMargin))%")
                        .foregroundColor(.green).fontWeight(.bold)
                }
            }
            Section(header: Text("المخزون")) {
                HStack {
                    Text("الكمية")
                    Spacer()
                    TextField("0", value: $draft.stock,
                              formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            Section(header: Text("ملاحظات")) {
                TextField("ملاحظات", text: $draft.notes)
            }
            Section {
                Button("حفظ") {
                    if isNew {
                        store.addProduct(draft)
                    } else {
                        store.updateProduct(draft)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity).foregroundColor(.orange)
            }
        }
        .navigationBarTitle(isNew ? "منتج جديد" : "تعديل", displayMode: .inline)
        .navigationBarItems(trailing:
            Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
        )
        .onAppear {
            if !hasSetup, let p = product {
                draft = p
                isNew = false
                hasSetup = true
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - CALCULATORS
// ═══════════════════════════════════════════════════════════

struct QuickCalcView: View {
    @State private var dailyKWh = "20"
    @State private var sunHours = "5.5"
    @State private var panelW = "550"
    
    var dailyValue: Double { Double(dailyKWh) ?? 0 }
    var sunValue: Double { Double(sunHours) ?? 5 }
    var panelValue: Double { Double(panelW) ?? 550 }
    var arrayKWp: Double { dailyValue / max(sunValue, 0.1) }
    var panelCount: Int {
        guard panelValue > 0 else { return 0 }
        return Int(ceil(arrayKWp * 1000 / panelValue))
    }
    var inverterKW: Double { arrayKWp * 1.25 }
    var batteryAh: Double { dailyValue * 1000 / 48 / 0.8 }
    
    var body: some View {
        Form {
            Section(header: Text("المدخلات")) {
                inputRow("الاستهلاك اليومي (kWh)", $dailyKWh)
                inputRow("ساعات الشمس/يوم", $sunHours)
                inputRow("قدرة اللوح (W)", $panelW)
            }
            Section(header: Text("النتائج")) {
                resultRow("حجم المصفوفة",
                          String(format: "%.2f kWp", arrayKWp), .orange)
                resultRow("عدد الألواح", "\(panelCount)", .blue)
                resultRow("الإنفرتر المقترح",
                          String(format: "%.1f kW", inverterKW), .purple)
                resultRow("البطارية (48V)", "\(Int(batteryAh)) Ah", .green)
            }
            Section(header: Text("ملاحظات")) {
                Text("• معامل الأداء: 75%").font(.caption)
                Text("• الألواح 550W افتراضية").font(.caption)
            }
        }
        .navigationBarTitle("حاسبة PV", displayMode: .inline)
    }
    
    func inputRow(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
    
    func resultRow(_ t: String, _ v: String, _ c: Color) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v).fontWeight(.bold).foregroundColor(c)
        }
    }
}

struct BatteryCalcView: View {
    @State private var dailyWh = "5000"
    @State private var autonomy = "2"
    @State private var systemV = "48"
    @State private var dod = "0.8"
    
    var requiredWh: Double {
        guard let d = Double(dailyWh), let a = Double(autonomy),
              let e = Double(dod) else { return 0 }
        return d * a / (e * 0.95)
    }
    var requiredAh: Double {
        guard let v = Double(systemV), v > 0 else { return 0 }
        return requiredWh / v
    }
    
    var body: some View {
        Form {
            Section(header: Text("المدخلات")) {
                inputRow("الطاقة اليومية (Wh)", $dailyWh)
                inputRow("أيام الاستقلالية", $autonomy)
                inputRow("جهد النظام (V)", $systemV)
                inputRow("عمق التفريغ (0-1)", $dod)
            }
            Section(header: Text("النتائج")) {
                resultRow("السعة المطلوبة (Wh)", "\(Int(requiredWh))", .orange)
                resultRow("السعة المطلوبة (Ah)", "\(Int(requiredAh))", .green)
                resultRow("بطاريات 100Ah",
                          "\(Int(ceil(requiredAh / 100)))", .blue)
                resultRow("بطاريات 200Ah",
                          "\(Int(ceil(requiredAh / 200)))", .purple)
            }
        }
        .navigationBarTitle("حاسبة البطاريات", displayMode: .inline)
    }
    
    func inputRow(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
    
    func resultRow(_ t: String, _ v: String, _ c: Color) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v).fontWeight(.bold).foregroundColor(c)
        }
    }
}

struct CableCalcView: View {
    @State private var length = "20"
    @State private var current = "10"
    @State private var voltage = "48"
    @State private var area = "6"
    
    let rho = 0.01724
    
    var voltageDrop: Double {
        guard let l = Double(length),
              let i = Double(current),
              let a = Double(area), a > 0 else { return 0 }
        let r = 2 * l * rho / a
        return r * i
    }
    var dropPercent: Double {
        guard let v = Double(voltage), v > 0 else { return 0 }
        return (voltageDrop / v) * 100
    }
    
    var body: some View {
        Form {
            Section(header: Text("المدخلات")) {
                inputRow("طول الكابل (م)", $length)
                inputRow("التيار (A)", $current)
                inputRow("الجهد (V)", $voltage)
                inputRow("مقطع الكابل (mm²)", $area)
            }
            Section(header: Text("النتائج")) {
                resultRow("هبوط الجهد",
                          String(format: "%.3f V", voltageDrop),
                          dropPercent > 3 ? .red : .green)
                resultRow("نسبة الهبوط",
                          String(format: "%.2f%%", dropPercent),
                          dropPercent > 3 ? .red : .green)
                Text(dropPercent > 3 ?
                     "⚠️ الهبوط أكبر من 3% — زد مقطع الكابل" :
                     "✓ الهبوط مقبول (< 3%)")
                    .font(.caption)
                    .foregroundColor(dropPercent > 3 ? .red : .green)
            }
        }
        .navigationBarTitle("حاسبة الكابلات", displayMode: .inline)
    }
    
    func inputRow(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
    
    func resultRow(_ t: String, _ v: String, _ c: Color) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v).fontWeight(.bold).foregroundColor(c)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - REPORTS
// ═══════════════════════════════════════════════════════════

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    
    var totalInvoiced: Double { store.invoices.reduce(0) { $0 + $1.total } }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()),
                                    GridItem(.flexible())], spacing: 12) {
                    kpiCard("إجمالي الفواتير", totalInvoiced, .blue, "doc.text.fill")
                    kpiCard("المحصّل", store.totalRevenue, .green,
                            "checkmark.circle.fill")
                    kpiCard("المستحق", store.totalOutstanding, .orange, "clock.fill")
                    kpiCard("عدد الفواتير", Double(store.invoices.count),
                            .purple, "number.circle.fill")
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("المشاريع").font(.headline).padding(.horizontal)
                    HStack(spacing: 12) {
                        miniStat("المشاريع", "\(store.projects.count)", .blue)
                        miniStat("العملاء", "\(store.clients.count)", .green)
                        miniStat("kWp",
                                 String(format: "%.1f", store.totalKWp), .orange)
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("حالات الفواتير").font(.headline).padding(.horizontal)
                    ForEach(InvoiceStatus.allCases, id: \.self) { s in
                        let count = store.invoices.filter { $0.status == s }.count
                        if count > 0 {
                            HStack {
                                Circle().fill(colorFor(s))
                                    .frame(width: 10, height: 10)
                                Text(s.rawValue)
                                Spacer()
                                Text("\(count)").fontWeight(.bold)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitle("التقارير", displayMode: .large)
    }
    
    func kpiCard(_ title: String, _ value: Double,
                 _ color: Color, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.title3)
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(Int(value))").font(.title3).fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }
    
    func miniStat(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack {
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
    
    func colorFor(_ s: InvoiceStatus) -> Color {
        switch s {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .secondary
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - SETTINGS
// ═══════════════════════════════════════════════════════════

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    
    let currencies = ["SAR", "AED", "EGP", "USD", "EUR",
                      "KWD", "QAR", "BHD", "OMR"]
    
    var body: some View {
        Form {
            Section(header: Text("العملة")) {
                Picker("العملة الأساسية", selection: Binding(
                    get: { store.baseCurrency },
                    set: { store.setBaseCurrency($0) }
                )) {
                    ForEach(currencies, id: \.self) { Text($0) }
                }
            }
            Section(header: Text("البيانات")) {
                HStack {
                    Text("المشاريع")
                    Spacer()
                    Text("\(store.projects.count)").foregroundColor(.secondary)
                }
                HStack {
                    Text("العملاء")
                    Spacer()
                    Text("\(store.clients.count)").foregroundColor(.secondary)
                }
                HStack {
                    Text("الفواتير")
                    Spacer()
                    Text("\(store.invoices.count)").foregroundColor(.secondary)
                }
                HStack {
                    Text("المنتجات")
                    Spacer()
                    Text("\(store.products.count)").foregroundColor(.secondary)
                }
            }
        }
        .navigationBarTitle("الإعدادات", displayMode: .large)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - ABOUT
// ═══════════════════════════════════════════════════════════

struct AboutView: View {
    var body: some View {
        List {
            Section(header: Text("التطبيق")) {
                HStack {
                    Text("الاسم")
                    Spacer()
                    Text("SolarEngineer").foregroundColor(.secondary)
                }
                HStack {
                    Text("الإصدار")
                    Spacer()
                    Text("2.0.0").foregroundColor(.secondary)
                }
            }
            Section(header: Text("الميزات")) {
                Label("إدارة المشاريع والعملاء", systemImage: "folder.fill")
                Label("الفواتير والعروض", systemImage: "doc.text.fill")
                Label("كتالوج المنتجات", systemImage: "shippingbox.fill")
                Label("حاسبات PV والبطاريات والكابلات", systemImage: "function")
                Label("حفظ محلي تلقائي", systemImage: "internaldrive.fill")
            }
            Section(header: Text("ملاحظات")) {
                Text("• البيانات محفوظة محليًا").font(.caption)
                Text("• لا يحتاج اتصال بالإنترنت").font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("حول", displayMode: .large)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - PDF PREVIEWS
// ═══════════════════════════════════════════════════════════

struct PDFPreview: View {
    let project: Project
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("تقرير نظام شمسي")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundColor(.orange)
                    Divider()
                    Text("العميل: \(project.clientName)").font(.headline)
                    Text("الموقع: \(project.siteName)")
                    Divider()
                    Text("الملخص").font(.headline)
                    Text("الطاقة اليومية: \(Int(project.totalDailyWh)) Wh")
                    Text("القدرة القصوى: \(Int(project.peakWatts)) W")
                    Divider()
                    Text("التوصيات").font(.headline)
                    Text("حجم المصفوفة: \(String(format: "%.2f kWp", project.suggestedKWp))")
                    Text("عدد الألواح: \(project.panelCount) (550W)")
                    Text("البطارية: \(project.batteryAh) Ah (48V)")
                    Text("الإنفرتر: \(String(format: "%.1f kW", project.inverterKW))")
                }
                .padding()
            }
            .navigationBarTitle("التقرير", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إغلاق") { presentationMode.wrappedValue.dismiss() }
            )
        }
    }
}

struct InvoicePDFPreview: View {
    let invoice: Invoice
    let currency: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("فاتورة")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text(invoice.number).font(.title3)
                    Divider()
                    Text("العميل: \(invoice.clientName.isEmpty ? "بدون" : invoice.clientName)")
                    Text("التاريخ: \(formatDate(invoice.issuedAt))")
                    Text("الاستحقاق: \(formatDate(invoice.dueAt))")
                    Divider()
                    Text("البنود").font(.headline)
                    ForEach(invoice.items) { item in
                        HStack {
                            Text(item.title)
                            Spacer()
                            Text("\(Int(item.lineTotal))").fontWeight(.semibold)
                        }
                    }
                    Divider()
                    HStack {
                        Text("المجموع")
                        Spacer()
                        Text("\(Int(invoice.subtotal))")
                    }
                    HStack {
                        Text("ضريبة")
                        Spacer()
                        Text("\(Int(invoice.taxAmount))")
                    }
                    HStack {
                        Text("الإجمالي").fontWeight(.bold)
                        Spacer()
                        Text("\(Int(invoice.total)) \(currency)")
                            .fontWeight(.bold).foregroundColor(.orange)
                    }
                }
                .padding()
            }
            .navigationBarTitle("معاينة الفاتورة", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إغلاق") { presentationMode.wrappedValue.dismiss() }
            )
        }
    }
    
    func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }
}
