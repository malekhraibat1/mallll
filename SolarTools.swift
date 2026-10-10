import SwiftUI
import CoreLocation
import CoreMotion

// ═══════════════════════════════════════════════════════════
// MARK: - PRODUCT MODEL
// ═══════════════════════════════════════════════════════════

struct SolarProduct: Identifiable, Codable {
    var id = UUID()
    var brand: String
    var name: String
    var category: String
    var specs: [String: String]
    var costPrice: Double
    var salePrice: Double
    var unit: String = "قطعة"
    
    var profit: Double { salePrice - costPrice }
    var profitMargin: Double {
        guard salePrice > 0 else { return 0 }
        return (profit / salePrice) * 100
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - DEYE & JINKO CATALOG
// ═══════════════════════════════════════════════════════════

struct SolarCatalog {
    static let all: [SolarProduct] = deyeInverters + jinkoPanels + deyeBatteries
    
    static let deyeInverters: [SolarProduct] = [
        SolarProduct(
            brand: "Deye", name: "SUN-5K-SG04LP3-EU",
            category: "إنفرتر",
            specs: [
                "النوع": "هجين ثلاثي الأطوار",
                "القدرة": "5 kW",
                "MPPT": "2",
                "أقصى جهد DC": "800V",
                "جهد البطارية": "40-60V",
                "أقصى تيار شحن": "120A",
                "الكفاءة": "97.6%",
                "الحماية": "IP65"
            ],
            costPrice: 3200, salePrice: 4800
        ),
        SolarProduct(
            brand: "Deye", name: "SUN-8K-SG04LP3-EU",
            category: "إنفرتر",
            specs: [
                "النوع": "هجين ثلاثي الأطوار",
                "القدرة": "8 kW",
                "MPPT": "2",
                "أقصى جهد DC": "800V",
                "جهد البطارية": "40-60V",
                "أقصى تيار شحن": "190A",
                "الكفاءة": "97.6%",
                "الحماية": "IP65"
            ],
            costPrice: 4500, salePrice: 6700
        ),
        SolarProduct(
            brand: "Deye", name: "SUN-10K-SG04LP3-EU",
            category: "إنفرتر",
            specs: [
                "النوع": "هجين ثلاثي الأطوار",
                "القدرة": "10 kW",
                "MPPT": "2",
                "أقصى جهد DC": "800V",
                "جهد البطارية": "40-60V",
                "أقصى تيار شحن": "240A",
                "الكفاءة": "97.6%",
                "الحماية": "IP65"
            ],
            costPrice: 5300, salePrice: 7900
        ),
        SolarProduct(
            brand: "Deye", name: "SUN-12K-SG04LP3-EU",
            category: "إنفرتر",
            specs: [
                "النوع": "هجين ثلاثي الأطوار",
                "القدرة": "12 kW",
                "MPPT": "2",
                "أقصى جهد DC": "800V",
                "جهد البطارية": "40-60V",
                "أقصى تيار شحن": "240A",
                "الكفاءة": "97.6%",
                "الحماية": "IP65"
            ],
            costPrice: 6200, salePrice: 9200
        ),
        SolarProduct(
            brand: "Deye", name: "SUN-5K-SG03LP1-EU",
            category: "إنفرتر",
            specs: [
                "النوع": "هجين أحادي الطور",
                "القدرة": "5 kW",
                "MPPT": "2",
                "أقصى جهد DC": "500V",
                "جهد البطارية": "40-60V",
                "أقصى تيار شحن": "120A",
                "الكفاءة": "97.6%",
                "الحماية": "IP65"
            ],
            costPrice: 2900, salePrice: 4400
        ),
        SolarProduct(
            brand: "Deye", name: "SUN-8K-SG01LP1-EU",
            category: "إنفرتر",
            specs: [
                "النوع": "هجين أحادي الطور",
                "القدرة": "8 kW",
                "MPPT": "2",
                "أقصى جهد DC": "500V",
                "جهد البطارية": "40-60V",
                "أقصى تيار شحن": "190A",
                "الكفاءة": "97.6%",
                "الحماية": "IP65"
            ],
            costPrice: 4100, salePrice: 6200
        )
    ]
    
    static let jinkoPanels: [SolarProduct] = [
        SolarProduct(
            brand: "Jinko", name: "Tiger Neo JKM550N-72HL4-BDV",
            category: "لوح شمسي",
            specs: [
                "النوع": "N-Type ثنائي الوجه",
                "القدرة": "550 W",
                "Vmp": "41.95V",
                "Imp": "13.12A",
                "Voc": "51.47V",
                "Isc": "13.87A",
                "الكفاءة": "21.29%",
                "الأبعاد": "2274×1134×30 مم",
                "الوزن": "32 kg",
                "الضمان": "12 سنة / 30 سنة أداء"
            ],
            costPrice: 480, salePrice: 720
        ),
        SolarProduct(
            brand: "Jinko", name: "Tiger Neo JKM580N-72HL4-BDV",
            category: "لوح شمسي",
            specs: [
                "النوع": "N-Type ثنائي الوجه",
                "القدرة": "580 W",
                "Vmp": "43.35V",
                "Imp": "13.38A",
                "Voc": "51.47V",
                "Isc": "14.15A",
                "الكفاءة": "22.45%",
                "الأبعاد": "2274×1134×30 مم",
                "الوزن": "32 kg",
                "الضمان": "12 سنة / 30 سنة أداء"
            ],
            costPrice: 520, salePrice: 780
        ),
        SolarProduct(
            brand: "Jinko", name: "Tiger Neo JKM600N-78HL4",
            category: "لوح شمسي",
            specs: [
                "النوع": "N-Type أحادي الوجه",
                "القدرة": "600 W",
                "Vmp": "44.80V",
                "Imp": "13.40A",
                "Voc": "53.20V",
                "Isc": "14.10A",
                "الكفاءة": "22.53%",
                "الأبعاد": "2465×1134×30 مم",
                "الوزن": "34.5 kg",
                "الضمان": "12 سنة / 30 سنة أداء"
            ],
            costPrice: 560, salePrice: 840
        ),
        SolarProduct(
            brand: "Jinko", name: "Tiger Neo JKM565N-72HL4",
            category: "لوح شمسي",
            specs: [
                "النوع": "N-Type أحادي الوجه",
                "القدرة": "565 W",
                "Vmp": "42.90V",
                "Imp": "13.17A",
                "Voc": "51.90V",
                "Isc": "13.95A",
                "الكفاءة": "21.87%",
                "الأبعاد": "2274×1134×30 مم",
                "الوزن": "32 kg",
                "الضمان": "12 سنة / 30 سنة أداء"
            ],
            costPrice: 490, salePrice: 740
        )
    ]
    
    static let deyeBatteries: [SolarProduct] = [
        SolarProduct(
            brand: "Deye", name: "SE-G5.3 Pro",
            category: "بطارية",
            specs: [
                "النوع": "LiFePO4",
                "السعة": "5.3 kWh",
                "الجهد": "51.2V",
                "السعة Ah": "104 Ah",
                "دورات": "6000",
                "الاتصال": "CAN/RS485",
                "الحماية": "IP20"
            ],
            costPrice: 4200, salePrice: 6200
        ),
        SolarProduct(
            brand: "Deye", name: "SE-G10.6 Pro",
            category: "بطارية",
            specs: [
                "النوع": "LiFePO4",
                "السعة": "10.6 kWh",
                "الجهد": "51.2V",
                "السعة Ah": "208 Ah",
                "دورات": "6000",
                "الاتصال": "CAN/RS485",
                "الحماية": "IP20"
            ],
            costPrice: 7800, salePrice: 11000
        )
    ]
}

// ═══════════════════════════════════════════════════════════
// MARK: - CATALOG STORE
// ═══════════════════════════════════════════════════════════

class SolarCatalogStore: ObservableObject {
    @Published var products: [SolarProduct] = []
    @Published var customSystems: [SystemPackage] = []
    
    private let productsKey = "solar_catalog_v2"
    private let systemsKey = "custom_systems_v1"
    
    init() {
        loadAll()
        if products.isEmpty { products = SolarCatalog.all }
    }
    
    func loadAll() {
        if let data = UserDefaults.standard.data(forKey: productsKey),
           let decoded = try? JSONDecoder().decode([SolarProduct].self, from: data) {
            products = decoded
        }
        if let data = UserDefaults.standard.data(forKey: systemsKey),
           let decoded = try? JSONDecoder().decode([SystemPackage].self, from: data) {
            customSystems = decoded
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(products) {
            UserDefaults.standard.set(data, forKey: productsKey)
        }
        if let data = try? JSONEncoder().encode(customSystems) {
            UserDefaults.standard.set(data, forKey: systemsKey)
        }
    }
    
    func addProduct(_ p: SolarProduct) { products.append(p); save() }
    func updateProduct(_ p: SolarProduct) {
        if let i = products.firstIndex(where: { $0.id == p.id }) {
            products[i] = p; save()
        }
    }
    func deleteProduct(_ p: SolarProduct) {
        products.removeAll { $0.id == p.id }; save()
    }
    
    func addSystem(_ s: SystemPackage) { customSystems.append(s); save() }
    func deleteSystem(_ s: SystemPackage) {
        customSystems.removeAll { $0.id == s.id }; save()
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - SYSTEM PACKAGE
// ═══════════════════════════════════════════════════════════

struct SystemPackageItem: Identifiable, Codable {
    var id = UUID()
    var productName: String
    var quantity: Double = 1
    var unitPrice: Double = 0
    var unit: String = "قطعة"
    var lineTotal: Double { quantity * unitPrice }
}

struct SystemPackage: Identifiable, Codable {
    var id = UUID()
    var name: String
    var systemType: String = "هجين"
    var capacityKWp: Double = 5
    var items: [SystemPackageItem] = []
    var laborCost: Double = 0
    var transportCost: Double = 0
    var taxRate: Double = 15
    var notes: String = ""
    var createdAt: Date = Date()
    
    var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    var totalCosts: Double { subtotal + laborCost + transportCost }
    var taxAmount: Double { totalCosts * (taxRate / 100) }
    var grandTotal: Double { totalCosts + taxAmount }
    var pricePerKWp: Double {
        guard capacityKWp > 0 else { return 0 }
        return grandTotal / capacityKWp
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - SYSTEM BUILDER
// ═══════════════════════════════════════════════════════════

struct SystemBuilderView: View {
    @EnvironmentObject var store: SolarCatalogStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var systemName = ""
    @State private var systemType = "هجين"
    @State private var capacityKWp = "5"
    @State private var items: [SystemPackageItem] = []
    @State private var laborCost = ""
    @State private var transportCost = ""
    @State private var taxRate = "15"
    @State private var notes = ""
    @State private var showingAddItem = false
    
    let systemTypes = ["هجين", "On-Grid", "Off-Grid", "مضخة شمسية"]
    
    var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    var labor: Double { Double(laborCost) ?? 0 }
    var transport: Double { Double(transportCost) ?? 0 }
    var tax: Double { Double(taxRate) ?? 15 }
    var totalCosts: Double { subtotal + labor + transport }
    var taxAmount: Double { totalCosts * (tax / 100) }
    var grandTotal: Double { totalCosts + taxAmount }
    var cap: Double { Double(capacityKWp) ?? 0 }
    var pricePerKWp: Double { cap > 0 ? grandTotal / cap : 0 }
    
    var body: some View {
        Form {
            Section(header: Text("معلومات النظام")) {
                TextField("اسم النظام", text: $systemName)
                Picker("النوع", selection: $systemType) {
                    ForEach(systemTypes, id: \.self) { Text($0) }
                }
                HStack {
                    Text("الحجم (kWp)")
                    Spacer()
                    TextField("5", text: $capacityKWp)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            Section(header: Text("المنتجات (\(items.count))")) {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName).font(.subheadline)
                            Text("\(item.quantity, specifier: "%.0f") × \(item.unitPrice, specifier: "%.0f") \(item.unit)")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(item.lineTotal, specifier: "%.0f")")
                            .bold()
                    }
                }
                .onDelete { idx in
                    idx.forEach { items.remove(at: $0) }
                }
                Button(action: { showingAddItem = true }) {
                    Label("إضافة منتج", systemImage: "plus.circle")
                }
                .foregroundColor(.orange)
            }
            
            Section(header: Text("تكاليف إضافية")) {
                HStack {
                    Text("أعمال التركيب")
                    Spacer()
                    TextField("0", text: $laborCost)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                HStack {
                    Text("النقل")
                    Spacer()
                    TextField("0", text: $transportCost)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section(header: Text("الضريبة")) {
                HStack {
                    Text("ضريبة %")
                    Spacer()
                    TextField("15", text: $taxRate)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
            }
            
            Section(header: Text("الملخص")) {
                summaryRow("المنتجات", subtotal, .primary)
                summaryRow("تركيب", labor, .primary)
                summaryRow("نقل", transport, .primary)
                summaryRow("المجموع", totalCosts, .blue)
                summaryRow("ضريبة", taxAmount, .secondary)
                HStack {
                    Text("الإجمالي النهائي").bold()
                    Spacer()
                    Text("\(grandTotal, specifier: "%.2f")")
                        .bold().foregroundColor(.orange)
                }
                HStack {
                    Text("السعر لكل kWp").bold()
                    Spacer()
                    Text("\(pricePerKWp, specifier: "%.2f")")
                        .bold().foregroundColor(.green)
                }
            }
            
            Section(header: Text("ملاحظات")) {
                TextField("ملاحظات", text: $notes)
            }
            
            Section {
                Button("حفظ النظام") {
                    let package = SystemPackage(
                        name: systemName.isEmpty ? "نظام \(systemType)" : systemName,
                        systemType: systemType,
                        capacityKWp: cap,
                        items: items,
                        laborCost: labor,
                        transportCost: transport,
                        taxRate: tax,
                        notes: notes
                    )
                    store.addSystem(package)
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.orange)
            }
        }
        .navigationBarTitle("بناء نظام جديد", displayMode: .inline)
        .navigationBarItems(trailing:
            Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
        )
        .sheet(isPresented: $showingAddItem) {
            ProductPickerSheet(items: $items)
        }
    }
    
    func summaryRow(_ title: String, _ value: Double, _ color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value, specifier: "%.2f")").foregroundColor(color)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - PRODUCT PICKER
// ═══════════════════════════════════════════════════════════

struct ProductPickerSheet: View {
    @EnvironmentObject var store: SolarCatalogStore
    @Environment(\.presentationMode) var presentationMode
    @Binding var items: [SystemPackageItem]
    
    @State private var search = ""
    @State private var selectedCategory = "الكل"
    @State private var quantity = "1"
    @State private var customPrice = ""
    @State private var selectedProduct: SolarProduct?
    
    let categories = ["الكل", "إنفرتر", "لوح شمسي", "بطارية"]
    
    var filtered: [SolarProduct] {
        var list = store.products
        if selectedCategory != "الكل" {
            list = list.filter { $0.category == selectedCategory }
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
        NavigationView {
            List {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat)
                                    .font(.caption).bold()
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Color.orange : Color.gray.opacity(0.15))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowInsets(EdgeInsets())
                
                ForEach(filtered) { p in
                    Button(action: {
                        selectedProduct = p
                        customPrice = "\(Int(p.salePrice))"
                        quantity = "1"
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.subheadline).foregroundColor(.primary)
                                Text(p.brand).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(Int(p.salePrice))")
                                .bold().foregroundColor(.orange)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .searchable(text: $search, prompt: "ابحث عن منتج")
            .navigationBarTitle("اختر منتجًا", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إغلاق") { presentationMode.wrappedValue.dismiss() }
            )
            .alert("الكمية والسعر", isPresented: Binding(
                get: { selectedProduct != nil },
                set: { if !$0 { selectedProduct = nil } }
            )) {
                TextField("الكمية", text: $quantity).keyboardType(.decimalPad)
                TextField("السعر", text: $customPrice).keyboardType(.decimalPad)
                Button("إضافة") {
                    if let p = selectedProduct {
                        let item = SystemPackageItem(
                            productName: "\(p.brand) \(p.name)",
                            quantity: Double(quantity) ?? 1,
                            unitPrice: Double(customPrice) ?? p.salePrice,
                            unit: p.unit
                        )
                        items.append(item)
                    }
                    selectedProduct = nil
                }
                Button("إلغاء", role: .cancel) { selectedProduct = nil }
            } message: {
                if let p = selectedProduct {
                    Text("\(p.brand) \(p.name)")
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - COMPASS
// ═══════════════════════════════════════════════════════════

class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    @Published var accuracy: Double = 0
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func start() {
        manager.requestWhenInUseAuthorization()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }
    
    func stop() {
        manager.stopUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading.trueHeading >= 0
                ? newHeading.trueHeading
                : newHeading.magneticHeading
            self.accuracy = newHeading.headingAccuracy
        }
    }
    
    var cardinalDirection: String {
        let dirs = ["شمال", "شمال شرق", "شرق", "جنوب شرق",
                    "جنوب", "جنوب غرب", "غرب", "شمال غرب"]
        let idx = Int((heading + 22.5) / 45) % 8
        return dirs[idx]
    }
    
    var optimalTilt: Double {
        let absLat = 24.7
        if absLat < 25 { return absLat * 0.87 }
        if absLat < 50 { return absLat * 0.76 + 3.1 }
        return absLat * 0.6 + 25
    }
    
    var guidance: String {
        let diff = abs(heading - 180)
        if diff < 15 { return "✅ اتجاه مثالي" }
        if diff < 30 { return "✔️ اتجاه جيد" }
        return "⚠️ يُنصح بالاتجاه نحو الجنوب"
    }
}

struct CompassView: View {
    @StateObject private var compass = CompassManager()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color(.secondarySystemBackground), lineWidth: 20)
                    .frame(width: 280, height: 280)
                
                ForEach(0..<36) { i in
                    Rectangle()
                        .fill(i % 9 == 0 ? Color.primary : Color.secondary.opacity(0.5))
                        .frame(width: i % 9 == 0 ? 2 : 1,
                               height: i % 9 == 0 ? 14 : 7)
                        .offset(y: -128)
                        .rotationEffect(.degrees(Double(i) * 10))
                }
                
                Text("N")
                    .font(.title).bold()
                    .foregroundColor(.red)
                    .offset(y: -152)
                
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 240, height: 240)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 100)
                    .offset(y: -50)
                    .rotationEffect(.degrees(-compass.heading))
                
                VStack(spacing: 4) {
                    Text("\(Int(compass.heading))°")
                        .font(.system(size: 36, weight: .bold))
                    Text(compass.cardinalDirection)
                        .font(.title3)
                        .foregroundColor(.orange)
                }
            }
            .animation(.spring(response: 0.3), value: compass.heading)
            
            VStack(spacing: 8) {
                Text(compass.guidance)
                    .font(.headline)
                    .foregroundColor(compass.guidance.contains("مثالي") ? .green :
                                     compass.guidance.contains("جيد") ? .blue : .orange)
                
                Text("الميل المثالي لموقعك: \(Int(compass.optimalTilt))°")
                    .font(.subheadline).foregroundColor(.secondary)
                
                if compass.accuracy > 15 {
                    Text("⚠️ دقة منخفضة — ابتعد عن المعادن")
                        .font(.caption).foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitle("البوصلة", displayMode: .inline)
        .onAppear { compass.start() }
        .onDisappear { compass.stop() }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - TILT LEVEL
// ═══════════════════════════════════════════════════════════

class TiltManager: NSObject, ObservableObject {
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var tiltMagnitude: Double = 0
    
    private let motionManager = CMMotionManager()
    
    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical,
                                                to: .main) { [weak self] motion, _ in
            guard let self = self, let m = motion else { return }
            let p = m.attitude.pitch * 180 / .pi
            let r = m.attitude.roll * 180 / .pi
            self.pitch = p
            self.roll = r
            self.tiltMagnitude = sqrt(p * p + r * r)
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct TiltLevelView: View {
    @StateObject private var tilt = TiltManager()
    @State private var capturedAngle: Double? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 280, height: 280)
                
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    .frame(width: 280, height: 280)
                
                ForEach([0.66, 0.33], id: \.self) { scale in
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        .frame(width: 280 * scale, height: 280 * scale)
                }
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 280, height: 1)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 280)
                
                let maxAngle: Double = 45
                let dx = tilt.roll / maxAngle * 130
                let dy = tilt.pitch / maxAngle * 130
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: .orange.opacity(0.4), radius: 10)
                    .offset(x: dx, y: dy)
                    .animation(.spring(response: 0.15), value: dx)
                
                VStack(spacing: 2) {
                    Text("\(tilt.tiltMagnitude, specifier: "%.1f")°")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.orange)
                    Text(tiltDescription)
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                tiltCard("Pitch", tilt.pitch, "arrow.up.and.down")
                tiltCard("Roll", tilt.roll, "arrow.left.and.right")
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                if let captured = capturedAngle {
                    Text("الزاوية المحفوظة: \(captured, specifier: "%.1f")°")
                        .font(.headline).foregroundColor(.green)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        capturedAngle = tilt.tiltMagnitude
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Label("حفظ الزاوية", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { capturedAngle = nil }) {
                        Label("مسح", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitle("ميزان الميل", displayMode: .inline)
        .onAppear { tilt.start() }
        .onDisappear { tilt.stop() }
    }
    
    var tiltDescription: String {
        if tilt.tiltMagnitude < 2 { return "أفقي" }
        if tilt.tiltMagnitude < 10 { return "ميل خفيف" }
        if tilt.tiltMagnitude < 30 { return "ميل مناسب" }
        if tilt.tiltMagnitude < 45 { return "ميل شديد" }
        return "ميل حاد"
    }
    
    func tiltCard(_ title: String, _ value: Double, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16)).foregroundColor(.orange)
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(value, specifier: "%.1f")°")
                .font(.title3).bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - CATALOG VIEW
// ═══════════════════════════════════════════════════════════

struct SolarCatalogView: View {
    @EnvironmentObject var store: SolarCatalogStore
    @State private var selectedCategory = "الكل"
    @State private var search = ""
    
    let categories = ["الكل", "إنفرتر", "لوح شمسي", "بطارية"]
    
    var filtered: [SolarProduct] {
        var list = store.products
        if selectedCategory != "الكل" {
            list = list.filter { $0.category == selectedCategory }
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
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { cat in
                        Button(action: { selectedCategory = cat }) {
                            Text(cat)
                                .font(.caption).bold()
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedCategory == cat ? Color.orange : Color.gray.opacity(0.15))
                                .foregroundColor(selectedCategory == cat ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
            
            List {
                ForEach(filtered) { p in
                    NavigationLink(destination: ProductDetailView(product: p)) {
                        HStack(spacing: 12) {
                            Image(systemName: iconFor(p.category))
                                .foregroundColor(.orange)
                                .frame(width: 40, height: 40)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.subheadline).bold()
                                Text(p.brand).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(Int(p.salePrice))")
                                    .font(.subheadline).bold().foregroundColor(.orange)
                                Text("+\(Int(p.profitMargin))%")
                                    .font(.caption2).foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .searchable(text: $search, prompt: "ابحث في الكتالوج")
        }
        .navigationBarTitle("كتالوج Deye & Jinko", displayMode: .large)
    }
    
    func iconFor(_ category: String) -> String {
        switch category {
        case "إنفرتر": return "bolt.fill"
        case "لوح شمسي": return "sun.max.fill"
        case "بطارية": return "battery.100"
        default: return "shippingbox.fill"
        }
    }
}

struct ProductDetailView: View {
    let product: SolarProduct
    
    var body: some View {
        List {
            Section(header: Text("معلومات")) {
                detailRow("الماركة", product.brand)
                detailRow("الموديل", product.name)
                detailRow("التصنيف", product.category)
            }
            
            Section(header: Text("المواصفات الفنية")) {
                ForEach(Array(product.specs.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key).font(.subheadline)
                        Spacer()
                        Text(product.specs[key] ?? "")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("الأسعار")) {
                HStack {
                    Text("سعر التكلفة")
                    Spacer()
                    Text("\(Int(product.costPrice))").foregroundColor(.secondary)
                }
                HStack {
                    Text("سعر البيع")
                    Spacer()
                    Text("\(Int(product.salePrice))").bold().foregroundColor(.orange)
                }
                HStack {
                    Text("هامش الربح")
                    Spacer()
                    Text("\(Int(product.profitMargin))%").bold().foregroundColor(.green)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(product.name, displayMode: .inline)
    }
    
    func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - SOLAR TOOLS HUB
// ═══════════════════════════════════════════════════════════

struct SolarToolsHubView: View {
    @EnvironmentObject var catalogStore: SolarCatalogStore
    
    var body: some View {
        List {
            Section(header: Text("أدوات القياس")) {
                NavigationLink(destination: CompassView()) {
                    Label("البوصلة", systemImage: "safari.fill")
                }
                NavigationLink(destination: TiltLevelView()) {
                    Label("ميزان الميل", systemImage: "level.fill")
                }
            }
            
            Section(header: Text("الكتالوج")) {
                NavigationLink(destination: SolarCatalogView()) {
                    HStack {
                        Label("كتالوج Deye & Jinko", systemImage: "shippingbox.fill")
                        Spacer()
                        Text("\(catalogStore.products.count) منتج")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("الأنظمة الجاهزة")) {
                NavigationLink(destination: SystemBuilderView()) {
                    Label("بناء نظام جديد", systemImage: "plus.circle.fill")
                }
                NavigationLink(destination: SavedSystemsView()) {
                    HStack {
                        Label("الأنظمة المحفوظة", systemImage: "folder.fill")
                        Spacer()
                        Text("\(catalogStore.customSystems.count)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("أدوات الطاقة الشمسية", displayMode: .large)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - SAVED SYSTEMS
// ═══════════════════════════════════════════════════════════

struct SavedSystemsView: View {
    @EnvironmentObject var store: SolarCatalogStore
    
    var body: some View {
        List {
            if store.customSystems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 70)).foregroundColor(.orange)
                    Text("لا توجد أنظمة محفوظة")
                        .font(.title3).bold()
                    Text("ابدأ ببناء نظام جديد")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(store.customSystems) { sys in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(sys.name).font(.headline)
                            Spacer()
                            Text("\(sys.grandTotal, specifier: "%.0f")")
                                .font(.headline).foregroundColor(.orange)
                        }
                        HStack(spacing: 12) {
                            Label("\(sys.capacityKWp, specifier: "%.1f") kWp",
                                  systemImage: "bolt.fill")
                                .font(.caption2).foregroundColor(.blue)
                            Label(sys.systemType, systemImage: "gear")
                                .font(.caption2).foregroundColor(.secondary)
                            Text("\(sys.items.count) بند")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Text("\(sys.pricePerKWp, specifier: "%.0f") / kWp")
                            .font(.caption).foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { idx in
                    idx.forEach { store.deleteSystem(store.customSystems[$0]) }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("الأنظمة المحفوظة", displayMode: .inline)
    }
}
