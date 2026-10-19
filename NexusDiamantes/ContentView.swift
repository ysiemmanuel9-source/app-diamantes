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
    let accent: Color
}

private let packages: [DiamondPackage] = [
    .init(id: "572", diamonds: "572", price: 5.20, label: "Paquete inicial", badge: "POPULAR", accent: .cyan),
    .init(id: "1116", diamonds: "1,116", price: 9.00, label: "Más por tu dinero", badge: "MEJOR VALOR", accent: .blue),
    .init(id: "2398", diamonds: "2,398", price: 18.00, label: "Recarga estándar", badge: nil, accent: .indigo),
    .init(id: "6160", diamonds: "6,160", price: 37.00, label: "Recarga pro", badge: nil, accent: .purple),
    .init(id: "12320", diamonds: "12,320", price: 76.00, label: "Para escuadras", badge: nil, accent: .pink),
    .init(id: "18480", diamonds: "18,480", price: 113.00, label: "Pack competitivo", badge: nil, accent: .orange),
    .init(id: "24640", diamonds: "24,640", price: 150.00, label: "Pack elite", badge: nil, accent: .yellow),
    .init(id: "30800", diamonds: "30,800", price: 187.00, label: "Pack creator", badge: nil, accent: .green),
    .init(id: "36960", diamonds: "36,960", price: 224.00, label: "Pack max", badge: nil, accent: .teal),
    .init(id: "43120", diamonds: "43,120", price: 261.00, label: "Pack ultra", badge: nil, accent: .mint),
    .init(id: "49280", diamonds: "49,280", price: 298.00, label: "Pack legend", badge: "MÁXIMO", accent: .purple)
]

struct LocalProfile: Codable {
    var name: String
    var email: String
    var passwordHash: String
    var avatar: Data?
}

struct LocalOrder: Codable, Identifiable {
    let id: UUID
    let packageName: String
    let price: Double
    let playerID: String
    let region: String
    let date: Date
    var status: String
}

