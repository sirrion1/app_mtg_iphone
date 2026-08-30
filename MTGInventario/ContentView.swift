import SwiftUI

/// Equivalente a `AppRoot` (dentro de `MainActivity.kt`): la barra de
/// pestañas inferior con Buscar / Escanear / Ajustes.
struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var pestana: Pestana = .buscar

    private enum Pestana: Hashable {
        case buscar, escanear, ajustes
    }

    var body: some View {
        TabView(selection: $pestana) {
            BuscarView()
                .tabItem { Label("Buscar", systemImage: pestana == .buscar ? "magnifyingglass.circle.fill" : "magnifyingglass") }
                .tag(Pestana.buscar)

            EscanearView { textoDetectado in
                viewModel.setTextoParaBuscar(textoDetectado)
                pestana = .buscar
            }
            .tabItem { Label("Escanear", systemImage: pestana == .escanear ? "camera.fill" : "camera") }
            .tag(Pestana.escanear)

            AjustesView()
                .tabItem { Label("Ajustes", systemImage: pestana == .ajustes ? "gearshape.fill" : "gearshape") }
                .tag(Pestana.ajustes)
        }
        .tint(MtgTheme.dorado)
    }
}

#Preview {
    ContentView().environmentObject(AppViewModel())
}
