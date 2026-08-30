import SwiftUI
import AVFoundation

/// Equivalente a `EscanearScreen.kt`.
struct EscanearView: View {
    var onTextoDetectado: (String) -> Void

    @StateObject private var controller = CameraController()
    @State private var permisoConcedido = false
    @State private var permisoDenegado = false
    @State private var lineasDetectadas: [String] = []
    @State private var procesando = false

    var body: some View {
        VStack(spacing: 0) {
            if permisoConcedido {
                vistaCamara
                controlesInferiores
            } else {
                estadoSinPermiso
            }
        }
        .background(MtgTheme.fondo.ignoresSafeArea())
        .task {
            await comprobarYPedirPermiso()
        }
        .onAppear {
            if permisoConcedido { controller.iniciar() }
        }
        .onDisappear {
            controller.detener()
        }
    }

    private var vistaCamara: some View {
        ZStack(alignment: .top) {
            CameraPreviewView(controller: controller)
                .onAppear {
                    controller.configurar()
                    controller.iniciar()
                }

            // Marco guía para encuadrar el nombre de la carta.
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                .frame(height: 56)
                .padding(.horizontal, 30)
                .padding(.top, 24)

            if procesando {
                ZStack {
                    Color.black.opacity(0.35)
                    VStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Leyendo carta...").foregroundStyle(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controlesInferiores: some View {
        VStack(spacing: 16) {
            Button {
                Task { await capturarYLeer() }
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(procesando ? "Procesando..." : "Capturar foto")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(MtgTheme.dorado)
            .disabled(procesando)

            if !lineasDetectadas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "textformat").foregroundStyle(MtgTheme.textoApagado)
                        Text("Toca la línea que sea el nombre (la de letra más grande sale primero)")
                            .font(.subheadline)
                            .foregroundStyle(MtgTheme.textoApagado)
                    }
                    VStack(spacing: 0) {
                        ForEach(lineasDetectadas, id: \.self) { linea in
                            Button {
                                onTextoDetectado(linea)
                            } label: {
                                HStack {
                                    Text(linea).foregroundStyle(MtgTheme.texto)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                            }
                            if linea != lineasDetectadas.last {
                                Divider()
                            }
                        }
                    }
                    .background(MtgTheme.superficieVariante)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding(16)
        .background(MtgTheme.superficie)
    }

    private var estadoSinPermiso: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill").font(.system(size: 56)).foregroundStyle(MtgTheme.textoApagado)
            Text("Se necesita permiso de cámara para escanear cartas")
                .font(.subheadline)
                .foregroundStyle(MtgTheme.textoApagado)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if permisoDenegado {
                Text("Lo denegaste antes: actívalo en Ajustes de iOS > MTGInventario > Cámara.")
                    .font(.caption)
                    .foregroundStyle(MtgTheme.estadoError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Abrir Ajustes de iOS") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(MtgTheme.dorado)
            } else {
                Button("Conceder permiso") {
                    Task { await comprobarYPedirPermiso() }
                }
                .buttonStyle(.borderedProminent)
                .tint(MtgTheme.dorado)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func comprobarYPedirPermiso() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permisoConcedido = true
        case .notDetermined:
            let concedido = await AVCaptureDevice.requestAccess(for: .video)
            permisoConcedido = concedido
            permisoDenegado = !concedido
        default:
            permisoConcedido = false
            permisoDenegado = true
        }
    }

    private func capturarYLeer() async {
        procesando = true
        lineasDetectadas = []
        await controller.enfocarCentro()
        guard let imagen = await controller.capturarFoto() else {
            procesando = false
            return
        }
        let lineas = await ReconocedorTexto.reconocer(en: imagen)
        lineasDetectadas = lineas
        procesando = false
    }
}
