
import SwiftUI
import CoreLocation

struct HomeView: View {
    
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    WelcomeHealthView().padding()
                }
            }
            .navigationTitle("Pulse")
        }
    }
}

