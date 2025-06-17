import SwiftUI

// MARK: - Side Menu Overlay (Yandan açılan)
struct SideMenuOverlay: View {
    @Binding var isShowing: Bool
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Roqua")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Keşfet, Kaydet, Kazan")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 30)
            
            // Menu Items
            VStack(spacing: 0) {
                // Keşif Section
                MenuSectionHeader(title: "Keşif")
                
                MenuButton(
                    icon: "trophy.fill",
                    title: "Başarımlar",
                    description: "Rozetlerinizi görün"
                ) {
                    closeMenuAndNavigate(to: "achievements")
                }
                
                MenuButton(
                    icon: "chart.bar.fill",
                    title: "İstatistikler",
                    description: "Keşif verileriniz"
                ) {
                    closeMenuAndNavigate(to: "statistics")
                }
                
                // Uygulama Section
                MenuSectionHeader(title: "Uygulama")
                
                MenuButton(
                    icon: "info.circle.fill",
                    title: "Hakkında",
                    description: "Uygulama bilgileri"
                ) {
                    closeMenuAndNavigate(to: "about")
                }
                
                MenuButton(
                    icon: "person.circle.fill",
                    title: "Hesap",
                    description: "Profil ayarları"
                ) {
                    closeMenuAndNavigate(to: "account")
                }
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                Text("Sürüm 1.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Privacy-First Exploration")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 60)
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
    }
    
    private func closeMenuAndNavigate(to destination: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            navigationPath.append(destination)
        }
    }
}

// MARK: - Original SideMenuView (Sheet versiyonu - backward compatibility)
struct SideMenuView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text("Roqua")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Keşfet, Kaydet, Kazan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Menu Items
                VStack(spacing: 0) {
                    // Keşif Section
                    MenuSectionHeader(title: "Keşif")
                    
                    MenuButton(
                        icon: "trophy.fill",
                        title: "Başarımlar",
                        description: "Rozetlerinizi görün"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationPath.append("achievements")
                        }
                    }
                    
                    MenuButton(
                        icon: "chart.bar.fill",
                        title: "İstatistikler",
                        description: "Keşif verileriniz"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationPath.append("statistics")
                        }
                    }
                    
                    // Uygulama Section
                    MenuSectionHeader(title: "Uygulama")
                    
                    MenuButton(
                        icon: "gearshape.fill",
                        title: "Ayarlar",
                        description: "Uygulama tercihleriniz"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationPath.append("settings")
                        }
                    }
                    
                    MenuButton(
                        icon: "info.circle.fill",
                        title: "Hakkında",
                        description: "Uygulama bilgileri"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationPath.append("about")
                        }
                    }
                    
                    MenuButton(
                        icon: "person.circle.fill",
                        title: "Hesap",
                        description: "Profil ayarları"
                    ) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationPath.append("account")
                        }
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("Sürüm 1.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Privacy-First Exploration")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Menu Components
struct MenuSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Preview
struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(navigationPath: .constant(NavigationPath()))
    }
} 