enum ProfileStore {
    private static let key = "nexus.diamantes.profile"
    static func load() -> LocalProfile? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LocalProfile.self, from: data)
    }
    static func save(_ profile: LocalProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

enum OrderStore {
    private static let key = "nexus.diamantes.orders"
    static func load() -> [LocalOrder] {
        guard let data = UserDefaults.standard.data(forKey: key), let orders = try? JSONDecoder().decode([LocalOrder].self, from: data) else { return [] }
        return orders
    }
    static func save(_ order: LocalOrder) {
        var orders = load()
        orders.insert(order, at: 0)
        if let data = try? JSONEncoder().encode(Array(orders.prefix(30))) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ContentView: View {
    @State private var profile = ProfileStore.load()
    @State private var cartPackage: DiamondPackage?
    @State private var showingProfile = false
    @State private var showingCheckout = false

    var body: some View {
        ZStack {
            AppBackground()
            if let profile {
                StoreView(profile: profile, cartPackage: $cartPackage, showingProfile: $showingProfile, showingCheckout: $showingCheckout)
                    .transition(.opacity)
                    .sheet(isPresented: $showingProfile) {
                        ProfileView(existing: profile) { updated in
                            ProfileStore.save(updated)
                            self.profile = updated
                        }
                    }
                    .sheet(isPresented: $showingCheckout) {
                        if let cartPackage { CheckoutView(profile: profile, package: cartPackage) }
                    }
            } else {
                ProfileView(existing: nil) { created in
                    ProfileStore.save(created)
                    withAnimation(.easeInOut(duration: 0.5)) { profile = created }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .tint(.cyan)
    }
}

struct AppBackground: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            Color(red: 0.015, green: 0.025, blue: 0.07).ignoresSafeArea()
            Circle().fill(.blue.opacity(0.18)).frame(width: 330).blur(radius: 70).offset(x: animate ? 155 : -170, y: -300)
            Circle().fill(.purple.opacity(0.13)).frame(width: 300).blur(radius: 80).offset(x: animate ? -170 : 140, y: 350)
        }
        .onAppear { withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { animate = true } }
    }
}

enum StoreTab: String, CaseIterable {
    case inicio = "Inicio", paquetes = "Paquetes", pedidos = "Pedidos", perfil = "Perfil"
    var icon: String {
        switch self { case .inicio: return "house.fill"; case .paquetes: return "diamond.fill"; case .pedidos: return "clock.arrow.circlepath"; case .perfil: return "person.fill" }
    }
}

struct StoreView: View {
    let profile: LocalProfile
    @Binding var cartPackage: DiamondPackage?
    @Binding var showingProfile: Bool
    @Binding var showingCheckout: Bool
    @State private var tab: StoreTab = .inicio
    @State private var search = ""

    private var filteredPackages: [DiamondPackage] {
        guard !search.isEmpty else { return packages }
        return packages.filter { $0.diamonds.contains(search) || $0.label.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .inicio: home
                case .paquetes: packagesPage
                case .pedidos: OrdersView()
                case .perfil:
                    ProfileView(existing: profile) { updated in ProfileStore.save(updated); showingProfile = false }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            BottomBar(tab: $tab)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AnimatedDiamondLogo(size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXUS").font(.caption.weight(.black)).tracking(3).foregroundStyle(.cyan)
                Text("DIAMANTES").font(.headline.weight(.black)).tracking(1)
            }
            Spacer()
            Button { tab = .perfil } label: { AvatarView(profile: profile, size: 44) }
        }
    }

    private var home: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                HeroBanner { tab = .paquetes }
                HStack(spacing: 12) {
                    FeaturePill(icon: "bolt.fill", title: "Entrega rápida", color: .yellow)
                    FeaturePill(icon: "checkmark.shield.fill", title: "Compra segura", color: .green)
                }
                sectionTitle("PAQUETES DESTACADOS", action: "Ver todos") { tab = .paquetes }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(Array(packages.prefix(4))) { package in PackageCard(package: package) { openCheckout(package) } }
                }
                InfoCard()
            }
            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 24)
        }
    }

    private var packagesPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                VStack(alignment: .leading, spacing: 5) {
                    Text("Todos los paquetes").font(.system(size: 32, weight: .black, design: .rounded))
                    Text("Selecciona la cantidad de diamantes para tu cuenta.").foregroundStyle(.secondary)
                }
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Buscar paquete", text: $search).textInputAutocapitalization(.never)
                    if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.foregroundStyle(.secondary) }
                }
                .padding(14).background(.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 16))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(filteredPackages) { package in PackageCard(package: package) { openCheckout(package) } }
                }
                if filteredPackages.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "diamond").font(.system(size: 36)).foregroundStyle(.cyan)
                        Text("No encontramos paquetes").font(.headline.bold())
                        Text("Prueba con otra búsqueda.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 55)
                }
            }
            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 24)
        }
    }

    private func sectionTitle(_ title: String, action: String, actionHandler: @escaping () -> Void) -> some View {
        HStack { Text(title).font(.caption.weight(.black)).tracking(1.6); Spacer(); Button(action, action: actionHandler).font(.caption.weight(.bold)).foregroundStyle(.cyan) }
    }

    private func openCheckout(_ package: DiamondPackage) { cartPackage = package; showingCheckout = true }
}

struct AnimatedDiamondLogo: View {
    let size: CGFloat
    @State private var spin = false
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [.cyan.opacity(0.27), .blue.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "diamond.fill").font(.system(size: size * 0.43, weight: .bold)).foregroundStyle(LinearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom)).rotationEffect(.degrees(spin ? 360 : 0)).scaleEffect(pulse ? 1.08 : 0.94)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(.cyan.opacity(0.45), lineWidth: 1))
        .onAppear {
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

struct HeroBanner: View {
    let action: () -> Void
    @State private var shimmer = false
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [.blue.opacity(0.72), .purple.opacity(0.56), .black.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "diamond.2.fill").font(.system(size: 160)).foregroundStyle(.white.opacity(0.08)).rotationEffect(.degrees(-18)).offset(x: 34, y: 38)
            VStack(alignment: .leading, spacing: 12) {
                HStack { Label("RECARGA PREMIUM", systemImage: "sparkles").font(.caption.weight(.black)).foregroundStyle(.cyan); Spacer(); Text("01").font(.caption.monospaced().bold()).foregroundStyle(.white.opacity(0.55)) }
                Text("Brilla en cada partida.").font(.system(size: 30, weight: .black, design: .rounded)).fixedSize(horizontal: false, vertical: true)
                Text("Diamantes para Free Fire, con atención personalizada y métodos de pago flexibles.").font(.subheadline).foregroundStyle(.white.opacity(0.78)).fixedSize(horizontal: false, vertical: true)
                Button(action: action) { Text("Ver paquetes").font(.subheadline.weight(.bold)).padding(.horizontal, 16).padding(.vertical, 10).background(.white).foregroundStyle(.blue).clipShape(Capsule()) }
            }
            .padding(22)
        }
        .frame(minHeight: 245)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.14)))
        .shadow(color: .blue.opacity(0.25), radius: shimmer ? 24 : 12)
        .onAppear { withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { shimmer = true } }
    }
}

