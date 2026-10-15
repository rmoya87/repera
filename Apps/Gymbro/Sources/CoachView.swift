import GymbroDomain
import SwiftUI

struct CoachView: View {
    @Environment(GymbroStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Coach local")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(OG.label)
                Text("Consejos a partir de tu historial, fatiga y peso. Sin internet.")
                    .font(.system(size: 15))
                    .foregroundStyle(OG.label2)

                ForEach(store.coachInsights) { insight in
                    OGCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(insight.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(OG.label)
                            Text(insight.detail)
                                .font(.system(size: 15))
                                .foregroundStyle(OG.label2)
                        }
                    }
                }
            }
            .padding(.horizontal, OG.pad)
            .padding(.vertical, 12)
        }
        .background(OG.bg)
        .navigationTitle("Coach")
        .toolbarBackground(OG.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
