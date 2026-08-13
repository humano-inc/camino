import SwiftUI

struct PiecePicker: View {
    @Binding var amountMg: Double
    var showsCustomField: Bool = true

    @State private var choice: PieceChoice?
    @State private var customText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                ForEach(PieceChoice.allCases, id: \.self) { piece in
                    pieceButton(piece)
                }
            }
            .padding(2)
            .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(Copy.pieceUnit)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if showsCustomField, choice == .custom, amountMg > Tablet.epsilon || !customText.isEmpty {
                TextField("mg", text: $customText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Custom milligrams")
                    .onChange(of: customText) { _, new in
                        if let value = Double(new.replacingOccurrences(of: ",", with: ".")), value >= 0 {
                            amountMg = value
                        }
                    }
            }
        }
        .onAppear { syncFromAmount() }
        .onChange(of: amountMg) { _, _ in
            if choice != .custom {
                syncFromAmount()
            }
        }
    }

    private func pieceButton(_ piece: PieceChoice) -> some View {
        let selected = choice == piece
        return Button {
            choice = piece
            if let mg = piece.milligrams {
                amountMg = mg
                customText = ""
            } else {
                customText = formatMg(amountMg)
            }
        } label: {
            VStack(spacing: 1) {
                Text(piece.glyph)
                    .font(.system(size: piece == .custom ? 15 : 16, weight: selected ? .semibold : .regular))
                Text(piece.secondary)
                    .font(.system(size: 10))
                    .foregroundStyle(selected ? Color.white.opacity(0.7) : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemBackground))
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel(piece == .custom ? Copy.custom : "\(piece.glyph), \(piece.secondary) milligrams")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func syncFromAmount() {
        if amountMg <= Tablet.epsilon {
            choice = nil
            customText = ""
            return
        }
        let matched = PieceChoice.matching(amountMg)
        choice = matched
        if matched == .custom {
            customText = formatMg(amountMg)
        }
    }
}