struct FeaturePill: View {
    let icon: String; let title: String; let color: Color
    var body: some View { HStack(spacing: 8) { Image(systemName: icon).foregroundStyle(color); Text(title).font(.caption.weight(.bold)).lineLimit(1) }.frame(maxWidth: .infinity).padding(.vertical, 12).background(.white.opacity(0.07)).clipShape(Capsule()) }
}

struct PackageCard: View {
    let package: DiamondPackage
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: "diamond.fill").font(.title3).foregroundStyle(package.accent); Spacer(); if let badge = package.badge { Text(badge).font(.system(size: 8, weight: .black)).foregroundStyle(package.accent).padding(.horizontal, 7).padding(.vertical, 5).background(package.accent.opacity(0.13)).clipShape(Capsule()) } }
            Text(package.diamonds).font(.system(size: 25, weight: .black, design: .rounded)).minimumScaleFactor(0.7)
            Text("DIAMANTES").font(.system(size: 9, weight: .black)).tracking(1.2).foregroundStyle(.secondary)
            Divider().overlay(.white.opacity(0.1))
            HStack(alignment: .firstTextBaseline) { Text(String(format: "$%.2f", package.price)).font(.title3.weight(.black)); Text("USD").font(.caption2.weight(.bold)).foregroundStyle(.secondary) }
            Text(package.label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Button(action: { withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { pressed = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { pressed = false }; action() }) { HStack { Text("COMPRAR"); Image(systemName: "arrow.up.right") }.font(.caption.weight(.black)).frame(maxWidth: .infinity).padding(.vertical, 10) }.buttonStyle(.borderedProminent).tint(package.accent).scaleEffect(pressed ? 0.94 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(15).background(.white.opacity(0.075)).clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(package.accent.opacity(package.badge == nil ? 0.18 : 0.55), lineWidth: 1))
    }
}

struct InfoCard: View {
    var body: some View { HStack(spacing: 14) { Image(systemName: "checkmark.shield.fill").font(.title2).foregroundStyle(.green); VStack(alignment: .leading, spacing: 4) { Text("Compra responsable").font(.headline.weight(.bold)); Text("Nunca compartas tu contraseña. La entrega y el pago se verifican manualmente.").font(.caption).foregroundStyle(.secondary) }; Spacer() }.padding(16).background(.green.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.green.opacity(0.2))) }
}

struct BottomBar: View {
    @Binding var tab: StoreTab
    var body: some View { HStack(spacing: 4) { ForEach(StoreTab.allCases, id: \.self) { item in Button { withAnimation(.easeInOut(duration: 0.22)) { tab = item } } label: { VStack(spacing: 5) { Image(systemName: item.icon).font(.system(size: 17, weight: .semibold)); Text(item.rawValue).font(.system(size: 10, weight: .bold)) }.foregroundStyle(tab == item ? .cyan : .secondary).frame(maxWidth: .infinity).padding(.vertical, 10).background(tab == item ? .cyan.opacity(0.12) : .clear).clipShape(RoundedRectangle(cornerRadius: 14)) } } }.padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 4).background(.ultraThinMaterial).overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.08)).frame(height: 1) } }
}

