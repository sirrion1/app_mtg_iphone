import SwiftUI

/// Equivalente a `Color.kt` + `Theme.kt`. Paleta inspirada en el
/// dorado/negro de una carta de Magic, en vez de los azules de plantilla.
///
/// SwiftUI adapta automáticamente los "Color(light:dark:)" al modo claro/
/// oscuro del sistema, así que no hace falta un ColorScheme completo como
/// en Compose: basta con definir cada color semántico una vez.
enum MtgTheme {
    static let dorado = Color(
        light: Color(red: 0x8A/255, green: 0x6D/255, blue: 0x1D/255),
        dark: Color(red: 0xD4/255, green: 0xAF/255, blue: 0x37/255)
    )
    static let doradoVariante = Color(
        light: Color(red: 0x6E/255, green: 0x57/255, blue: 0x16/255),
        dark: Color(red: 0xB8/255, green: 0x91/255, blue: 0x2C/255)
    )
    static let carmesi = Color(
        light: Color(red: 0x8C/255, green: 0x2E/255, blue: 0x23/255),
        dark: Color(red: 0xB0/255, green: 0x3A/255, blue: 0x2E/255)
    )
    static let fondo = Color(
        light: Color(red: 0xFF/255, green: 0xFB/255, blue: 0xF3/255),
        dark: Color(red: 0x0F/255, green: 0x0D/255, blue: 0x0B/255)
    )
    static let superficie = Color(
        light: Color(red: 0xFB/255, green: 0xF6/255, blue: 0xEC/255),
        dark: Color(red: 0x16/255, green: 0x13/255, blue: 0x11/255)
    )
    static let superficieVariante = Color(
        light: Color(red: 0xF0/255, green: 0xE8/255, blue: 0xD6/255),
        dark: Color(red: 0x21/255, green: 0x1D/255, blue: 0x19/255)
    )
    static let texto = Color(
        light: Color(red: 0x21/255, green: 0x1D/255, blue: 0x19/255),
        dark: Color(red: 0xF2/255, green: 0xEC/255, blue: 0xE4/255)
    )
    static let textoApagado = Color(
        light: Color(red: 0x5C/255, green: 0x53/255, blue: 0x47/255),
        dark: Color(red: 0xC9/255, green: 0xBF/255, blue: 0xB2/255)
    )

    // Colores semánticos compartidos (iguales en claro y oscuro).
    static let estadoOk = Color(red: 0x2E/255, green: 0x7D/255, blue: 0x32/255)
    static let estadoError = Color(red: 0xC6/255, green: 0x28/255, blue: 0x28/255)
    static let estadoFoil = Color(red: 0x8E/255, green: 0x6F/255, blue: 0xCE/255)
}

private extension Color {
    /// Crea un Color que cambia automáticamente entre modo claro y oscuro,
    /// igual que un ColorScheme de Material 3 en Compose.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
