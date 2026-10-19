import SwiftUI
import PhotosUI
import CryptoKit
import UIKit

struct DiamondPackage: Identifiable, Hashable {
    let id: String
    let diamonds: String
    let price: Double
    let label: String
    let badge: String?
}

private let packages: [DiamondPackage] = [
    .init(id: "572", diamonds: "572", price: 5.20, label: "Paquete inicial", badge: "POPULAR"),
    .init(id: "1116", diamonds: "1,116", price: 9.00, label: "Más por tu dinero", badge: "MEJOR VALOR"),
    .init(id: "2398", diamonds: "2,398", price: 18.00, label: "Recarga estándar", badge: nil),
    .init(id: "6160", diamonds: "6,160", price: 37.00, label: "Recarga pro", badge: nil),
    .init(id: "12320", diamonds: "12,320", price: 76.00, label: "Para escuadras", badge: nil),
    .init(id: "18480", diamonds: "18,480", price: 113.00, label: "Pack competitivo", badge: nil),
    .init(id: "24640", diamonds: "24,640", price: 150.00, label: "Pack elite", badge: nil),
    .init(id: "30800", diamonds: "30,800", price: 187.00, label: "Pack creator", badge: nil),
    .init(id: "36960", diamonds: "36,960", price: 224.00, label: "Pack max", badge: nil),
    .init(id: "43120", diamonds: "43,120", price: 261.00, label: "Pack ultra", badge: nil),
    .init(id: "49280", diamonds: "49,280", price: 298.00, label: "Pack legend", badge: nil)
]

struct LocalProfile: Codable {
    var name: String
    var email: String
    var passwordHash: String
    var avatar: Data?
}

enum ProfileStore {
    private static let key = "nexus.diamantes.profile"

    static func load() -> LocalProfile? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LocalProfile.self, from: data)
    }

    static func save(_ profile: LocalProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ContentView: View {
    @State private var profile = ProfileStore.load()
    @State private var selectedPackage: DiamondPackage?
    @State private var cartPackage: DiamondPackage?
    @State private var showingProfile = false
    @State private var showingCheckout = false

    var body: some View {
        Group {
            if let profile {
                StoreView(profile: profile, cartPackage: $cartPackage, showingProfile: $showingProfile, showingCheckout: $showingCheckout)
                    .sheet(isPresented: $showingProfile) {
                        ProfileView(existing: profile) { updated in
                            ProfileStore.save(updated)
                            self.profile = updated
                        }
                    }
                    .sheet(isPresented: $showingCheckout) {
                        if let cartPackage {
                            CheckoutView(profile: profile, package: cartPackage)
                        }
                    }
            } else {
                ProfileView(existing: nil) { created in
                    ProfileStore.save(created)
                    profile = created
                }
            }
        }
        .tint(Color(red: 0.16, green: 0.58, blue: 1.0))
    }
}

struct StoreView: View {
    let profile: LocalProfile
    @Binding var cartPackage: DiamondPackage?
    @Binding var showingProfile: Bool
    @Binding var showingCheckout: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "diamond.fill")
                            .font(.title2).foregroundStyle(.blue).frame(width: 48, height: 48)
                            .background(.blue.opacity(0.16)).clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEXUS HACK").font(.caption.weight(.black)).tracking(2)
                            Text("DIAMOND STORE · FF RECARGAS").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { showingProfile = true } label: {
                            if let data = profile.avatar, let image = UIImage(data: data) {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else {
                                Text(String(profile.name.prefix(1)).uppercased()).fontWeight(.bold)
                            }
                        }
                        .frame(width: 42, height: 42).background(.blue.opacity(0.25)).clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("RECARGA RÁPIDA · SEGURA · MANUAL").font(.caption2.weight(.bold)).foregroundStyle(.blue)
                        Text("Diamantes que llegan a tu cuenta.").font(.system(size: 36, weight: .black, design: .rounded))
                        Text("Elige un paquete, agrega tu ID de jugador y paga con tu método preferido.")
                            .foregroundStyle(.secondary)
                        Button("Hablar con soporte") { open("https://wa.me/13473667628") }
                            .buttonStyle(.bordered)
                    }
                    .padding(22).background(LinearGradient(colors: [.blue.opacity(0.27), .black.opacity(0.35)], startPoint: .topTrailing, endPoint: .bottomLeading))
                    .clipShape(RoundedRectangle(cornerRadius: 26))

                    HStack {
                        Text("ELIGE TU PAQUETE").font(.caption.weight(.black)).tracking(1.5)
                        Spacer()
                        Text("USD · entrega manual").font(.caption).foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(packages) { package in
                            PackageCard(package: package) {
                                cartPackage = package
                                showingCheckout = true
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compra responsable").font(.headline)
                        Text("Los pagos y la entrega se verifican manualmente. No compartas tu contraseña con nadie.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding().background(.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Diamantes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        UIApplication.shared.open(url)
    }
}

struct PackageCard: View {
    let package: DiamondPackage
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let badge = package.badge { Text(badge).font(.caption2.weight(.black)).foregroundStyle(.blue) }
            Image(systemName: "diamond.fill").font(.title2).foregroundStyle(.blue)
            Text(package.diamonds).font(.system(size: 25, weight: .black, design: .rounded))
            Text("DIAMANTES").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            Divider()
            Text(String(format: "$%.2f", package.price)).font(.title3.weight(.black))
            Text(package.label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Button("COMPRAR", action: action).buttonStyle(.borderedProminent).controlSize(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(15)
        .background(.white.opacity(0.065)).clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.blue.opacity(package.badge == nil ? 0.15 : 0.6)))
    }
}

struct ProfileView: View {
    let existing: LocalProfile?
    let onSave: (LocalProfile) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var email: String
    @State private var password = ""
    @State private var avatar: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var error = ""

    init(existing: LocalProfile?, onSave: @escaping (LocalProfile) -> Void) {
        self.existing = existing; self.onSave = onSave
        _name = State(initialValue: existing?.name ?? "")
        _email = State(initialValue: existing?.email ?? "")
        _avatar = State(initialValue: existing?.avatar)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        avatarView
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Elegir foto de perfil", systemImage: "photo")
                        }
                        .onChange(of: photoItem) { item in
                            Task { await loadPhoto(item) }
                        }
                    }.frame(maxWidth: .infinity)
                }
                Section("Tu perfil") {
                    TextField("Nombre", text: $name).textContentType(.name)
                    TextField("Correo", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    SecureField(existing == nil ? "Contraseña" : "Nueva contraseña (opcional)", text: $password)
                }
                if !error.isEmpty { Section { Text(error).foregroundStyle(.red) } }
                Section { Text("El perfil se guarda solo en esta iPhone. No hay login externo ni código de Gmail.").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle(existing == nil ? "Crea tu perfil" : "Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Guardar") { save() } } }
        }
    }

    private var avatarView: some View {
        Group {
            if let avatar, let image = UIImage(data: avatar) { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().padding(15).foregroundStyle(.blue) }
        }
        .frame(width: 104, height: 104).background(.blue.opacity(0.18)).clipShape(Circle())
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data), let resized = image.jpegData(compressionQuality: 0.82) else { return }
        await MainActor.run { avatar = resized }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              email.contains("@"),
              (existing != nil || password.count >= 6) else {
            error = "Completa nombre, correo y una contraseña de mínimo 6 caracteres."
            return
        }
        let hash = password.isEmpty ? (existing?.passwordHash ?? "") : SHA256.hash(data: Data(password.utf8)).map { String(format: "%02x", $0) }.joined()
        onSave(LocalProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: email, passwordHash: hash, avatar: avatar))
        dismiss()
    }
}