struct OrdersView: View {
    @State private var orders = OrderStore.load()
    var body: some View { ScrollView(showsIndicators: false) { VStack(alignment: .leading, spacing: 18) { Text("Mis pedidos").font(.system(size: 32, weight: .black, design: .rounded)); Text("Consulta aquí tus recargas realizadas desde esta app.").foregroundStyle(.secondary); if orders.isEmpty { VStack(spacing: 14) { Image(systemName: "clock.arrow.circlepath").font(.system(size: 42)).foregroundStyle(.cyan); Text("Todavía no hay pedidos").font(.title3.bold()); Text("Cuando prepares una compra aparecerá en esta sección.").multilineTextAlignment(.center).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 80) } else { ForEach(orders) { order in OrderRow(order: order) } } }.padding(18) }.onAppear { orders = OrderStore.load() } }
}

struct OrderRow: View {
    let order: LocalOrder
    var body: some View { HStack(spacing: 14) { Image(systemName: "diamond.fill").font(.title2).foregroundStyle(.cyan).frame(width: 48, height: 48).background(.cyan.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading, spacing: 4) { Text(order.packageName).font(.headline.bold()); Text("ID \(order.playerID) · \(order.region)").font(.caption).foregroundStyle(.secondary); Text(order.date, style: .date).font(.caption2).foregroundStyle(.secondary) }; Spacer(); VStack(alignment: .trailing, spacing: 5) { Text(String(format: "$%.2f", order.price)).font(.subheadline.bold()); Text(order.status).font(.caption2.bold()).foregroundStyle(.green) } }.padding(14).background(.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 18)) }
}

struct ProfileView: View {
    let existing: LocalProfile?
    let onSave: (LocalProfile) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String; @State private var email: String; @State private var password = ""; @State private var avatar: Data?; @State private var photoItem: PhotosPickerItem?; @State private var error = ""
    init(existing: LocalProfile?, onSave: @escaping (LocalProfile) -> Void) { self.existing = existing; self.onSave = onSave; _name = State(initialValue: existing?.name ?? ""); _email = State(initialValue: existing?.email ?? ""); _avatar = State(initialValue: existing?.avatar) }
    var body: some View { ScrollView { VStack(spacing: 22) { if existing == nil { AnimatedDiamondLogo(size: 78); VStack(spacing: 7) { Text("Bienvenido a NEXUS").font(.system(size: 30, weight: .black, design: .rounded)); Text("Crea tu perfil para comenzar").foregroundStyle(.secondary) } } else { HStack { Text("Tu perfil").font(.system(size: 30, weight: .black, design: .rounded)); Spacer(); Button("Cerrar") { dismiss() }.foregroundStyle(.cyan) } }; VStack(spacing: 16) { AvatarView(data: avatar, size: 112); PhotosPicker(selection: $photoItem, matching: .images) { Label("Elegir foto de perfil", systemImage: "photo.on.rectangle") }.buttonStyle(.bordered); field("Nombre", icon: "person.fill", text: $name); field("Correo", icon: "envelope.fill", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never); HStack { Image(systemName: "lock.fill").foregroundStyle(.cyan); SecureField(existing == nil ? "Contraseña (mínimo 6)" : "Nueva contraseña opcional", text: $password) }.padding(16).background(.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 15)) }; if !error.isEmpty { Text(error).foregroundStyle(.red).font(.caption) }; Button { save() } label: { Text(existing == nil ? "Entrar a la tienda" : "Guardar cambios").font(.headline.bold()).frame(maxWidth: .infinity).padding(.vertical, 16) }.buttonStyle(.borderedProminent).tint(.cyan); Text("Tu perfil se guarda únicamente en este iPhone. No usamos Supabase ni login externo.").multilineTextAlignment(.center).font(.caption).foregroundStyle(.secondary) }.padding(22) }.onChange(of: photoItem) { item in Task { await loadPhoto(item) } }.preferredColorScheme(.dark) }
    private func field(_ title: String, icon: String, text: Binding<String>) -> some View { HStack { Image(systemName: icon).foregroundStyle(.cyan); TextField(title, text: text) }.padding(16).background(.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 15)) }
    private func loadPhoto(_ item: PhotosPickerItem?) async { guard let item, let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data), let resized = image.jpegData(compressionQuality: 0.8) else { return }; await MainActor.run { avatar = resized } }
    private func save() { guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, email.contains("@"), existing != nil || password.count >= 6 else { error = "Completa nombre, correo y una contraseña de mínimo 6 caracteres."; return }; let hash = password.isEmpty ? (existing?.passwordHash ?? "") : SHA256.hash(data: Data(password.utf8)).map { String(format: "%02x", $0) }.joined(); onSave(LocalProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: email, passwordHash: hash, avatar: avatar)); dismiss() }
}

