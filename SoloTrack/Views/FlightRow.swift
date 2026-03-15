import SwiftUI

// MARK: - Flight Row

struct FlightRow: View {
    let flight: FlightLog

    private var primaryCategoryColor: Color {
        if let firstTag = flight.categoryTags.first {
            switch firstTag {
            case "Solo": return .skyBlue
            case "Dual": return .badgeDual
            case "XC": return .badgeXC
            case "Inst": return .badgeInst
            default: return .skyBlue
            }
        }
        return .skyBlue
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(flight.date)
    }

    private var isOutsideCurrencyWindow: Bool {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now) else { return false }
        return flight.date < cutoff
    }

    var body: some View {
        HStack(spacing: 0) {
            // DL-4: Category color indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(primaryCategoryColor)
                .frame(width: 3)
                .padding(.vertical, 2)

            HStack(spacing: 12) {
                // Date circle
                VStack(spacing: 2) {
                    Text(flight.date, format: .dateTime.day())
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text(flight.date, format: .dateTime.month(.abbreviated))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(width: AppTokens.Size.dateCircle)
                // DL-4: Today highlight
                .background(
                    isToday ? Color.skyBlue.opacity(AppTokens.Opacity.subtle) : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTokens.Radius.sm))
                .overlay(alignment: .top) {
                    if isToday {
                        Text("Today")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.skyBlue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.skyBlue.opacity(AppTokens.Opacity.light))
                            .clipShape(Capsule())
                            .offset(y: -8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.formattedRoute)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))

                    HStack(spacing: 6) {
                        ForEach(flight.categoryTags, id: \.self) { tag in
                            CategoryBadge(tag: tag)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(flight.formattedDuration)h")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))

                    HStack(spacing: 4) {
                        if flight.hasValidSignature {
                            Image(systemName: "signature")
                                .font(.caption)
                                .foregroundStyle(Color.currencyGreen)
                                .accessibilityLabel("Has instructor signature")
                        }
                        if flight.isSignatureLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Signature locked")
                        }
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
        // DL-4: Subtle de-emphasis for old flights
        .opacity(isOutsideCurrencyWindow ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(flight.formattedRoute), \(flight.formattedDuration) hours, \(flight.date.formatted(date: .abbreviated, time: .omitted))")
    }
}

// MARK: - D4: Shared Category Badge

struct CategoryBadge: View {
    let tag: String

    private var badgeColor: Color {
        switch tag {
        case "Solo": return .skyBlue
        case "Dual": return .badgeDual
        case "XC": return .badgeXC
        case "Inst": return .badgeInst
        default: return .skyBlue
        }
    }

    var body: some View {
        Text(tag)
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(AppTokens.Opacity.light))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
            .accessibilityLabel(tag)
    }
}
