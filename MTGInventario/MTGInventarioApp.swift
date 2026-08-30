import SwiftUI

/// Equivalente al `class MainActivity : ComponentActivity()` de Android.
/// En SwiftUI el punto de entrada de la app es un `struct` marcado con
/// `@main`, sin necesidad de un AndroidManifest ni de registrar nada
/// parecido al ImageLoader de Coil (SwiftUI's AsyncImage y nuestro
/// SVGIconView ya llevan su propia configuración de red incluida).
@main
struct MTGInventarioApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(nil) // sigue el modo claro/oscuro del sistema
        }
    }
}
