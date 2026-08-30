import SwiftUI

private enum EstadoConexion: Equatable {
    case desconocido
    case comprobando
    case ok
    case error(String)
}

/// Equivalente a `AjustesScreen.kt`.
///
/// A diferencia de Android, aquí no hace falta gestionar el permiso de red
/// local a mano: basta con `NSLocalNetworkUsageDescription` en el
/// Info.plist (ver GUIA.md) y iOS pregunta solo la primera vez que
/// `probarConexion` / `enviarCarta` llaman de verdad a tu servidor.
struct AjustesView: View {
    @State private var url: String = Preferences.getServerUrl()
    @State private var guardado = false
    @State private var estado: EstadoConexion = .desconocido

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ajustes").font(.title2.bold()).foregroundStyle(MtgTheme.texto)
                    Text("Configura la conexión con tu servidor de inventario")
                        .font(.subheadline)
                        .foregroundStyle(MtgTheme.textoApagado)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "server.rack").foregroundStyle(MtgTheme.dorado)
                        Text("Servidor de inventario (PC)").font(.headline).foregroundStyle(MtgTheme.texto)
                    }

                    TextField("http://192.168.1.100:5000", text: $url)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(MtgTheme.superficie)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onChange(of: url) { _ in
                            guardado = false
                            estado = .desconocido
                        }

                    HStack(spacing: 12) {
                        Button("Guardar") {
                            Preferences.setServerUrl(url)
                            guardado = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(MtgTheme.dorado)

                        Button("Probar conexión") {
                            estado = .comprobando
                            Task {
                                let resultado = await ServerApi.probarConexion(baseUrl: url)
                                switch resultado {
                                case .ok: estado = .ok
                                case .error(let mensaje): estado = .error(mensaje)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(estado == .comprobando)
                    }

                    if guardado {
                        Text("Guardado ✓").foregroundStyle(MtgTheme.estadoOk).fontWeight(.medium)
                    }

                    estadoVista
                }
                .padding(16)
                .background(MtgTheme.superficieVariante)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(MtgTheme.fondo.ignoresSafeArea())
    }

    @ViewBuilder
    private var estadoVista: some View {
        switch estado {
        case .desconocido:
            EmptyView()
        case .comprobando:
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.8)
                Text("Comprobando conexión...").font(.subheadline).foregroundStyle(MtgTheme.texto)
            }
        case .ok:
            estadoFila(color: MtgTheme.estadoOk, texto: "Conectado correctamente al servidor")
        case .error(let mensaje):
            estadoFila(color: MtgTheme.estadoError, texto: mensaje)
        }
    }

    private func estadoFila(color: Color, texto: String) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(texto).font(.subheadline.weight(.medium)).foregroundStyle(color)
        }
    }
}

#Preview {
    AjustesView()
}