struct AvatarView: View {
    var profile: LocalProfile? = nil; var data: Data? = nil; let size: CGFloat
    init(profile: LocalProfile, size: CGFloat) { self.profile = profile; self.size = size }
    init(data: Data?, size: CGFloat) { self.data = data; self.size = size }
    var body: some View { Group { if let imageData = data ?? profile?.avatar, let image = UIImage(data: imageData) { Image(uiImage: image).resizable().scaledToFill() } else { Text(String((profile?.name ?? "N").prefix(1)).uppercased()).font(.system(size: size * 0.38, weight: .black)).foregroundStyle(.white) } }.frame(width: size, height: size).background(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(Circle()).overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2)) }
}

enum PaymentMethod: String, CaseIterable, Identifiable { case paypal = "PayPal"; case cashApp = "Cash App"; case zelle = "Zelle"; case whatsapp = "WhatsApp"; var id: String { rawValue } }

struct CheckoutView: View {
    let profile: LocalProfile; let package: DiamondPackage
    @Environment(\.dismiss) private var dismiss
    @State private var playerID = ""; @State private var region = "LATAM Norte"; @State private var method: PaymentMethod = .paypal; @State private var message = ""; @State private var showingMessage = false
    var body: some View { NavigationStack { Form { Section { HStack { AnimatedDiamondLogo(size: 54); VStack(alignment: .leading) { Text(package.diamonds).font(.title2.bold()); Text("diamantes").font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(String(format: "$%.2f", package.price)).font(.title3.bold()) }.padding(.vertical, 6) }; Section("Destino de la recarga") { TextField("ID del jugador", text: $playerID).keyboardType(.numberPad); Picker("Región", selection: $region) { ForEach(["LATAM Norte", "LATAM Sur", "Brasil", "NA", "EU", "Indonesia", "MENA"], id: \.self) { Text($0) } } }; Section("Método de pago") { Picker("Pagar con", selection: $method) { ForEach(PaymentMethod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu) }; Section { Button { pay() } label: { Label("Continuar al pago", systemImage: "arrow.up.right.circle.fill").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent) }; Section { Text("La entrega se confirma manualmente. Nunca compartas tu contraseña.").font(.caption).foregroundStyle(.secondary) } }.navigationTitle("Finalizar pedido").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }.alert("Pedido preparado", isPresented: $showingMessage) { Button("OK") { dismiss() } } message: { Text(message) } } }
    private func pay() { guard !playerID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { message = "Escribe el ID del jugador."; showingMessage = true; return }; let amount = String(format: "%.2f", package.price); let order = LocalOrder(id: UUID(), packageName: "\(package.diamonds) diamantes", price: package.price, playerID: playerID, region: region, date: Date(), status: "Pendiente"); OrderStore.save(order); let text = "Hola NEXUS DIAMANTES, quiero pagar \(package.diamonds) diamantes (\(amount) USD). Mi ID es \(playerID), región \(region)."; let destination: String?; switch method { case .paypal: destination = "https://www.paypal.me/MaykTzoc760/\(amount)"; case .cashApp: destination = "https://cash.app/$MaykTzoc5/\(amount)"; case .whatsapp: destination = "https://wa.me/13473667628?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"; case .zelle: destination = nil }; if let destination, let url = URL(string: destination) { UIApplication.shared.open(url) }; message = method == .zelle ? "Envía $\(amount) USD por Zelle y comparte el comprobante por WhatsApp." : "Se abrió \(method.rawValue). Después comparte el comprobante por WhatsApp."; showingMessage = true }
}
