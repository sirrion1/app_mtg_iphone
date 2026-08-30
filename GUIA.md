# MTGInventario para iPhone — guía paso a paso

Este documento asume que **nunca has usado Xcode**. Sigue los pasos en orden.

## 0. Lo que vas a necesitar

- Un **Mac** (propio, prestado, o de pago por horas: MacinCloud, MacStadium...). No hay alternativa: Apple exige macOS para compilar apps de iOS.
- **Xcode**, gratis desde la Mac App Store (varios GB, resérvate tiempo para la descarga).
- Un **Apple ID** normal y corriente (el mismo que usas para la App Store) — sirve para probar la app en tu propio iPhone gratis. Solo si algún día quieres subirla a la App Store necesitarás el programa de pago (99 $/año).
- Tu **iPhone** con un cable (o la misma red Wi-Fi que el Mac), para poder probarla de verdad — la cámara no funciona en el simulador de Xcode.

## 1. Instalar Xcode

1. Abre la **App Store** en el Mac.
2. Busca "Xcode" e instálalo (botón "Obtener").
3. Ábrelo una vez para que termine de instalar componentes adicionales (te lo pedirá él solo).

## 2. Crear el proyecto en Xcode

1. Abre Xcode → **File → New → Project…**
2. Elige la pestaña **iOS** → plantilla **App** → **Next**.
3. Rellena:
   - **Product Name**: `MTGInventario`
   - **Team**: tu Apple ID (si no aparece, pulsa "Add Account…" e inicia sesión)
   - **Organization Identifier**: algo tipo `com.tunombre` (junto con el nombre del producto forma el ID único de la app, equivalente al `applicationId` de tu `build.gradle.kts`)
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - Desmarca "Use Core Data" y "Include Tests" (no los necesitamos)
4. **Next** → elige dónde guardarlo → **Create**.

Xcode te crea un proyecto con `MTGInventarioApp.swift` y `ContentView.swift` de plantilla — **los vas a reemplazar** con los que te he preparado.

## 3. Añadir los archivos que te he generado

En el Finder, dentro de la carpeta que te he entregado, tienes una carpeta `MTGInventario/` con esta estructura (refleja la de tu proyecto Android):

```
MTGInventario/
  MTGInventarioApp.swift
  ContentView.swift
  AppViewModel.swift
  Preferences.swift
  Models/
    CardModels.swift
  Network/
    ScryfallApi.swift
    ServerApi.swift
  Views/
    BuscarView.swift
    EscanearView.swift
    AjustesView.swift
    Components/
      CameraController.swift
      CameraPreviewView.swift
      ReconocedorTexto.swift
      SVGIconView.swift
  Theme/
    Theme.swift
```

1. En Xcode, **borra** los `MTGInventarioApp.swift` y `ContentView.swift` de plantilla que se crearon solos (clic derecho → Delete → "Move to Trash").
2. En el Finder, arrastra **toda la carpeta `MTGInventario/`** que te he entregado (su contenido, no la carpeta contenedora) al panel izquierdo de Xcode (el "Project Navigator"), dentro del grupo azul `MTGInventario`.
3. En el diálogo que aparece:
   - Marca **"Copy items if needed"**
   - En "Added folders" elige **"Create groups"** (no "Create folder references")
   - Asegúrate de que el target `MTGInventario` esté marcado
   - **Finish**

## 4. Configurar Info.plist (permisos)

Tu app pide cámara y habla con tu servidor en la red local, así que iOS necesita que declares eso.

1. En Xcode, selecciona el proyecto (icono azul arriba del todo) → target `MTGInventario` → pestaña **Info**.
2. En "Custom iOS Target Properties", añade estas claves (botón `+` sobre cualquier fila):

| Clave (Key) | Tipo | Valor |
|---|---|---|
| `Privacy - Camera Usage Description` | String | `Necesitamos la cámara para escanear el nombre de tus cartas.` |
| `Privacy - Local Network Usage Description` | String | `Necesitamos acceso a tu red local para hablar con tu servidor de inventario.` |
| `App Transport Security Settings` → `Allow Local Networking` | Boolean | `YES` |

