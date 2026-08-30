import Foundation
import Combine

/// Equivalente a `AppViewModel.kt`. Se usa para pasar el texto detectado en
/// la pantalla de Escanear hacia la pantalla de Buscar (en Android era un
/// `ViewModel` compartido a nivel de Activity; en SwiftUI lo compartimos
/// como `@StateObject` inyectado a toda la jerarquía de vistas).
final class AppViewModel: ObservableObject {
    @Published var textoParaBuscar: String = ""

    func setTextoParaBuscar(_ texto: String) {
        textoParaBuscar = texto
    }
}
