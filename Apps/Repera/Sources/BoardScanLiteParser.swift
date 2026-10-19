import ReperaDomain

/// Puente de compatibilidad con el nombre usado en el pipeline iOS.
/// El parser ligero real vive en ReperaDomain para compartir exactamente
/// las mismas reglas con las pruebas de regresión Swift.
typealias BoardScanLiteParser = ReperaDomain.BoardScanLiteParser
