import SwiftUI

struct DisclaimerView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 120)
                Text(Copy.appName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(CaminoTheme.cream)
                    .padding(.horizontal, 34)
                Text(Copy.disclaimerBody)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .lineSpacing(4)
                    .padding(.top, 22)
                    .padding(.horizontal, 34)
                Spacer()
                Button(action: onContinue) {
                    Text(Copy.continue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(CaminoTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(CaminoTheme.amber, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .accessibilityHint("Opens the first promise")
            }
        }
        .preferredColorScheme(.dark)
        .tint(CaminoTheme.amber)
    }
}
