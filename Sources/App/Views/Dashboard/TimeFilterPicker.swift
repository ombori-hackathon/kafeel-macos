import SwiftUI

struct TimeFilterPicker: View {
    @Binding var selectedFilter: TimeFilter

    var body: some View {
        Picker("Time Period", selection: $selectedFilter) {
            ForEach(TimeFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

#Preview {
    @Previewable @State var filter: TimeFilter = .day

    VStack {
        TimeFilterPicker(selectedFilter: $filter)
        Text("Selected: \(filter.rawValue)")
    }
    .padding()
    .frame(width: 300)
}
