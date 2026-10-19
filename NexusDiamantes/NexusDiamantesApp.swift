import SwiftUI

@main
struct NexusDiamantesApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
    }
}

struct LaunchView: View {
    @State private var finished = false
    @State private var progress = 0.0
    @State private var logoScale = 0.72
    @State private var glow = false

    var body: some View {
        ZStack {
            if finished {
                ContentView().transition(.opacity)
            } else {
                LinearGradient(colors: [Color(red: 0.02, green: 0.03, blue: 0.11), .blue.opacity(0.55), .purple.opacity(0.32)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                Circle().fill(.cyan.opacity(glow ? 0.22 : 0.08)).frame(width: 260).blur(radius: 70).scaleEffect(glow ? 1.25 : 0.8)
                VStack(spacing: 24) {
                    AnimatedDiamondLogo(size: 116).scaleEffect(logoScale).shadow(color: .cyan.opacity(0.8), radius: glow ? 28 : 10)
                    VStack(spacing: 6) { Text("NEXUS").font(.system(size: 35, weight: .black, design: .rounded)).tracking(7); Text("DIAMANTES").font(.caption.weight(.black)).tracking(5).foregroundStyle(.cyan) }
                    VStack(spacing: 10) { ProgressView(value: progress).tint(.cyan).frame(width: 180); Text("Preparando tu tienda").font(.caption).foregroundStyle(.white.opacity(0.65)) }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.62)) { logoScale = 1; glow = true }
            withAnimation(.easeInOut(duration: 1.5)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { withAnimation(.easeInOut(duration: 0.45)) { finished = true } }
        }
    }
}
