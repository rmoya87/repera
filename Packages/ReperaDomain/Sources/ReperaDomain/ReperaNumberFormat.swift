import Foundation

/// Formato visible único para iPhone y Apple Watch: 1.234,56.
/// Es independiente del idioma configurado en el dispositivo y no se utiliza
/// para serializar datos (JSON, Supabase, HealthKit, etc.).
public enum ReperaNumberFormat {
    /// Muestra solo los decimales necesarios (máximo dos) y agrupa desde 1.000.
    public static func decimal(
        _ value: Double,
        maximumFractionDigits: Int = 2,
        minimumFractionDigits: Int = 0
    ) -> String {
        guard value.isFinite else { return "—" }
        let formatter = makeFormatter(
            minimumFractionDigits: minimumFractionDigits,
            maximumFractionDigits: maximumFractionDigits
        )
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    public static func integer(_ value: Int) -> String {
        makeFormatter(minimumFractionDigits: 0, maximumFractionDigits: 0)
            .string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Admite entradas españolas (1.234,56), decimales heredados (1234.56)
    /// y cadenas sin separador. El punto seguido por grupos de tres dígitos
    /// se interpreta como separador de millares solo si no hay coma.
    public static func parse(_ input: String) -> Double? {
        let compact = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
        guard !compact.isEmpty else { return nil }
        let normalized: String
        if compact.contains(",") {
            normalized = compact.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        } else if compact.range(
            of: #"^[+-]?[0-9]{1,3}(\.[0-9]{3})+$"#,
            options: .regularExpression
        ) != nil {
            normalized = compact.replacingOccurrences(of: ".", with: "")
        } else {
            normalized = compact
        }
        guard let result = Double(normalized), result.isFinite else { return nil }
        return result
    }

    private static func makeFormatter(
        minimumFractionDigits: Int,
        maximumFractionDigits: Int
    ) -> NumberFormatter {
        let maximum = min(2, max(0, maximumFractionDigits))
        let formatter = NumberFormatter()
        // es_ES de CLDR omite a veces el separador en números de cuatro cifras.
        // en_US con separadores explícitos garantiza «1.234» desde el primer millar.
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.secondaryGroupingSize = 3
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = min(maximum, max(0, minimumFractionDigits))
        formatter.maximumFractionDigits = maximum
        return formatter
    }
}
