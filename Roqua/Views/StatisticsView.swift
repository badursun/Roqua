import SwiftUI

struct StatisticsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("📊 İstatistikler")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Keşif verileriniz ve analitikler burada görünecek")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("İstatistikler")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
        }
    }
} 