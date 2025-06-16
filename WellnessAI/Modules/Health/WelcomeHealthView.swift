import SwiftUI
struct WelcomeHealthView: View {
    
    @State private var showHealthCards = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Welcome to Pulse")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("“Health is the greatest gift, contentment the greatest wealth, faithfulness the best relationship.”")
                .font(.title3)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showHealthCards = true
            }) {
                Text("Create your health card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.cornerRadius(12))
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            NavigationLink(destination: HealthCardsView(), isActive: $showHealthCards) {
                EmptyView()
            }
        }
        .padding()
        //.navigationBarHidden(true) // Optional depending on your design
    }
}
