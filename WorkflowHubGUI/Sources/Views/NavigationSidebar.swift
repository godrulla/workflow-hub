import SwiftUI

struct NavigationSidebar: View {
    @Binding var selectedItem: SidebarItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workflow Hub")
                .font(.headline)
                .padding()
            
            ForEach(SidebarItem.allCases) { item in
                Button(action: {
                    selectedItem = item
                }) {
                    HStack {
                        Image(systemName: item.iconName)
                        Text(item.rawValue)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(selectedItem == item ? Color.blue.opacity(0.2) : Color.clear)
                .cornerRadius(6)
            }
            
            Spacer()
        }
        .frame(minWidth: 250)
        .background(Color(NSColor.controlBackgroundColor))
    }
}