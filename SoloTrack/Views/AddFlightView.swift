import SwiftUI
import SwiftData

struct AddFlightView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(OnboardingManager.self) private var onboarding

    // Smart defaults: read most recent flight for pre-population (A1)
    @Query(sort: \FlightLog.date, order: .reverse, animation: .none) private var recentFlights: [FlightLog]
    @Query(sort: \FlightTemplate.createdAt, order: .reverse) private var templates: [FlightTemplate]

    /// Optional flight to edit (B6). When nil, we create a new entry.
    var editingFlight: FlightLog?

    /// C3: Optional recommendation from the dashboard nudge card
    var defaultRecommendation: FlightRecommendation?

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
    @State private var showAdvanced = false
    @State private var hasAppliedDefaults = false
    @State private var showDiscardAlert = false   // B1: Unsaved changes warning

    // A4: Route swap animation
    @State private var routeSwapRotation: Double = 0

    // FR-9: Flight templates
    @State private var showSaveTemplateSheet = false
    @State private var templateName = ""

    // FR-2: Hobbs start/end calculator
    @State private var useHobbsCalculator = false
    @State private var hobbsStart = ""
    @State private var hobbsEnd = ""

    // Quick-Entry mode: keep form open after save for rapid backfill
    @State private var quickEntryMode = false
    @State private var quickEntrySaved = false
    @State private var quickEntryCount = 0
    @State private var quickEntryTotalHobbs: Double = 0

    // C-2 fix: Track initial defaults so isFormDirty compares against them, not hardcoded false
    @State private var initialIsSolo = false
    @State private var initialIsDualReceived = false
    @State private var initialRouteFrom = ""
    @State private var initialRouteTo = ""
    @State private var initialCfiNumber = ""

    // C2: Save custom airport
    @State private var showSaveAirportAlert = false
    @State private var saveAirportCode = ""
    @State private var saveAirportName = ""

    var isEditing: Bool { editingFlight != nil }

    // MARK: - Inline Validation

    /// Parsed Hobbs value (nil if empty or unparseable)
    private var parsedHobbs: Double? {
        if useHobbsCalculator {
            guard let start = Double(hobbsStart), let end = Double(hobbsEnd), end > start else { return nil }
            return end - start
        }
        return Double(durationHobbs)
    }

    /// True when the Hobbs field has user input that doesn't parse to a valid number
    private var hobbsHasError: Bool {
        let input = useHobbsCalculator ? hobbsStart : durationHobbs
        guard !input.isEmpty else { return false }
        return parsedHobbs == nil || parsedHobbs == 0
    }

    /// True when user has zeroed out both landing fields
    private var landingsHaveError: Bool {
        landingsDay == 0 && landingsNightFullStop == 0
    }

    /// Inline warning message for Hobbs field (nil when valid)
    private var hobbsWarningMessage: String? {
        if hobbsHasError {
            return "Enter a valid Hobbs time"
        }
        if let hobbs = parsedHobbs, hobbs > 12 {
            return "Hobbs exceeds 12 hours — verify before saving"
        }
        return nil
    }

    /// True when Hobbs is valid but unusually high (soft warning, not a save blocker)
    private var hobbsHasSoftWarning: Bool {
        guard let hobbs = parsedHobbs else { return false }
        return hobbs > 12
    }

    /// Core save requirements met (inline — excludes soft warnings like >12h)
    private var saveEnabled: Bool {
        guard let hobbs = parsedHobbs, hobbs > 0 else { return false }
        return !landingsHaveError
    }

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
                DisclosureGroup(isExpanded: $showAdvanced) {
                    remarksField
                    signatureSection
                } label: {
                    HStack {
                        Text("More Details")
                        if !showAdvanced && (!remarks.isEmpty || signatureData != nil || !cfiNumber.isEmpty) {
                            Circle()
                                .fill(Color.skyBlue)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .tint(Color.skyBlue)
            }
            .navigationTitle(isEditing ? "Edit Flight" : (quickEntryMode ? "Quick Entry" : "Log Flight"))
            .navigationBarTitleDisplayMode(.inline)
            // Quick-Entry inline success toast
            .overlay(alignment: .top) {
                if quickEntrySaved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.currencyGreen)
                        Text(quickEntryCount >= 2 ? "Saved! (\(String(format: "%.1f", quickEntryTotalHobbs))h total)" : "Saved!")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                        Text("(\(quickEntryCount))")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.skyBlue)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.currencyGreen.opacity(AppTokens.Opacity.light))
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .motionAwareAnimation(.spring(duration: 0.3), value: quickEntrySaved)
            .task(id: quickEntrySaved) {
                guard quickEntrySaved else { return }
                try? await Task.sleep(for: .seconds(1.5))
                withMotionAwareAnimation(.easeOut(duration: 0.3)) { quickEntrySaved = false }
            }
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
                    HStack(spacing: 12) {
                        // Quick-Entry toggle (only for new flights)
                        if !isEditing {
                            Button {
                                quickEntryMode.toggle()
                                HapticService.selectionChanged()
                            } label: {
                                Image(systemName: quickEntryMode ? "bolt.fill" : "bolt")
                                    .font(.caption)
                                    .foregroundStyle(quickEntryMode ? Color.skyBlue : .secondary)
                            }
                            .accessibilityLabel(quickEntryMode ? "Quick entry on" : "Quick entry off")
                        }
                        Button("Save") { saveFlight() }
                            .fontWeight(.semibold)
                            .disabled(!saveEnabled)
                            .keyboardShortcut("s", modifiers: .command)
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showSaveTemplateSheet = true
                    } label: {
                        Label("Save as Template", systemImage: "bookmark.fill")
                    }
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
            // B1: Discard changes confirmation
            .alert("Unsaved Flight", isPresented: $showDiscardAlert) {
                Button("Keep Editing", role: .cancel) {}
                if saveEnabled {
                    Button("Save & Close") { saveFlight() }
                }
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
            // C2: Save custom airport alert
            .alert("Save Airport", isPresented: $showSaveAirportAlert) {
                TextField("Airport name", text: $saveAirportName)
                Button("Save") {
                    ICAODatabase.addCustomAirport(
                        code: saveAirportCode,
                        name: saveAirportName.isEmpty ? "Custom" : saveAirportName
                    )
                    HapticService.saveConfirmation()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Save \(saveAirportCode) to your custom airports list?")
            }
            .onAppear {
                applyDefaults()
            }
            // FR-9: Save as template sheet
            .sheet(isPresented: $showSaveTemplateSheet) {
                NavigationStack {
                    Form {
                        TextField("Template Name", text: $templateName)
                        Section("Configuration") {
                            LabeledContent("Route", value: "\(routeFrom) → \(routeTo)")
                            if let hobbs = Double(durationHobbs), hobbs > 0 {
                                LabeledContent("Typical Hobbs", value: String(format: "%.1f", hobbs))
                            }
                            LabeledContent("Categories", value: [
                                isSolo ? "Solo" : nil,
                                isDualReceived ? "Dual" : nil,
                                isCrossCountry ? "XC" : nil,
                                isSimulatedInstrument ? "Sim Inst" : nil
                            ].compactMap { $0 }.joined(separator: ", "))
                        }
                    }
                    .navigationTitle("Save Template")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showSaveTemplateSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let template = FlightTemplate(
                                    name: templateName.isEmpty ? "\(routeFrom)→\(routeTo)" : templateName,
                                    routeFrom: routeFrom,
                                    routeTo: routeTo,
                                    typicalHobbs: Double(durationHobbs) ?? 0,
                                    isSolo: isSolo,
                                    isDualReceived: isDualReceived,
                                    isCrossCountry: isCrossCountry,
                                    isSimulatedInstrument: isSimulatedInstrument,
                                    defaultLandingsDay: landingsDay,
                                    remarks: remarks,
                                    cfiNumber: cfiNumber
                                )
                                modelContext.insert(template)
                                templateName = ""
                                showSaveTemplateSheet = false
                                HapticService.saveConfirmation()
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
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
            // FR-R6: Auto-swap routes for XC return legs within 24 hours
            if lastFlight.isCrossCountry && lastFlight.routeFrom != lastFlight.routeTo {
                let hoursSinceLast = Date.now.timeIntervalSince(lastFlight.date) / 3600
                if hoursSinceLast < 24 {
                    routeFrom = lastFlight.routeTo
                    routeTo = lastFlight.routeFrom
                }
            }
            isSolo = lastFlight.isSolo
            isDualReceived = lastFlight.isDualReceived
            if !lastFlight.cfiNumber.isEmpty {
                cfiNumber = lastFlight.cfiNumber
            }
            // C1: Auto-focus the first truly empty required field
            focusedField = firstEmptyRequiredField()
        } else {
            // Persona-based defaults for first-ever flight
            isSolo = onboarding.trainingStage.defaultIsSolo
            isDualReceived = onboarding.trainingStage.defaultIsDualReceived
            focusedField = .routeFrom
        }

        // C3: Apply recommendation from dashboard nudge (overrides category defaults)
        if !isEditing, let rec = defaultRecommendation {
            if rec.suggestedHobbs > 0 {
                durationHobbs = String(format: "%.1f", rec.suggestedHobbs)
            }
            isSolo = rec.isSolo
            isDualReceived = rec.isDual
            isCrossCountry = rec.isXC
            isSimulatedInstrument = rec.isInstrument
            if rec.isNight { landingsNightFullStop = max(landingsNightFullStop, 1) }
            focusedField = firstEmptyRequiredField()
        }

        // C-2 fix: Snapshot initial state so isFormDirty compares against applied defaults
        initialIsSolo = isSolo
        initialIsDualReceived = isDualReceived
        initialRouteFrom = routeFrom
        initialRouteTo = routeTo
        initialCfiNumber = cfiNumber
    }

    // MARK: - FR-9: Apply Template

    private func applyTemplate(_ template: FlightTemplate) {
        routeFrom = template.routeFrom
        routeTo = template.routeTo
        if template.typicalHobbs > 0 {
            durationHobbs = String(format: "%.1f", template.typicalHobbs)
        }
        isSolo = template.isSolo
        isDualReceived = template.isDualReceived
        isCrossCountry = template.isCrossCountry
        isSimulatedInstrument = template.isSimulatedInstrument
        landingsDay = template.defaultLandingsDay
        if !template.remarks.isEmpty {
            remarks = template.remarks
        }
        if !template.cfiNumber.isEmpty {
            cfiNumber = template.cfiNumber
        }
        // Auto-expand "More Details" if template has remarks or CFI data
        if !template.remarks.isEmpty || !template.cfiNumber.isEmpty {
            showAdvanced = true
        }
        // Update initial values so isFormDirty works correctly
        initialRouteFrom = template.routeFrom
        initialRouteTo = template.routeTo
        initialIsSolo = template.isSolo
        initialIsDualReceived = template.isDualReceived
        // C1: Skip past fields the template already filled
        focusedField = firstEmptyRequiredField()
        HapticService.lightImpact()
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

    // MARK: - C1: Smart Focus Skipping

    /// Returns the first empty required field so focus skips past pre-filled values.
    private func firstEmptyRequiredField() -> Field {
        if routeFrom.trimmingCharacters(in: .whitespaces).isEmpty { return .routeFrom }
        if routeTo.trimmingCharacters(in: .whitespaces).isEmpty { return .routeTo }
        if useHobbsCalculator {
            if hobbsStart.isEmpty { return .hobbs }
        } else {
            if durationHobbs.isEmpty { return .hobbs }
        }
        return .hobbs
    }

    // MARK: - FR-R2: ICAO Auto-Completion

    private func icaoSuggestions(for query: String, field: Field) -> [(code: String, name: String)] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count < 4 else { return [] }

        // Prioritize airports from recent routes
        let recentCodes = Set(recentFlights.prefix(10).flatMap { [$0.routeFrom.uppercased(), $0.routeTo.uppercased()] })
        let dbSuggestions = ICAODatabase.suggestions(for: trimmed)

        let sorted = dbSuggestions.sorted { a, b in
            let aRecent = recentCodes.contains(a.code)
            let bRecent = recentCodes.contains(b.code)
            if aRecent != bRecent { return aRecent }
            return a.code < b.code
        }
        return Array(sorted.prefix(8))
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

            // FR-9: Template quick-pick pills
            if !isEditing && !templates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTokens.Spacing.sm) {
                        ForEach(templates) { template in
                            Button {
                                applyTemplate(template)
                            } label: {
                                Label(template.name, systemImage: "bookmark.fill")
                                    .font(.caption)
                                    .padding(.horizontal, AppTokens.Spacing.md)
                                    .padding(.vertical, AppTokens.Spacing.xs)
                                    .background(Color.skyBlue.opacity(0.12))
                                    .foregroundStyle(Color.skyBlue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(template)
                                } label: {
                                    Label("Delete Template", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            // FR-1: Quick-pick recent routes
            if !isEditing && recentRoutes.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentRoutes, id: \.id) { route in
                            Button {
                                routeFrom = route.from
                                routeTo = route.to
                                focusedField = .hobbs
                                HapticService.selectionChanged()
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
                                    .scaleEffect(routeFrom == route.from && routeTo == route.to ? 0.97 : 1.0)
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
                                .foregroundStyle(ICAODatabase.isKnown(routeFrom) ? Color.currencyGreen : Color.cautionYellow)
                        }
                    }
                    if routeFrom.trimmingCharacters(in: .whitespaces).count == 4 && !ICAODatabase.isKnown(routeFrom) {
                        Button {
                            saveAirportCode = routeFrom.uppercased()
                            saveAirportName = ""
                            showSaveAirportAlert = true
                        } label: {
                            Label("Save to My Airports", systemImage: "plus.circle")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(Color.cautionYellow)
                        }
                        .buttonStyle(.plain)
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
                    withMotionAwareAnimation(.spring(duration: 0.3)) {
                        routeSwapRotation += 180
                    }
                    HapticService.selectionChanged()
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
                                .foregroundStyle(ICAODatabase.isKnown(routeTo) ? Color.currencyGreen : Color.cautionYellow)
                        }
                    }
                    if routeTo.trimmingCharacters(in: .whitespaces).count == 4 && !ICAODatabase.isKnown(routeTo) {
                        Button {
                            saveAirportCode = routeTo.uppercased()
                            saveAirportName = ""
                            showSaveAirportAlert = true
                        } label: {
                            Label("Save to My Airports", systemImage: "plus.circle")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(Color.cautionYellow)
                        }
                        .buttonStyle(.plain)
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

            // FR-R2: ICAO auto-completion suggestions
            if let activeField = focusedField,
               (activeField == .routeFrom || activeField == .routeTo) {
                let query = activeField == .routeFrom ? routeFrom : routeTo
                let suggestions = icaoSuggestions(for: query, field: activeField)
                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(suggestions, id: \.code) { suggestion in
                                Button {
                                    if activeField == .routeFrom {
                                        routeFrom = suggestion.code
                                        focusedField = .routeTo
                                    } else {
                                        routeTo = suggestion.code
                                        focusedField = .hobbs
                                    }
                                    HapticService.selectionChanged()
                                } label: {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(suggestion.code)
                                            .font(.system(.caption, design: .monospaced, weight: .bold))
                                        Text(suggestion.name)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.skyBlue.opacity(AppTokens.Opacity.subtle))
                                    .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.sm))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        } header: {
            Text("Route")
        }
        .motionAwareAnimation(.spring(duration: AppTokens.Duration.quick), value: focusedField)
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
                        .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
                        .focused($focusedField, equals: .hobbs)
                }

                HStack {
                    Text("Hobbs End")
                    Spacer()
                    TextField("0.0", text: $hobbsEnd)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
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
                    .transition(.opacity)
                }
            } else {
                HStack {
                    Text("Hobbs")
                        .foregroundStyle(hobbsHasError ? Color.warningRed : .primary)
                    Spacer()
                    TextField("0.0", text: $durationHobbs)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
                        .focused($focusedField, equals: .hobbs)
                    Text("hrs")
                        .foregroundStyle(hobbsHasError ? Color.warningRed.opacity(0.6) : .secondary)
                }
            }

            if let warning = hobbsWarningMessage {
                Text(warning)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(hobbsHasError ? Color.warningRed : Color.cautionYellow)
                    .transition(.opacity)
            }

            HStack {
                Text("Tach")
                // Quick copy from Hobbs when Tach differs
                if !durationHobbs.isEmpty && durationTach != durationHobbs {
                    Button {
                        durationTach = durationHobbs
                        HapticService.selectionChanged()
                    } label: {
                        Text("= Hobbs")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(Color.skyBlue)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                TextField("0.0", text: $durationTach)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
                    .focused($focusedField, equals: .tach)
                Text("hrs")
                    .foregroundStyle(.secondary)
            }
            // Auto-fill Tach from Hobbs when Tach is empty
            .onChange(of: durationHobbs) { _, newValue in
                if durationTach.isEmpty && !newValue.isEmpty && !useHobbsCalculator {
                    durationTach = newValue
                }
            }
        } header: {
            HStack {
                Text("Duration")
                Spacer()
                // FR-2: Toggle between direct entry and calculator
                Button {
                    withMotionAwareAnimation(.smooth(duration: 0.3)) {
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
            landingRow(label: "Day Landings", value: $landingsDay)
                .sensoryFeedback(.increase, trigger: landingsDay)
            landingRow(label: "Night Full-Stop", value: $landingsNightFullStop)
                .sensoryFeedback(.increase, trigger: landingsNightFullStop)

            if landingsHaveError {
                Text("Every flight needs at least one landing")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.warningRed)
                    .transition(.opacity)
            }
        } header: {
            Text("Landings")
        }
        .motionAwareAnimation(.spring(duration: AppTokens.Duration.quick), value: landingsHaveError)
    }

    // MARK: - Landing Row (editable numeric input with +/- buttons)

    private func landingRow(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Button {
                if value.wrappedValue > 0 { value.wrappedValue -= 1 }
                HapticService.selectionChanged()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(value.wrappedValue > 0 ? Color.skyBlue : Color.gray.opacity(AppTokens.Opacity.medium))
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue <= 0)

            Text("\(value.wrappedValue)")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .frame(minWidth: 32)
                .multilineTextAlignment(.center)

            Button {
                if value.wrappedValue < 99 { value.wrappedValue += 1 }
                HapticService.selectionChanged()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.skyBlue)
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue >= 99)
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

        // Validate — inline errors are already visible
        guard let hobbs = Double(durationHobbs), hobbs > 0 else {
            HapticService.error()
            return
        }

        if landingsDay == 0 && landingsNightFullStop == 0 {
            HapticService.error()
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
            if let signature = signatureData, !cfiNumber.isEmpty {
                flight.lockSignature(
                    signatureData: signature,
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
        HapticService.saveConfirmation()
        onSave?()

        if quickEntryMode && !isEditing {
            // Quick-Entry: reset for next flight, keep route + categories
            quickEntryCount += 1
            quickEntryTotalHobbs += Double(durationHobbs) ?? 0
            withMotionAwareAnimation(.spring(duration: 0.3)) {
                quickEntrySaved = true
            }
            // Advance date by 1 day, clear durations & remarks
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) {
                date = nextDay
            }
            if useHobbsCalculator && !hobbsEnd.isEmpty {
                hobbsStart = hobbsEnd
                hobbsEnd = ""
            } else {
                durationHobbs = ""
            }
            durationTach = ""
            landingsDay = 1
            landingsNightFullStop = 0
            remarks = ""
            signatureData = nil
            // Keep: routeFrom, routeTo, isSolo, isDualReceived, isCrossCountry, isSimulatedInstrument, cfiNumber
            focusedField = .hobbs
        } else {
            dismiss()
        }
    }
}

#Preview {
    AddFlightView()
        .modelContainer(for: [FlightLog.self, FlightTemplate.self], inMemory: true)
        .environment(OnboardingManager())
}