enum PaymentMethod: String, CaseIterable, Identifiable { case paypal = "PayPal", cashApp = "Cash App", zelle = "Zelle", whatsapp = "WhatsApp"; var id: String { rawValue } }

struct CheckoutView: View {
    let profile: LocalProfile
    let package: DiamondPackage
    @Environment(\.dismiss) private var dismiss
    @State private var playerID = ""
    @State private var region = "LATAM Norte"
    @State private var method: PaymentMethod = .paypal
    @State private var message = ""
    @State private var showingMessage = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Pedido de \(package.diamonds) diamantes") {
                    LabeledContent("Cliente", value: profile.name)
                    LabeledContent("Total", value: String(format: "$%.2f USD", package.price))
                }
                Section("Destino") {
                    TextField("ID del jugador", text: $playerID).keyboardType(.numberPad)
                    Picker("Región", selection: $region) { ForEach(["LATAM Norte", "LATAM Sur", "Brasil", "NA", "EU", "Indonesia", "MENA"], id: \.self) { Text($0) } }
                }
                Section("Método de pago") { Picker("Pagar con", selection: $method) { ForEach(PaymentMethod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu) }
                Section { Button("Continuar al pago") { pay() }.frame(maxWidth: .infinity) }
                Section { Text("La entrega se confirma manualmente. Nunca compartas tu contraseña.").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Finalizar pedido")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
            .alert("Pedido preparado", isPresented: $showingMessage) { Button("OK") { dismiss() } } message: { Text(message) }
        }
    }

    private func pay() {
        guard !playerID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { message = "Escribe el ID del jugador."; showingMessage = true; return }
        let amount = String(format: "%.2f", package.price)
        let order = "Hola NEXUS HACK, quiero pagar \(package.diamonds) diamantes (\(amount) USD). Mi ID es \(playerID), región \(region)."
        let destination: String?
        switch method {
        case .paypal: destination = "https://www.paypal.me/MaykTzoc760/\(amount)"
        case .cashApp: destination = "https://cash.app/$MaykTzoc5/\(amount)"
        case .whatsapp: destination = "https://wa.me/13473667628?text=\(order.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        case .zelle: destination = nil
        }
        if let destination, let url = URL(string: destination) { UIApplication.shared.open(url) }
        message = method == .zelle ? "Envía $\(amount) USD por Zelle al +1 (347) 366-7628 y comparte el comprobante por WhatsApp." : "Se abrió \(method.rawValue) para completar el pago. Después envía el comprobante al WhatsApp +1 (347) 366-7628."
        showingMessage = true
    }
}
