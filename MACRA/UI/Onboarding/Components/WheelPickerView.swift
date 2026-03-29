import SwiftUI
import UIKit

// MARK: - WheelPickerView (UIKit UIPickerView wrapper)

struct WheelPickerView: UIViewRepresentable {
    let items: [String]
    @Binding var selectedIndex: Int
    let rowHeight: CGFloat

    init(items: [String], selectedIndex: Binding<Int>, rowHeight: CGFloat = 40) {
        self.items = items
        self._selectedIndex = selectedIndex
        self.rowHeight = rowHeight
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        picker.selectRow(selectedIndex, inComponent: 0, animated: false)

        // Style the selection indicator
        picker.subviews.forEach { view in
            if view.frame.height <= 1 {
                view.isHidden = true
            }
        }

        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        if uiView.selectedRow(inComponent: 0) != selectedIndex {
            uiView.selectRow(selectedIndex, inComponent: 0, animated: true)
        }
    }

    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        let parent: WheelPickerView

        init(_ parent: WheelPickerView) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.items.count
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            parent.rowHeight
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.textAlignment = .center

            let isSelected = row == pickerView.selectedRow(inComponent: component)

            label.text = parent.items[row]
            label.font = isSelected
                ? UIFont.systemFont(ofSize: 20, weight: .semibold)
                : UIFont.systemFont(ofSize: 16, weight: .regular)
            label.textColor = isSelected
                ? UIColor(OnboardingTheme.textPrimary)
                : UIColor(OnboardingTheme.textSecondary)

            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selectedIndex = row

            // Refresh visible rows to update styling
            pickerView.reloadAllComponents()
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
    }
}

// MARK: - Styled Wheel Picker with gradient masks

struct StyledWheelPicker: View {
    let items: [String]
    @Binding var selectedIndex: Int
    let height: CGFloat

    init(items: [String], selectedIndex: Binding<Int>, height: CGFloat = 200) {
        self.items = items
        self._selectedIndex = selectedIndex
        self.height = height
    }

    var body: some View {
        ZStack {
            // Selection highlight
            RoundedRectangle(cornerRadius: 10)
                .fill(OnboardingTheme.backgroundSecondary)
                .frame(height: 40)

            // Picker
            WheelPickerView(items: items, selectedIndex: $selectedIndex)
                .frame(height: height)

            // Top gradient mask
            VStack {
                LinearGradient(
                    colors: [OnboardingTheme.background, OnboardingTheme.background.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 70)
                Spacer()
            }
            .allowsHitTesting(false)

            // Bottom gradient mask
            VStack {
                Spacer()
                LinearGradient(
                    colors: [OnboardingTheme.background.opacity(0), OnboardingTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 70)
            }
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    @Previewable @State var index = 5
    StyledWheelPicker(
        items: (1...12).map { "Item \($0)" },
        selectedIndex: $index
    )
    .padding()
}
