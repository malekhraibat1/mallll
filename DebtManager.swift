import SwiftUI

// ═══════════════════════════════════════════════════════════
// MARK: - DEBT MODELS
// ═══════════════════════════════════════════════════════════

struct DebtPerson: Identifiable, Codable {
    var id = UUID()
    var name: String
    var phone: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
}

enum DebtType: String, Codable, CaseIterable {
    case lent = "أقرضت"
    case borrowed = "استلفت"

    var icon: String {
        switch self {
        case .lent: return "arrow.up.circle.fill"
        case .borrowed: return "arrow.down.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .lent: return .green
        case .borrowed: return .red
        }
    }
}

enum DebtCategory: String, Codable, CaseIterable {
    case loan = "قرض"
    case sale = "بيع"
    case purchase = "شراء"
    case rent = "إيجار"
    case salary = "راتب"
    case service = "خدمة"
    case bill = "فاتورة"
    case other = "أخرى"

    var icon: String {
        switch self {
        case .loan: return "banknote"
        case .sale: return "cart.fill"
        case .purchase: return "bag.fill"
        case .rent: return "house.fill"
        case .salary: return "person.fill"
        case .service: return "wrench.fill"
        case .bill: return "doc.text.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct DebtTransaction: Identifiable, Codable {
    var id = UUID()
    var personId: UUID
    var type: DebtType
    var category: DebtCategory = .loan
    var amount: Double = 0
    var paidAmount: Double = 0
    var date: Date = Date()
    var dueDate: Date? = nil
    var note: String = ""

    var remaining: Double { max(amount - paidAmount, 0) }
    var isPaid: Bool { paidAmount >= amount }
    var paidRatio: Double { amount > 0 ? min(paidAmount / amount, 1) : 0 }
    var isOverdue: Bool {
        guard let due = dueDate, !isPaid else { return false }
        return Date() > due
    }
}

struct DebtPayment: Identifiable, Codable {
    var id = UUID()
    var transactionId: UUID
    var amount: Double
    var date: Date = Date()
    var note: String = ""
}

// ═══════════════════════════════════════════════════════════
// MARK: - DEBT STORE
// ═══════════════════════════════════════════════════════════

class DebtStore: ObservableObject {
    @Published var persons: [DebtPerson] = []
    @Published var transactions: [DebtTransaction] = []
    @Published var payments: [DebtPayment] = []

    private let personsKey = "debt_persons_v1"
    private let transactionsKey = "debt_transactions_v1"
    private let paymentsKey = "debt_payments_v1"

    init() { loadAll() }

    func loadAll() {
        persons = load(personsKey) ?? []
        transactions = load(transactionsKey) ?? []
        payments = load(paymentsKey) ?? []
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

    func addPerson(_ p: DebtPerson) {
        persons.append(p); save(persons, key: personsKey)
    }
    func updatePerson(_ p: DebtPerson) {
        if let i = persons.firstIndex(where: { $0.id == p.id }) {
            persons[i] = p; save(persons, key: personsKey)
        }
    }
    func deletePerson(_ p: DebtPerson) {
        persons.removeAll { $0.id == p.id }
        transactions.removeAll { $0.personId == p.id }
        save(persons, key: personsKey)
        save(transactions, key: transactionsKey)
    }

    func addTransaction(_ t: DebtTransaction) {
        transactions.append(t); save(transactions, key: transactionsKey)
    }
    func updateTransaction(_ t: DebtTransaction) {
        if let i = transactions.firstIndex(where: { $0.id == t.id }) {
            transactions[i] = t; save(transactions, key: transactionsKey)
        }
    }
    func deleteTransaction(_ t: DebtTransaction) {
        transactions.removeAll { $0.id == t.id }
        payments.removeAll { $0.transactionId == t.id }
        save(transactions, key: transactionsKey)
        save(payments, key: paymentsKey)
    }

    func transactionsFor(_ personId: UUID) -> [DebtTransaction] {
        transactions.filter { $0.personId == personId }
            .sorted { $0.date > $1.date }
    }

    func addPayment(_ p: DebtPayment) {
        payments.append(p)
        if let i = transactions.firstIndex(where: { $0.id == p.transactionId }) {
            transactions[i].paidAmount += p.amount
        }
        save(payments, key: paymentsKey)
        save(transactions, key: transactionsKey)
    }

    func paymentsFor(_ transactionId: UUID) -> [DebtPayment] {
        payments.filter { $0.transactionId == transactionId }
            .sorted { $0.date > $1.date }
    }

    func balanceFor(_ personId: UUID) -> (lent: Double, borrowed: Double, net: Double) {
        let list = transactionsFor(personId).filter { !$0.isPaid }
        let lent = list.filter { $0.type == .lent }.reduce(0) { $0 + $1.remaining }
        let borrowed = list.filter { $0.type == .borrowed }.reduce(0) { $0 + $1.remaining }
        return (lent, borrowed, lent - borrowed)
    }

    var totalLent: Double {
        transactions.filter { $0.type == .lent && !$0.isPaid }
            .reduce(0) { $0 + $1.remaining }
    }
    var totalBorrowed: Double {
        transactions.filter { $0.type == .borrowed && !$0.isPaid }
            .reduce(0) { $0 + $1.remaining }
    }
    var netBalance: Double { totalLent - totalBorrowed }
    var overdueCount: Int {
        transactions.filter { $0.isOverdue }.count
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - DEBTS VIEW
// ═══════════════════════════════════════════════════════════

struct DebtsView: View {
    @EnvironmentObject var store: DebtStore
    @State private var selectedTab: Int = 0
    @State private var showingNewPerson = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    summaryCard(title: "له عندي", value: store.totalLent,
                                icon: "arrow.up.circle.fill", color: .green)
                    summaryCard(title: "عليّ له", value: store.totalBorrowed,
                                icon: "arrow.down.circle.fill", color: .red)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("الرصيد الصافي")
                            .font(.caption).foregroundColor(.secondary)
                        Text("\(Int(store.netBalance))")
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(store.netBalance >= 0 ? .green : .red)
                    }
                    Spacer()
                    if store.overdueCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("\(store.overdueCount) متأخرة")
                        }
                                            if store.overdueCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("\(store.overdueCount) متأخرة")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Picker("", selection: $selectedTab) {
                Text("الأشخاص").tag(0)
                Text("الحركات").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if selectedTab == 0 {
                personsList
            } else {
                transactionsList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitle("الحسابات والديون", displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { showingNewPerson = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundColor(.orange)
            }
        )
        .sheet(isPresented: $showingNewPerson) {
            AddPersonSheet()
        }
    }

    var personsList: some View {
        Group {
            if store.persons.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 70)).foregroundColor(.orange)
                    Text("لا يوجد أشخاص").font(.title3).fontWeight(.semibold)
                    Text("اضغط + لإضافة شخص").foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.persons) { person in
                            NavigationLink(destination: PersonLedgerView(person: person)) {
                                personRow(person)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
    }

    func personRow(_ person: DebtPerson) -> some View {
        let bal = store.balanceFor(person.id)
        return HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials(person.name))
                        .foregroundColor(.white).fontWeight(.bold)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(person.name).font(.headline).foregroundColor(.primary)
                if !person.phone.isEmpty {
                    Text(person.phone).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if bal.net != 0 {
                    Text("\(Int(abs(bal.net)))")
                        .font(.headline)
                        .foregroundColor(bal.net > 0 ? .green : .red)
                    Text(bal.net > 0 ? "له عندي" : "عليّ له")
                        .font(.caption2).foregroundColor(.secondary)
                } else {
                    Text("متوازن").font(.caption).foregroundColor(.green)
                }
            }
            Image(systemName: "chevron.left").foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    var transactionsList: some View {
        Group {
            if store.transactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 70)).foregroundColor(.orange)
                    Text("لا توجد حركات").font(.title3).fontWeight(.semibold)
                    Text("أضف شخصًا ثم أضف له حركة").foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.transactions.sorted(by: { $0.date > $1.date })) { t in
                            transactionRow(t)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    func transactionRow(_ t: DebtTransaction) -> some View {
        let personName = store.persons.first { $0.id == t.personId }?.name ?? "—"
        return HStack(spacing: 12) {
            Image(systemName: t.type.icon)
                .font(.title3)
                .foregroundColor(t.type.color)
                .frame(width: 40, height: 40)
                .background(t.type.color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(personName).font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 6) {
                    Text(t.category.rawValue).font(.caption).foregroundColor(.secondary)
                    Text("·").foregroundColor(.secondary)
                    Text(formatDate(t.date)).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(t.amount))").font(.headline)
                if t.isPaid {
                    Text("مدفوع").font(.caption2).foregroundColor(.green)
                } else if t.paidAmount > 0 {
                    Text("متبقٍ \(Int(t.remaining))")
                        .font(.caption2).foregroundColor(.orange)
                } else {
                    Text(t.type.rawValue)
                        .font(.caption2).foregroundColor(t.type.color)
                }
                if t.isOverdue {
                    Text("متأخرة").font(.caption2).foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    func summaryCard(title: String, value: Double,
                     icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("\(Int(value))").font(.title3).fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }

    func initials(_ s: String) -> String {
        let parts = s.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }

    func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: d)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - ADD PERSON
// ═══════════════════════════════════════════════════════════

struct AddPersonSheet: View {
    @EnvironmentObject var store: DebtStore
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var phone = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("المعلومات")) {
                    TextField("الاسم", text: $name)
                    TextField("الهاتف", text: $phone).keyboardType(.phonePad)
                }
                Section {
                    Button("إضافة") {
                        guard !name.isEmpty else { return }
                        store.addPerson(DebtPerson(name: name, phone: phone))
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity).foregroundColor(.orange)
                }
            }
            .navigationBarTitle("شخص جديد", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - PERSON LEDGER
// ═══════════════════════════════════════════════════════════

struct PersonLedgerView: View {
    @EnvironmentObject var store: DebtStore
    let person: DebtPerson

    @State private var showingNewTransaction = false
    @State private var paymentForTransaction: DebtTransaction?

    var transactions: [DebtTransaction] {
        store.transactionsFor(person.id)
    }

    var balance: (lent: Double, borrowed: Double, net: Double) {
        store.balanceFor(person.id)
    }

    var body: some View {
        List {
            Section(header: Text("الرصيد")) {
                HStack {
                    Text("له عندي")
                    Spacer()
                    Text("\(Int(balance.lent))")
                        .fontWeight(.bold).foregroundColor(.green)
                }
                HStack {
                    Text("عليّ له")
                    Spacer()
                    Text("\(Int(balance.borrowed))")
                        .fontWeight(.bold).foregroundColor(.red)
                }
                HStack {
                    Text("الصافي").fontWeight(.bold)
                    Spacer()
                    Text("\(Int(abs(balance.net))) \(balance.net >= 0 ? "له" : "عليّ")")
                        .fontWeight(.bold)
                        .foregroundColor(balance.net >= 0 ? .green : .red)
                }
            }

            Section(header: Text("الحركات (\(transactions.count))")) {
                if transactions.isEmpty {
                    Text("لا توجد حركات").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(transactions) { t in
                        Button(action: { paymentForTransaction = t }) {
                            transactionDetailRow(t)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete { idx in
                        idx.forEach { store.deleteTransaction(transactions[$0]) }
                    }
                }
            }

            Section {
                Button(action: { showingNewTransaction = true }) {
                    Label("إضافة حركة", systemImage: "plus.circle")
                }
                .foregroundColor(.orange)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(person.name, displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { showingNewTransaction = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundColor(.orange)
            }
        )
        .sheet(isPresented: $showingNewTransaction) {
            AddTransactionSheet(person: person)
        }
        .sheet(item: $paymentForTransaction) { t in
            AddPaymentSheet(transaction: t)
        }
    }

    func transactionDetailRow(_ t: DebtTransaction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: t.type.icon).foregroundColor(t.type.color)
                Text(t.type.rawValue).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(Int(t.amount))").font(.headline)
            }
            HStack(spacing: 8) {
                Label(t.category.rawValue, systemImage: t.category.icon)
                    .font(.caption2).foregroundColor(.secondary)
                Text("·").foregroundColor(.secondary)
                Text(formatDate(t.date))
                    .font(.caption2).foregroundColor(.secondary)
            }
            if !t.note.isEmpty {
                Text(t.note).font(.caption).foregroundColor(.secondary)
            }
            if t.paidAmount > 0 && !t.isPaid {
                ProgressView(value: t.paidRatio)
                HStack {
                    Text("مدفوع: \(Int(t.paidAmount))")
                        .font(.caption2).foregroundColor(.green)
                    Spacer()
                    Text("متبقٍ: \(Int(t.remaining))")
                        .font(.caption2).foregroundColor(.orange)
                }
            }
            if t.isPaid {
                Label("مسددة", systemImage: "checkmark.circle.fill")
                    .font(.caption2).foregroundColor(.green)
            } else if t.isOverdue {
                Label("متأخرة!", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2).foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .foregroundColor(.primary)
    }

    func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - ADD TRANSACTION
// ═══════════════════════════════════════════════════════════

struct AddTransactionSheet: View {
    @EnvironmentObject var store: DebtStore
    @Environment(\.presentationMode) var presentationMode
    let person: DebtPerson

    @State private var type: DebtType = .lent
    @State private var category: DebtCategory = .loan
    @State private var amount = ""
    @State private var date = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(30 * 86400)
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("نوع الحركة")) {
                    Picker("النوع", selection: $type) {
                        ForEach(DebtType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Picker("التصنيف", selection: $category) {
                        ForEach(DebtCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                }
                Section(header: Text("المبلغ والتاريخ")) {
                    HStack {
                        Text("المبلغ")
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    DatePicker("التاريخ", selection: $date,
                               displayedComponents: .date)
                }
                Section(header: Text("الاستحقاق")) {
                    Toggle("تحديد تاريخ استحقاق", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("تاريخ الاستحقاق", selection: $dueDate,
                                   displayedComponents: .date)
                    }
                }
                Section(header: Text("ملاحظات")) {
                    TextField("ملاحظة", text: $note)
                }
                Section {
                    Button("حفظ") {
                        guard let amt = Double(amount), amt > 0 else { return }
                        let t = DebtTransaction(
                            personId: person.id,
                            type: type,
                            category: category,
                            amount: amt,
                            date: date,
                            dueDate: hasDueDate ? dueDate : nil,
                            note: note
                        )
                        store.addTransaction(t)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity).foregroundColor(.orange)
                }
            }
            .navigationBarTitle("حركة جديدة", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - ADD PAYMENT
// ═══════════════════════════════════════════════════════════

struct AddPaymentSheet: View {
    @EnvironmentObject var store: DebtStore
    @Environment(\.presentationMode) var presentationMode
    let transaction: DebtTransaction

    @State private var amount = ""
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("الحركة")) {
                    HStack {
                        Text("المبلغ الأصلي")
                        Spacer()
                        Text("\(Int(transaction.amount))").fontWeight(.semibold)
                    }
                    HStack {
                        Text("مدفوع حتى الآن")
                        Spacer()
                        Text("\(Int(transaction.paidAmount))")
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("المتبقي")
                        Spacer()
                        Text("\(Int(transaction.remaining))")
                            .foregroundColor(.orange).fontWeight(.semibold)
                    }
                }
                Section(header: Text("الدفعة الجديدة")) {
                    HStack {
                        Text("المبلغ")
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Button("دفعة كاملة (\(Int(transaction.remaining)))") {
                        amount = "\(Int(transaction.remaining))"
                    }
                    .font(.caption).foregroundColor(.blue)
                }
                Section(header: Text("ملاحظات")) {
                    TextField("ملاحظة (اختياري)", text: $note)
                }
                Section {
                    Button("تسجيل الدفعة") {
                        guard let amt = Double(amount), amt > 0 else { return }
                        let p = DebtPayment(
                            transactionId: transaction.id,
                            amount: amt,
                            note: note
                        )
                        store.addPayment(p)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity).foregroundColor(.green)
                }
                if !store.paymentsFor(transaction.id).isEmpty {
                    Section(header: Text("سجل الدفعات")) {
                        ForEach(store.paymentsFor(transaction.id)) { p in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(Int(p.amount))").font(.subheadline)
                                    Text(formatDate(p.date))
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                if !p.note.isEmpty {
                                    Text(p.note).font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("تسجيل دفعة", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("إلغاء") { presentationMode.wrappedValue.dismiss() }
            )
        }
    }

    func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - DEBTS ROOT
// ═══════════════════════════════════════════════════════════

struct DebtsRootView: View {
    @StateObject private var debtStore = DebtStore()

    var body: some View {
        DebtsView()
            .environmentObject(debtStore)
    }
}
