import SwiftUI

struct SettingsPageView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LocationSettingsTab()
                .tabItem {
                    Image(systemName: "location.circle.fill")
                    Text("Konum")
                }
                .tag(0)
            
            ExplorationSettingsTab()
                .tabItem {
                    Image(systemName: "map.circle.fill")
                    Text("Keşif")
                }
                .tag(1)
            
            AppearanceSettingsTab()
                .tabItem {
                    Image(systemName: "paintbrush.fill")
                    Text("Görünüm")
                }
                .tag(2)
            
            PrivacySettingsTab()
                .tabItem {
                    Image(systemName: "lock.shield.fill")
                    Text("Gizlilik")
                }
                .tag(3)
            
            SystemSettingsTab()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Sistem")
                }
                .tag(4)
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(.activeTab)
    }
}

// MARK: - Tab views are implemented in separate files

// MARK: - Preview
struct SettingsPageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsPageView()
        }
    }
} 