La última clave es el equivalente al permiso runtime `ACCESS_LOCAL_NETWORK` de Android 16/17 que ya conoces de `LocalNetworkPermission.kt`: en iOS no hay que pedirlo a mano desde el código, el sistema muestra el aviso automáticamente la primera vez que la app llama de verdad a una IP de tu red (192.168.x.x). Sin esa clave de ATS, iOS bloquearía las peticiones **http://** (no https) a tu servidor.

3. Ve a la pestaña **General** → **Minimum Deployments** → pon **iOS 16.0** (lo usamos para el reconocimiento automático de idioma al escanear).

## 5. Compilar y probar en tu iPhone

1. Conecta el iPhone al Mac por cable (o mismo Wi-Fi con "Wireless debugging" activado en el iPhone, en Ajustes → General → Transferir o resetear iPhone → no, en Xcode: Window → Devices and Simulators).
2. En el iPhone: **Ajustes → Privacidad y seguridad → Modo Desarrollador → Activar** (te pedirá reiniciar el teléfono; es obligatorio desde iOS 16 para poder instalar apps compiladas por ti).
3. En Xcode, arriba a la izquierda, en el selector de dispositivo (donde suele decir "iPhone 15 simulator"), elige tu iPhone físico.
4. Pulsa el botón ▶️ (Run) o `Cmd+R`.
5. La primera vez te saldrá un error de firma tipo "Failed to register bundle identifier" o "Untrusted Developer" — es normal:
   - En el iPhone: **Ajustes → General → VPN y gestión de dispositivos** → toca tu Apple ID → **Confiar**.
   - Vuelve a pulsar ▶️ en Xcode.
6. Con una cuenta gratis (sin pagar los 99 $/año) la app deja de funcionar en el iPhone a los **7 días** y hay que reinstalarla desde Xcode; es una limitación de Apple, no un fallo tuyo.

## 6. Qué esperar la primera vez que la ejecutes

- Al entrar en la pestaña **Escanear**, iOS te pedirá permiso de cámara (como en Android).
- Al pulsar "Probar conexión" o "Añadir al inventario" por primera vez, iOS te preguntará algo como *"MTGInventario would like to find and connect to devices on your local network"* — acepta, es el equivalente al permiso de red local.
- Si tu servidor sigue corriendo en `http://192.168.1.100:5000` (o la IP que uses), cambia esa dirección en la pestaña Ajustes igual que hacías en Android.

## 7. Diferencias que he tenido que resolver al portar el código

- **Cámara**: CameraX → AVFoundation (archivo `CameraController.swift` + `CameraPreviewView.swift`). El zoom por pellizco y el enfoque central antes de disparar están replicados.
- **OCR**: ML Kit (4 motores por idioma en paralelo) → Vision framework de Apple, que soporta varios idiomas en **una sola pasada**, así que el código quedó más simple sin perder cobertura de idiomas (`ReconocedorTexto.swift`).
- **Iconos de edición (SVG)**: Coil (Android) sabe pintar SVG nativamente; en iOS no existe eso de fábrica, así que uso un `WKWebView` diminuto que carga el SVG y lo tiñe con CSS (`SVGIconView.swift`). Es la pieza más "casera" del port — si algún día quieres algo más pulido, la librería `SVGKit` (via Swift Package Manager) es la opción estándar.
- **Permiso de red local**: en Android lo pedías a mano; en iOS es automático en cuanto declaras la clave del Info.plist (paso 4).
- **Preferencias**: `SharedPreferences` → `UserDefaults`, cambio directo.

## 8. Si algo no compila

Como te comenté, yo no puedo compilar este proyecto por mi cuenta (no tengo macOS/Xcode disponibles). Si Xcode te marca un error:

1. Copia el **texto exacto** del error (clic en el triángulo rojo/amarillo del panel izquierdo de Xcode, o el panel de "Issue Navigator", icono ⚠️).
2. Pégamelo tal cual, junto con el nombre del archivo y la línea donde ocurre.
3. Te doy la corrección exacta.

Los errores más típicos en un primer port suelen ser tonterías: una comilla, un nombre de tipo que en tu versión de Xcode se llama distinto, o un `import` que falta. Nada estructural.
