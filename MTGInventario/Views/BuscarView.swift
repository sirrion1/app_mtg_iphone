import SwiftUI

/// Equivalente a `BuscarScreen.kt`.
///
/// Nota sobre el permiso de red local: en Android hace falta pedirlo a
/// mano (`LocalNetworkPermission.kt`). En iOS no existe esa API: basta con
/// añadir `NSLocalNetworkUsageDescription` al Info.plist (ver GUIA.md) y el
/// sistema muestra el aviso automáticamente la primera vez que la app habla
/// con una IP de tu red local (192.168.x.x, etc.), sin que tengamos que
/// gestionarlo desde el código.
struct BuscarView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var consulta: String = ""
    @State private var sugerencias: [Sugerencia] = []
    @State private var nombreElegido: String?
    @State private var impresiones: [Impresion] = []
    @State private var impresionElegida: Impresion?
    @State private var foil: Bool = false
    @State private var cargando = false
    @State private var mensaje: String?
    @State private var mensajeEsError = false
    @State private var busquedaTask: Task<Void, Never>?
    /// Cuando seleccionamos una sugerencia o llega texto escaneado,
    /// actualizamos `consulta` nosotros mismos (no el usuario tecleando).
    /// Esta bandera evita que ese cambio programático dispare otra vez el
    /// reseteo de la selección + búsqueda, igual que en Android el
    /// `onValueChange` del TextField solo salta con toques reales del
    /// usuario, nunca al asignar el estado desde código.
    @State private var ignorarProximoCambioDeConsulta = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cabecera
                campoBusqueda

                if !sugerencias.isEmpty, nombreElegido == nil {
                    listaSugerencias
                }

                if cargando {
                    HStack {
                        Spacer()
                        ProgressView().tint(MtgTheme.dorado)
                        Spacer()
                    }
                    .padding(.top, 12)
                }

                if !impresiones.isEmpty {
                    detalleImpresiones
                } else if !cargando && consulta.isEmpty {
                    estadoVacio
                }

                if let mensaje {
                    mensajeFila(mensaje)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(MtgTheme.fondo.ignoresSafeArea())
        .onChange(of: viewModel.textoParaBuscar) { nuevoTexto in
            guard !nuevoTexto.isEmpty else { return }
            consulta = nuevoTexto
            viewModel.setTextoParaBuscar("")
        }
        .onChange(of: consulta) { nuevaConsulta in
            if ignorarProximoCambioDeConsulta {
                ignorarProximoCambioDeConsulta = false
                return
            }
            // Al cambiar el texto a mano se invalida cualquier
            // edición/impresión que ya estuviera elegida (igual que
            // `onValueChange` del TextField en la versión Android).
            nombreElegido = nil
            impresiones = []
            impresionElegida = nil
            mensaje = nil

            busquedaTask?.cancel()
            guard nuevaConsulta.count >= 2 else {
                sugerencias = []
                return
            }
            busquedaTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                let resultado = await ScryfallApi.buscarPorTexto(nuevaConsulta)
                guard !Task.isCancelled else { return }
                sugerencias = resultado
            }
        }
    }

    // MARK: - Subvistas

    private var cabecera: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Buscar carta").font(.title2.bold()).foregroundStyle(MtgTheme.texto)
            Text("Escribe el nombre o escanéala desde la pestaña Escanear")
                .font(.subheadline)
                .foregroundStyle(MtgTheme.textoApagado)
        }
    }

    private var campoBusqueda: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(MtgTheme.textoApagado)
            TextField("Nombre de la carta", text: $consulta)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(MtgTheme.superficieVariante)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var listaSugerencias: some View {
        VStack(spacing: 0) {
            ForEach(sugerencias) { sugerencia in
                Button {
                    seleccionarSugerencia(sugerencia)
                } label: {
                    HStack {
                        Text(sugerencia.textoMostrado).foregroundStyle(MtgTheme.texto)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }
                if sugerencia.id != sugerencias.last?.id {
                    Divider()
                }
            }
        }
        .background(MtgTheme.superficieVariante)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .frame(maxHeight: 220)
    }

    private var detalleImpresiones: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // Miniatura de la carta seleccionada.
                AsyncImage(url: URL(string: impresionElegida?.imageUrl ?? "")) { fase in
                    if let imagen = fase.image {
                        imagen.resizable().scaledToFill()
                    } else {
                        MtgTheme.superficieVariante
                    }
                }
                .frame(width: 90, height: 90 * 88 / 63)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Edición").font(.headline).foregroundStyle(MtgTheme.texto)
                    listaEdiciones
                }
            }
            .frame(minHeight: 220)

            HStack {
                Text("Foil").foregroundStyle(MtgTheme.texto)
                Spacer()
                Toggle("", isOn: $foil)
                    .labelsHidden()
                    .disabled(impresionElegida?.foilDisponible != true)
            }

            botonAnadir
        }
    }

    private var listaEdiciones: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(impresiones) { impresion in
                    Button {
                        impresionElegida = impresion
                        if !impresion.foilDisponible { foil = false }
                    } label: {
                        HStack(spacing: 10) {
                            SVGIconView(url: impresion.iconoEdicionUrl, tinta: MtgTheme.textoApagado)
                                .frame(width: 22, height: 22)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(nombreEdicionMostrado(impresion))
                                    .font(.subheadline)
                                    .foregroundStyle(MtgTheme.texto)
                                    .lineLimit(1)
                                Text(etiquetaEdicion(impresion))
                                    .font(.caption)
                                    .foregroundStyle(MtgTheme.textoApagado)
                            }
                            Spacer()
                            if impresion == impresionElegida {
                                Image(systemName: "checkmark").foregroundStyle(MtgTheme.dorado)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                    }
                }
            }
        }
        .background(MtgTheme.superficieVariante)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox").font(.system(size: 48)).foregroundStyle(MtgTheme.textoApagado)
            Text("Busca una carta para añadirla a tu inventario")
                .font(.subheadline)
                .foregroundStyle(MtgTheme.textoApagado)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private var botonAnadir: some View {
        Button {
            anadirAlInventario()
        } label: {
            HStack {
                Image(systemName: "shippingbox")
                Text("Añadir al inventario")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(MtgTheme.dorado)
        .disabled(impresionElegida == nil || cargando)
    }

    private func mensajeFila(_ texto: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(mensajeEsError ? MtgTheme.estadoError : MtgTheme.estadoOk)
                .frame(width: 8, height: 8)
            Text(texto)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(mensajeEsError ? MtgTheme.estadoError : MtgTheme.estadoOk)
        }
    }

    // MARK: - Lógica

    private func nombreEdicionMostrado(_ impresion: Impresion) -> String {
        if impresion.lang != "en", let localizado = impresion.nombreLocalizado {
            return "\(impresion.setName) · \(localizado)"
        }
        return impresion.setName
    }

    private func etiquetaEdicion(_ impresion: Impresion) -> String {
        let base = impresion.setCode.uppercased()
        return impresion.lang != "en" ? "\(base) · \(impresion.lang.uppercased())" : base
    }

    private func seleccionarSugerencia(_ sugerencia: Sugerencia) {
        nombreElegido = sugerencia.nombreOracle
        ignorarProximoCambioDeConsulta = true
        consulta = sugerencia.textoMostrado
        sugerencias = []
        cargando = true
        Task {
            let resultado = await ScryfallApi.buscarImpresiones(nombreExacto: sugerencia.nombreOracle, idiomaPreferido: sugerencia.lang)
            impresiones = resultado
            impresionElegida = resultado.first { $0.lang == sugerencia.lang } ?? resultado.first
            foil = (impresionElegida?.foilDisponible == true) && (impresionElegida?.normalDisponible != true)
            cargando = false
        }
    }

    private func anadirAlInventario() {
        guard let impresion = impresionElegida, let nombre = nombreElegido else { return }
        cargando = true
        mensaje = nil
        Task {
            let baseUrl = Preferences.getServerUrl()
            let resultado = await ServerApi.enviarCarta(baseUrl: baseUrl, nombre: nombre, edicion: impresion.setCode, foil: foil, idioma: impresion.lang)
            switch resultado {
            case .ok(let datos):
                let accion = datos.status == "incrementada" ? "Incrementada" : "Añadida"
                let precioTexto = datos.precioEur.map { String(format: " · %.2f €", $0) } ?? ""
                let idiomaTexto = (datos.idioma.flatMap { $0 != "en" ? $0.uppercased() : nil }).map { " · \($0)" } ?? ""
                mensaje = "\(accion): \(datos.nombre) (\(datos.edicion.uppercased())\(idiomaTexto)) · cantidad: \(datos.cantidad)\(precioTexto)"
                mensajeEsError = false
            case .error(let texto):
                mensaje = "Error: \(texto)"
                mensajeEsError = true
            }
            cargando = false
        }
    }
}

#Preview {
    BuscarView().environmentObject(AppViewModel())
}
