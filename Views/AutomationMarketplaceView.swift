import SwiftUI

struct AutomationMarketplaceView: View {
    @ObservedObject private var marketplace = AutomationMarketplace.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text("Automation Marketplace")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal, 80)
                    .padding(.top, 60)
                
                Text("Download pre-built automations from the community")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 80)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), spacing: 30)], spacing: 30) {
                    ForEach(marketplace.templates) { template in
                        TemplateCard(template: template)
                    }
                }
                .padding(.horizontal, 80)
            }
            .padding(.bottom, 60)
        }
    }
}

struct TemplateCard: View {
    let template: AutomationMarketplace.AutomationTemplate
    @ObservedObject private var marketplace = AutomationMarketplace.shared
    
    var isInstalled: Bool {
        marketplace.installedTemplates.contains(template.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.title3)
                        .bold()
                    
                    Text(template.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(template.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", template.rating))
                        .font(.caption)
                }
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(template.downloadCount) downloads")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    marketplace.installTemplate(template)
                }) {
                    HStack {
                        Image(systemName: isInstalled ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                        Text(isInstalled ? "Installed" : "Install")
                    }
                    .font(.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isInstalled ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(isInstalled)
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
    
    var categoryIcon: String {
        switch template.category {
        case .security: return "lock.shield.fill"
        case .energy: return "bolt.fill"
        case .comfort: return "house.fill"
        case .entertainment: return "tv.fill"
        case .health: return "heart.fill"
        }
    }
}