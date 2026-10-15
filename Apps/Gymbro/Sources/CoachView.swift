import GymbroDomain
import SwiftUI

struct CoachView: View {
    @Environment(GymbroStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                OGPageHeader(
                    title: "Coach",
                    subtitle: "Consejos a partir de tu historial, fatiga y peso. Sin internet."
                )

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
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(OG.bg)
        .ogContentTitleNav()
    }
}
