import SwiftUI
import SwiftData

struct AddFlightView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(OnboardingManager.self) private var onboarding

    // Smart defaults: read most recent flight for pre-population (A1)
    @Query(sort: \FlightLog.date, order: .reverse, animation: .none) private var recentFlights: [FlightLog]

    /// Optional flight to edit (B6). When nil, we create a new entry.
    var editingFlight: FlightLog?

    /// Callback fired only on successful save (A2: prevents false-positive toast).
    var onSave: (() -> Void)?

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
    @State private var landingsDay = 1   // A5: Default to 1 — every flight has at least one landing
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
    @State private var showDiscardAlert = false   // B1: Unsaved changes warning

    // A4: Route swap animation
    @State private var routeSwapRotation: Double = 0

    // FR-2: Hobbs start/end calculator
    @State private var useHobbsCalculator = false
    @State private var hobbsStart = ""
    @State private var hobbsEnd = ""

    // C-2 fix: Track initial defaults so isFormDirty compares against them, not hardcoded false
    @State private var initialIsSolo = false
    @State private var initialIsDualReceived = false
    @State private var initialRouteFrom = ""
    @State private var initialRouteTo = ""
    @State private var initialCfiNumber = ""

    var isEditing: Bool { editingFlight != nil }

    // B1: Track whether the form has been modified
    private var isFormDirty: Bool {
        if isEditing { return true } // Editing always counts as potentially dirty
        return !durationHobbs.isEmpty
            || !durationTach.isEmpty
            || !hobbsStart.isEmpty
            || !hobbsEnd.isEmpty
            || routeFrom != initialRouteFrom
            || routeTo != initialRouteTo
            || landingsDay != 1
            || landingsNightFullStop != 0
            || isSolo != initialIsSolo
            || isDualReceived != initialIsDualReceived
            || isCrossCountry
            || isSimulatedInstrument
            || !remarks.isEmpty
            || signatureData != nil
    }

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
                    Button("Cancel") {
                        // B1: Warn if form has unsaved data
                        if isFormDirty {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveFlight() }
                        .fontWeight(.semibold)
                }
                // A7: Next/Done keyboard toolbar for field advancement
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Previous") { advanceFocus(forward: false) }
                        .disabled(focusedField == .routeFrom)
                    Button("Next") { advanceFocus(forward: true) }
                        .disabled(focusedField == .cfiNumber || focusedField == .remarks)
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
            // B1: Discard changes confirmation
            .alert("Discard Flight?", isPresented: $showDiscardAlert) {
                Button("Keep Editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
            .onAppear {
                applyDefaults()
            }
            // B1: Swipe-to-dismiss interception
            .interactiveDismissDisabled(isFormDirty)
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
            // FR-5: Auto-focus the first required empty field
            focusedField = .hobbs
        } else {
            // Persona-based defaults for first-ever flight
            isSolo = onboarding.trainingStage.defaultIsSolo
            isDualReceived = onboarding.trainingStage.defaultIsDualReceived
            focusedField = .routeFrom
        }

        // C-2 fix: Snapshot initial state so isFormDirty compares against applied defaults
        initialIsSolo = isSolo
        initialIsDualReceived = isDualReceived
        initialRouteFrom = routeFrom
        initialRouteTo = routeTo
        initialCfiNumber = cfiNumber
    }

    // MARK: - A7: Keyboard Focus Advancement

    private func advanceFocus(forward: Bool) {
        let order: [Field] = [.routeFrom, .routeTo, .hobbs, .tach, .remarks, .cfiNumber]
        guard let current = focusedField,
              let index = order.firstIndex(of: current) else { return }

        let nextIndex = forward ? index + 1 : index - 1
        if order.indices.contains(nextIndex) {
            focusedField = order[nextIndex]
        }
    }

    // MARK: - FR-1: Recent Routes

    private var recentRoutes: [(id: String, from: String, to: String)] {
        var seen = Set<String>()
        var routes: [(id: String, from: String, to: String)] = []
        for flight in recentFlights {
            let key = "\(flight.routeFrom.uppercased())-\(flight.routeTo.uppercased())"
            guard !key.isEmpty, key != "-", !seen.contains(key) else { continue }
            seen.insert(key)
            routes.append((id: key, from: flight.routeFrom, to: flight.routeTo))
            if routes.count >= 5 { break }
        }
        return routes
    }

    // MARK: - Date & Route

    private var dateAndRouteSection: some View {
        Section {
            DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date) // A3: Prevent future dates

            // FR-1: Quick-pick recent routes
            if !isEditing && recentRoutes.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentRoutes, id: \.id) { route in
                            Button {
                                routeFrom = route.from
                                routeTo = route.to
                                focusedField = .hobbs
                                UISelectionFeedbackGenerator().selectionChanged()
                            } label: {
                                Text("\(route.from.uppercased()) → \(route.to.uppercased())")
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        routeFrom == route.from && routeTo == route.to
                                            ? Color.skyBlue.opacity(0.2)
                                            : Color.skyBlue.opacity(0.08)
                                    )
                                    .foregroundStyle(Color.skyBlue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            HStack {
                VStack(alignment: .leading) {
                    // FR-8: ICAO confidence indicator
                    HStack(spacing: 4) {
                        Text("From")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if routeFrom.trimmingCharacters(in: .whitespaces).count == 4 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.currencyGreen)
                        }
                    }
                    TextField("ICAO", text: $routeFrom)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .focused($focusedField, equals: .routeFrom)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .routeTo }
                }

                // A4: Tap to swap From/To route
                Button {
                    let temp = routeFrom
                    routeFrom = routeTo
                    routeTo = temp
                    withAnimation(.spring(duration: 0.3)) {
                        routeSwapRotation += 180
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                        .foregroundStyle(Color.skyBlue)
                        .padding(6)
                        .background(Color.skyBlue.opacity(0.1))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(routeSwapRotation))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Swap departure and arrival")

                VStack(alignment: .leading) {
                    // FR-8: ICAO confidence indicator
                    HStack(spacing: 4) {
                        Text("To")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if routeTo.trimmingCharacters(in: .whitespaces).count == 4 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.currencyGreen)
                        }
                    }
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

    // MARK: - Duration (FR-2: Optional start/end calculator)

    private var durationSection: some View {
        Section {
            if useHobbsCalculator {
                // FR-2: Start/End Hobbs entry with auto-calculation
                HStack {
                    Text("Hobbs Start")
                    Spacer()
                    TextField("0.0", text: $hobbsStart)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .focused($focusedField, equals: .hobbs)
                }

                HStack {
                    Text("Hobbs End")
                    Spacer()
                    TextField("0.0", text: $hobbsEnd)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .focused($focusedField, equals: .tach)
                }

                // Computed result
                if let start = Double(hobbsStart), let end = Double(hobbsEnd), end > start {
                    HStack {
                        Text("Duration")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.1f hrs", end - start))
                            .foregroundStyle(Color.skyBlue)
                            .fontWeight(.semibold)
                            .contentTransition(.numericText())
                    }
                }
            } else {
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
            HStack {
                Text("Duration")
                Spacer()
                // FR-2: Toggle between direct entry and calculator
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        useHobbsCalculator.toggle()
                    }
                    if !useHobbsCalculator {
                        // Sync calculated value back to durationHobbs
                        if let start = Double(hobbsStart), let end = Double(hobbsEnd), end > start {
                            durationHobbs = String(format: "%.1f", end - start)
                        }
                    }
                } label: {
                    Text(useHobbsCalculator ? "Direct Entry" : "Calculator")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Color.skyBlue)
                }
            }
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

    // MARK: - Save (A2 haptics, A3 validation)

    private func saveFlight() {
        // FR-2: Sync calculator value before validation
        if useHobbsCalculator {
            if let start = Double(hobbsStart), let end = Double(hobbsEnd), end > start {
                durationHobbs = String(format: "%.1f", end - start)
            }
        }

        // A3: Validate Hobbs
        guard let hobbs = Double(durationHobbs), hobbs > 0 else {
            validationMessage = "Please enter a valid Hobbs time."
            showingValidationAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        // A3: Warn on unusually long flights
        if hobbs > 12 {
            validationMessage = "Hobbs time exceeds 12 hours. Please verify this is correct."
            showingValidationAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        // A3: Ensure at least one landing for any flight
        if landingsDay == 0 && landingsNightFullStop == 0 {
            validationMessage = "Every flight needs at least one landing. Please add your landing count."
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

        // A2: Success haptic + callback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSave?()
        dismiss()
    }
}

#Preview {
    AddFlightView()
        .modelContainer(for: FlightLog.self, inMemory: true)
        .environment(OnboardingManager())
}
