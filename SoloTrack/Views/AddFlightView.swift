import SwiftUI
import SwiftData

struct AddFlightView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var date = Date.now
    @State private var durationHobbs = ""
    @State private var durationTach = ""
    @State private var routeFrom = ""
    @State private var routeTo = ""
    @State private var landingsDay = 0
    @State private var landingsNightFullStop = 0
    @State private var isSolo = false
    @State private var isDualReceived = false
    @State private var isCrossCountry = false
    @State private var isSimulatedInstrument = false
    @State private var remarks = ""

    // Signature
    @State private var signatureData: Data?
    @State private var cfiNumber = ""

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                dateAndRouteSection
                durationSection
                landingsSection
                categoriesSection
                remarksSection
                signatureSection
            }
            .navigationTitle("Log Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveFlight() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Missing Information", isPresented: $showingValidationAlert) {
                Button("OK") {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Date & Route

    private var dateAndRouteSection: some View {
        Section {
            DatePicker("Date", selection: $date, displayedComponents: .date)

            HStack {
                VStack(alignment: .leading) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("ICAO", text: $routeFrom)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("ICAO", text: $routeTo)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                }
            }
        } header: {
            Text("Route")
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        Section {
            HStack {
                Text("Hobbs")
                Spacer()
                TextField("0.0", text: $durationHobbs)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("hrs")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Tach")
                Spacer()
                TextField("0.0", text: $durationTach)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("hrs")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Duration")
        }
    }

    // MARK: - Landings

    private var landingsSection: some View {
        Section {
            Stepper("Day Landings: \(landingsDay)", value: $landingsDay, in: 0...99)
            Stepper("Night Full-Stop: \(landingsNightFullStop)", value: $landingsNightFullStop, in: 0...99)
        } header: {
            Text("Landings")
        }
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        Section {
            Toggle("Solo", isOn: $isSolo)
                .onChange(of: isSolo) { _, newValue in
                    if newValue { isDualReceived = false }
                }

            Toggle("Dual Received", isOn: $isDualReceived)
                .onChange(of: isDualReceived) { _, newValue in
                    if newValue { isSolo = false }
                }

            Toggle("Cross-Country (XC)", isOn: $isCrossCountry)
            Toggle("Simulated Instrument", isOn: $isSimulatedInstrument)
        } header: {
            Text("Categories")
        }
    }

    // MARK: - Remarks

    private var remarksSection: some View {
        Section {
            TextField("Flight notes...", text: $remarks, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Remarks")
        }
    }

    // MARK: - Signature

    private var signatureSection: some View {
        Section {
            SignatureCaptureView(
                signatureData: $signatureData,
                cfiNumber: $cfiNumber
            )
        } header: {
            Text("Instructor")
        } footer: {
            Text("Per AC 120-78, electronic signatures are accepted. The signature will be locked once saved.")
        }
    }

    // MARK: - Save

    private func saveFlight() {
        guard let hobbs = Double(durationHobbs), hobbs > 0 else {
            validationMessage = "Please enter a valid Hobbs time."
            showingValidationAlert = true
            return
        }

        let tach = Double(durationTach) ?? 0.0

        let shouldLockSignature = signatureData != nil && !cfiNumber.isEmpty

        let flight = FlightLog(
            date: date,
            durationHobbs: hobbs,
            durationTach: tach,
            routeFrom: routeFrom.trimmingCharacters(in: .whitespaces),
            routeTo: routeTo.trimmingCharacters(in: .whitespaces),
            landingsDay: landingsDay,
            landingsNightFullStop: landingsNightFullStop,
            isSolo: isSolo,
            isDualReceived: isDualReceived,
            isCrossCountry: isCrossCountry,
            isSimulatedInstrument: isSimulatedInstrument,
            instructorSignature: signatureData,
            cfiNumber: cfiNumber.trimmingCharacters(in: .whitespaces),
            signatureDate: shouldLockSignature ? .now : nil,
            isSignatureLocked: shouldLockSignature,
            remarks: remarks
        )

        modelContext.insert(flight)
        dismiss()
    }
}

#Preview {
    AddFlightView()
        .modelContainer(for: FlightLog.self, inMemory: true)
}
