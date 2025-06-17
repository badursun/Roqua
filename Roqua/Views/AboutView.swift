import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Roqua")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Sürüm 1.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Privacy-First Exploration")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("• Gizlilik dostu keşif uygulaması")
                    Text("• Verileriniz sadece cihazınızda")
                    Text("• İnternet gerektirmez")
                    Text("• Offline çalışır")
                }
                .font(.body)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Hakkında")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
    }
} 