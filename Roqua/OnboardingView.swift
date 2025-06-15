import SwiftUI

// MARK: - Onboarding Flow
struct OnboardingView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var currentStep: OnboardingStep = .welcome
    @State private var showingMainApp = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.black, .blue.opacity(0.8), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            switch currentStep {
            case .welcome:
                WelcomeStep(onNext: { currentStep = .features })
            case .features:
                FeaturesStep(onNext: { currentStep = .privacy })
            case .privacy:
                PrivacyStep(onNext: { currentStep = .locationPermission })
            case .locationPermission:
                LocationPermissionStep(
                    locationManager: locationManager,
                    onNext: { currentStep = .alwaysPermission }
                )
            case .alwaysPermission:
                AlwaysPermissionStep(
                    locationManager: locationManager,
                    onComplete: { showingMainApp = true }
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkExistingPermissionsAndSkip()
        }
        .onChange(of: showingMainApp) { _, newValue in
            if newValue {
                NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
            }
        }
    }
    
    private func checkExistingPermissionsAndSkip() {
        // Mevcut izinleri kontrol et ve uygun adıma geç
        switch locationManager.permissionState {
        case .alwaysGranted:
            // Always permission varsa direkt ana uygulamaya geç
            print("✅ Always permission already exists - skipping onboarding")
            showingMainApp = true
        case .whenInUseGranted:
            // When in use permission varsa always permission adımına geç
            print("✅ When in use permission exists - skipping to always permission step")
            currentStep = .alwaysPermission
        case .denied, .restricted:
            // İzin reddedildiyse location permission adımına geç
            print("❌ Permission denied - going to location permission step")
            currentStep = .locationPermission
        case .notRequested, .requesting, .unknown:
            // İzin istenmemişse normal akışa devam et
            print("📍 No permission yet - starting normal onboarding flow")
            break
        }
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep {
    case welcome
    case features
    case privacy
    case locationPermission
    case alwaysPermission
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo/Icon
            Image(systemName: "globe")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                Text("Roqua")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Kendi dünyeni keşfet")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Text("Gezdiğin her yer, haritanda aydınlanır")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: onNext) {
                    HStack {
                        Text("Başla")
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Features Step
struct FeaturesStep: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Roqua Nasıl Çalışır?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Sade, güvenli ve tamamen senin")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 50)
            
            VStack(spacing: 24) {
                FeatureCard(
                    icon: "location.fill",
                    title: "Arka Planda Takip",
                    description: "Uygulamayı kapatsan bile gezdiğin yerleri otomatik kaydeder"
                )
                
                FeatureCard(
                    icon: "eye.slash.fill",
                    title: "100% Gizli",
                    description: "Verilerin sadece cihazında. Hiçbir sunucuya gönderilmez"
                )
                
                FeatureCard(
                    icon: "chart.pie.fill",
                    title: "Keşif İstatistikleri",
                    description: "Dünyanın yüzde kaçını keşfettiğini görürsün"
                )
            }
            
            Spacer()
            
            Button(action: onNext) {
                HStack {
                    Text("Devam Et")
                        .fontWeight(.medium)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Privacy Step
struct PrivacyStep: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                
                Text("Gizliliğin Öncelik")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 50)
            
            VStack(spacing: 20) {
                PrivacyCard(
                    icon: "iphone",
                    title: "Offline Çalışır",
                    description: "Tüm veriler cihazında saklanır. İnternet gerektirmez."
                )
                
                PrivacyCard(
                    icon: "person.slash.fill",
                    title: "Hesap Yok",
                    description: "Kayıt olmaya gerek yok. Kişisel bilgi istenmez."
                )
                
                PrivacyCard(
                    icon: "server.rack",
                    title: "Sunucu Yok",
                    description: "Hiçbir verinin kopyası bizde tutulmaz."
                )
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Text("Sadece konumun gerekli, o da sadece cihazında")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: onNext) {
                    HStack {
                        Text("Güvenli, Devam Et")
                            .fontWeight(.medium)
                        Image(systemName: "checkmark.shield.fill")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Privacy Card
struct PrivacyCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Location Permission Step
struct LocationPermissionStep: View {
    @ObservedObject var locationManager: LocationManager
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("Konum İzni")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Gezdiğin yerleri takip edebilmek için konum izni gerekli")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 50)
            
            VStack(spacing: 16) {
                LocationBenefitItem(
                    icon: "map.fill",
                    text: "Sadece gezilen alanlar haritada açılır"
                )
                
                LocationBenefitItem(
                    icon: "lock.fill",
                    text: "Konum verisi cihazından çıkmaz"
                )
                
                LocationBenefitItem(
                    icon: "chart.bar.fill",
                    text: "Keşif istatistiklerin hesaplanır"
                )
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                if locationManager.permissionState == .requesting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        
                        Text("İzin isteniyor...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if locationManager.permissionState == .whenInUseGranted {
                    Button(action: onNext) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("İzin Verildi, Devam Et")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else if locationManager.permissionState == .alwaysGranted {
                    Button(action: onNext) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Sürekli İzin Verildi, Devam Et")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else if locationManager.permissionState == .denied {
                    VStack(spacing: 12) {
                        Text("Konum izni reddedildi")
                            .foregroundStyle(.red)
                            .font(.callout)
                        
                        Button("Ayarlara Git") {
                            locationManager.openSettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                } else {
                    Button(action: {
                        print("🎯 User tapped permission button")
                        Task {
                            await locationManager.requestWhenInUsePermission()
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Konum İzni Ver")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(locationManager.permissionState == .requesting)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Always Permission Step
struct AlwaysPermissionStep: View {
    @ObservedObject var locationManager: LocationManager
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple)
                
                Text("Sürekli Takip")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Uygulamayı kapatsan bile keşifler devam etsin")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 50)
            
            VStack(spacing: 16) {
                AlwaysBenefitItem(
                    icon: "moon.zzz.fill",
                    text: "Uygulama kapandığında bile çalışır"
                )
                
                AlwaysBenefitItem(
                    icon: "battery.25",
                    text: "Optimize edilmiş, batarya dostu"
                )
                
                AlwaysBenefitItem(
                    icon: "map.circle.fill",
                    text: "Hiçbir keşfi kaçırmazsın"
                )
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                if locationManager.permissionState == .requesting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                            .scaleEffect(1.2)
                        
                        Text("Sürekli izin isteniyor...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if locationManager.permissionState == .alwaysGranted {
                    Button(action: onComplete) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Tamamlandı! Roqua'ya Başla")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else if locationManager.canRequestAlwaysPermission {
                    VStack(spacing: 16) {
                        Button(action: {
                            print("🎯 User requesting always permission")
                            Task {
                                await locationManager.requestAlwaysPermission()
                            }
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Sürekli İzin Ver")
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(locationManager.permissionState == .requesting)
                        
                        Button("Şimdilik Atla") {
                            print("🎯 User skipping always permission")
                            onComplete()
                        }
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    }
                } else {
                    Button(action: onComplete) {
                        Text("Roqua'ya Başla")
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Helper Views
struct LocationBenefitItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .foregroundStyle(.secondary)
                .font(.callout)
            
            Spacer()
        }
    }
}

struct AlwaysBenefitItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 24)
            
            Text(text)
                .foregroundStyle(.secondary)
                .font(.callout)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
} 