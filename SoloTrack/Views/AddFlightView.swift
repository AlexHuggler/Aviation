import SwiftUI
import SwiftData

struct AddFlightView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Smart defaults: read most recent flight for pre-population (A1)
    @Query(sort: \FlightLog.date, order: .reverse, animation: .none) private var recentFlights: [FlightLog]

    /// Optional flight to edit (B6). When nil, we create a new entry.
    var editingFlight: FlightLog?

    // MARK: - Focus State (A4)

    enum Field: Hashable {
        case routeFrom, routeTo, hobbs, tach, remarks, cfiNumber
    }

    @FocusState private var focusedField: Field?

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

    // UI state
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showAdvanced = false
    @State private var hasAppliedDefaults = false

    var isEditing: Bool { editingFlight != nil }

    var body: some View {
        NavigationStack {
            Form {
                dateAndRouteSection
                durationSection
                landingsSection
                categoriesSection

                // B2: Collapsed advanced sections
                DisclosureGroup("More Details", isExpanded: $showAdvanced) {
                    remarksField
                    signatureSection
                }
                .tint(Color.skyBlue)
            }
            .navigationTitle(isEditing ? "Edit Flight" : "Log Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveFlight() }
                        .fontWeight(.semibold)
                }
                // A4: Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Missing Information", isPresented: $showingValidationAlert) {
                Button("OK") {}
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                applyDefaults()
            }
        }
    }

    // MARK: - Smart Defaults (A1)

    private func applyDefaults() {
        guard !hasAppliedDefaults else { return }
        hasAppliedDefaults = true

        if let flight = editingFlight {
            // B6: Pre-populate from editing flight
            date = flight.date
            durationHobbs = String(format: "%.1f", flight.durationHobbs)
            durationTach = flight.durationTach > 0 ? String(format: "%.1f", flight.durationTach) : ""
            routeFrom = flight.routeFrom
            routeTo = flight.routeTo
            landingsDay = flight.landingsDay
            landingsNightFullStop = flight.landingsNightFullStop
            isSolo = flight.isSolo
            isDualReceived = flight.isDualReceived
            isCrossCountry = flight.isCrossCountry
            isSimulatedInstrument = flight.isSimulatedInstrument
            remarks = flight.remarks
            cfiNumber = flight.cfiNumber
            signatureData = flight.instructorSignature
            if !remarks.isEmpty || !cfiNumber.isEmpty || signatureData != nil {
                showAdvanced = true
            }
        } else if let lastFlight = recentFlights.first {
            // A1: Smart defaults from most recent flight
            routeFrom = lastFlight.routeFrom
            routeTo = lastFlight.routeTo
            isSolo = lastFlight.isSolo
            isDualReceived = lastFlight.isDualReceived
            if !lastFlight.cfiNumber.isEmpty {
                cfiNumber = lastFlight.cfiNumber
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
                        .focused($focusedField, equals: .routeFrom)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .routeTo }
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
                        .focused($focusedField, equals: .routeTo)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .hobbs }
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
                    .focused($focusedField, equals: .hobbs)
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
                    .focused($focusedField, equals: .tach)
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
                .sensoryFeedback(.increase, trigger: landingsDay)
            Stepper("Night Full-Stop: \(landingsNightFullStop)", value: $landingsNightFullStop, in: 0...99)
                .sensoryFeedback(.increase, trigger: landingsNightFullStop)
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
                .sensoryFeedback(.selection, trigger: isSolo)

            Toggle("Dual Received", isOn: $isDualReceived)
                .onChange(of: isDualReceived) { _, newValue in
                    if newValue { isSolo = false }
                }
                .sensoryFeedback(.selection, trigger: isDualReceived)

            Toggle("Cross-Country (XC)", isOn: $isCrossCountry)
                .sensoryFeedback(.selection, trigger: isCrossCountry)
            Toggle("Simulated Instrument", isOn: $isSimulatedInstrument)
                .sensoryFeedback(.selection, trigger: isSimulatedInstrument)
        } header: {
            Text("Categories")
        }
    }

    // MARK: - Remarks (inside disclosure)

    private var remarksField: some View {
        Section {
            TextField("Flight notes...", text: $remarks, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .remarks)
        } header: {
            Text("Remarks")
        }
    }

    // MARK: - Signature (inside disclosure)

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

    // MARK: - Save (A2 haptics, A3 confirmation)

    private func saveFlight() {
        guard let hobbs = Double(durationHobbs), hobbs > 0 else {
            validationMessage = "Please enter a valid Hobbs time."
            showingValidationAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        let tach = Double(durationTach) ?? 0.0
        let shouldLockSignature = signatureData != nil && !cfiNumber.isEmpty

        if let flight = editingFlight {
            // B6: Update existing flight
            flight.date = date
            flight.durationHobbs = hobbs
            flight.durationTach = tach
            flight.routeFrom = routeFrom.trimmingCharacters(in: .whitespaces)
            flight.routeTo = routeTo.trimmingCharacters(in: .whitespaces)
            flight.landingsDay = landingsDay
            flight.landingsNightFullStop = landingsNightFullStop
            flight.isSolo = isSolo
            flight.isDualReceived = isDualReceived
            flight.isCrossCountry = isCrossCountry
            flight.isSimulatedInstrument = isSimulatedInstrument
            flight.remarks = remarks
            if shouldLockSignature {
                flight.lockSignature(
                    signatureData: signatureData!,
                    cfi: cfiNumber.trimmingCharacters(in: .whitespaces)
                )
            }
        } else {
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
        }

        // A2: Success haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

#Preview {
    AddFlightView()
        .modelContainer(for: FlightLog.self, inMemory: true)
}
