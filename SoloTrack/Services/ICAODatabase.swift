import Foundation

// MARK: - FR-R2: ICAO Airport Database

/// Provides auto-completion suggestions for ICAO airport codes.
/// Contains common US airports used in general aviation training.
enum ICAODatabase {
    /// Dictionary of ICAO code to airport name
    static let airports: [String: String] = [
        // California
        "KSJC": "San Jose Intl",
        "KRHV": "Reid-Hillview",
        "KPAO": "Palo Alto",
        "KSQL": "San Carlos",
        "KHWD": "Hayward Executive",
        "KOAK": "Oakland Intl",
        "KSFO": "San Francisco Intl",
        "KLVK": "Livermore Muni",
        "KCCR": "Buchanan Field",
        "KNUQ": "Moffett Federal",
        "KWVI": "Watsonville Muni",
        "KMOD": "Modesto City-County",
        "KMER": "Castle",
        "KSCK": "Stockton Metro",
        "KSNS": "Salinas Muni",
        "KMRY": "Monterey Regional",
        "KSBP": "San Luis Obispo",
        "KSBA": "Santa Barbara Muni",
        "KVNY": "Van Nuys",
        "KSMO": "Santa Monica Muni",
        "KTOA": "Torrance Zamperini",
        "KLGB": "Long Beach",
        "KLAX": "Los Angeles Intl",
        "KBUR": "Hollywood Burbank",
        "KONT": "Ontario Intl",
        "KSAN": "San Diego Intl",
        "KSEE": "Gillespie Field",
        "KCRQ": "McClellan-Palomar",
        "KFUL": "Fullerton Muni",
        "KCNO": "Chino",
        "KEMT": "El Monte",
        "KWHP": "Whiteman",
        "KRNM": "Ramona",
        "KSDM": "Brown Field",
        "KSAC": "Sacramento Executive",
        "KSMF": "Sacramento Intl",
        "KMCC": "McClellan-Palomar",
        "KFAT": "Fresno Yosemite",
        "KBFL": "Meadows Field",

        // Arizona
        "KPHX": "Phoenix Sky Harbor",
        "KDVT": "Deer Valley",
        "KSDL": "Scottsdale",
        "KCHD": "Chandler Muni",
        "KFFZ": "Falcon Field",
        "KIWA": "Phoenix-Mesa Gateway",
        "KTUS": "Tucson Intl",
        "KGEU": "Glendale Muni",
        "KPRC": "Prescott Muni",

        // Florida
        "KMIA": "Miami Intl",
        "KFLL": "Fort Lauderdale-Hollywood",
        "KTMB": "Kendall-Tamiami Executive",
        "KOPF": "Miami-Opa Locka Executive",
        "KHWO": "North Perry",
        "KFXE": "Fort Lauderdale Executive",
        "KPMP": "Pompano Beach Airpark",
        "KBCT": "Boca Raton",
        "KPBI": "Palm Beach Intl",
        "KSUA": "Witham Field",
        "KORL": "Orlando Executive",
        "KMCO": "Orlando Intl",
        "KSFB": "Orlando Sanford",
        "KDAB": "Daytona Beach Intl",
        "KTPA": "Tampa Intl",
        "KPIE": "St. Pete-Clearwater",
        "KSRQ": "Sarasota-Bradenton",
        "KJAX": "Jacksonville Intl",
        "KPNS": "Pensacola Intl",
        "KVDF": "Tampa Executive",
        "KLAL": "Lakeland Linder",

        // Texas
        "KDFW": "Dallas/Fort Worth Intl",
        "KDAL": "Dallas Love Field",
        "KADS": "Addison",
        "KGPM": "Grand Prairie Muni",
        "KRBD": "Dallas Executive",
        "KIAH": "George Bush Intercontinental",
        "KHOU": "William P Hobby",
        "KAUS": "Austin-Bergstrom",
        "KSAT": "San Antonio Intl",
        "KELP": "El Paso Intl",
        "KSGR": "Sugar Land Regional",
        "KDWH": "David Wayne Hooks",
        "KEFD": "Ellington Field",
        "KGTU": "Georgetown Muni",

        // Northeast
        "KJFK": "John F Kennedy Intl",
        "KLGA": "LaGuardia",
        "KEWR": "Newark Liberty",
        "KTEB": "Teterboro",
        "KHPN": "Westchester County",
        "KFRG": "Republic",
        "KISP": "Long Island MacArthur",
        "KCDW": "Essex County",
        "KMMU": "Morristown Muni",
        "KBOS": "Boston Logan",
        "KBED": "Laurence G Hanscom",
        "KBVY": "Beverly Muni",
        "KOWD": "Norwood Memorial",
        "KPHL": "Philadelphia Intl",
        "KPNE": "Northeast Philadelphia",
        "KDCA": "Ronald Reagan National",
        "KIAD": "Dulles Intl",
        "KBWI": "Baltimore/Washington Intl",
        "KGAI": "Montgomery County",
        "KHEF": "Manassas Regional",

        // Southeast
        "KATL": "Hartsfield-Jackson Atlanta",
        "KPDK": "DeKalb-Peachtree",
        "KRYY": "Cobb County-McCollum",
        "KFTY": "Fulton County-Brown Field",
        "KCLT": "Charlotte Douglas",
        "KRDU": "Raleigh-Durham Intl",
        "KBNA": "Nashville Intl",
        "KMEM": "Memphis Intl",
        "KJQF": "Concord-Padgett Regional",

        // Midwest
        "KORD": "O'Hare Intl",
        "KMDW": "Chicago Midway",
        "KDPA": "DuPage",
        "KPWK": "Chicago Executive",
        "KARR": "Aurora Muni",
        "KDTW": "Detroit Metro Wayne County",
        "KPTK": "Oakland County",
        "KYIP": "Willow Run",
        "KMSP": "Minneapolis-St Paul",
        "KFCM": "Flying Cloud",
        "KANP": "Lee",
        "KSTL": "St. Louis Lambert",
        "KMCI": "Kansas City Intl",
        "KCVG": "Cincinnati/Northern Kentucky",
        "KCMH": "John Glenn Columbus",
        "KIND": "Indianapolis Intl",
        "KEYE": "Eagle Creek Airpark",
        "KMKE": "General Mitchell",

        // Mountain/West
        "KDEN": "Denver Intl",
        "KAPA": "Centennial",
        "KBJC": "Rocky Mountain Metro",
        "KFTG": "Front Range",
        "KSLC": "Salt Lake City Intl",
        "KLAS": "Harry Reid Intl",
        "KVGT": "North Las Vegas",
        "KHND": "Henderson Executive",
        "KBOI": "Boise Air Terminal",
        "KGEG": "Spokane Intl",

        // Pacific Northwest
        "KSEA": "Seattle-Tacoma",
        "KBFI": "Boeing Field/King County",
        "KPAE": "Snohomish County",
        "KRNT": "Renton Muni",
        "KOLM": "Olympia Regional",
        "KPDX": "Portland Intl",
        "KHIO": "Portland-Hillsboro",
        "KTTD": "Portland-Troutdale",

        // Hawaii
        "PHNL": "Daniel K Inouye Intl",
        "PHOG": "Kahului",
        "PHKO": "Ellison Onizuka Kona",
        "PHLI": "Lihue",

        // Alaska
        "PANC": "Ted Stevens Anchorage",
        "PAFA": "Fairbanks Intl",
        "PAJN": "Juneau Intl",
    ]

    /// Returns airports matching the given prefix, sorted by code
    static func suggestions(for prefix: String) -> [(code: String, name: String)] {
        guard !prefix.isEmpty else { return [] }
        let upper = prefix.uppercased()
        return airports
            .filter { $0.key.hasPrefix(upper) }
            .map { (code: $0.key, name: $0.value) }
            .sorted { $0.code < $1.code }
    }

    /// Returns true if the code is a known airport
    static func isKnown(_ code: String) -> Bool {
        airports[code.uppercased()] != nil
    }
}
