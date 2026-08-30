# Compilar e instalar MTGInventario sin Mac (GitHub Actions + Sideloadly)

Esta es la ruta para tu caso: **cero Mac, en ningún momento**. Se apoya en dos piezas:

1. **GitHub Actions** compila el código en un Mac virtual de GitHub (gratis) y te devuelve un `.ipa` **sin firmar**.
2. **Sideloadly** (programa gratuito para Windows/Mac) firma ese `.ipa` con tu Apple ID normal y lo instala en tu iPhone por cable — esto es lo que de verdad reemplaza a "abrir Xcode y darle a Play". Es la misma técnica que usan herramientas como AltStore.

Limitación real que debes conocer desde ya: con un Apple ID gratis (sin pagar los 99 $/año), la app instalada **caduca a los 7 días** y hay que repetir el paso de Sideloadly. Es una restricción de Apple para cuentas gratuitas, no algo que se pueda evitar.

## Parte A — Subir el proyecto a GitHub

1. Crea una cuenta en [github.com](https://github.com) si no tienes.
2. Crea un repositorio nuevo, por ejemplo `mtginventario-ios`. Puedes dejarlo **público** (así los minutos de GitHub Actions para macOS son gratis e ilimitados; si lo haces privado, macOS consume minutos de tu cuota gratuita 10 veces más rápido que Linux).
3. Sube el contenido de la carpeta que te entregué (`MTGInventarioIOS/`, incluyendo `.github/`, `project.yml`, `MTGInventario/`) a ese repositorio. Formas de hacerlo sin usar la terminal:
   - En la página del repo → "uploading an existing file" → arrastra todos los archivos y carpetas.
   - O instala **GitHub Desktop** (Windows), que te deja arrastrar la carpeta entera y hacer "Publish repository" con un par de clics.

## Parte B — Lanzar la compilación

1. En tu repositorio de GitHub, ve a la pestaña **Actions**.
2. Verás el workflow **"Compilar MTGInventario (iOS, sin firmar)"**. Si no se lanzó solo, pulsa **Run workflow** → **Run workflow** (botón verde).
3. Espera unos 3-8 minutos. Cuando termine:
   - ✅ Verde = compiló bien.
   - ❌ Rojo = hay un error. Pulsa sobre la ejecución fallida → abre el paso **"Compilar para iPhone"** → copia el texto en rojo → pégamelo tal cual y te doy la corrección. Corriges el archivo en GitHub, y vuelves a lanzar el workflow (no hace falta nada más).
4. Si salió verde, baja hasta la sección **Artifacts** de esa misma ejecución y descarga `MTGInventario-sin-firmar` (es un .zip que contiene el `.ipa`).

## Parte C — Firmar e instalar con Sideloadly

1. Descarga Sideloadly desde **sideloadly.io** (gratis, para Windows o Mac).
2. Instálalo. Te pedirá tener iTunes o los drivers de Apple Mobile Device instalados (Sideloadly te avisa y enlaza el instalador si te falta).
3. Conecta el iPhone al PC con cable USB. Autoriza "Confiar en este ordenador" en el iPhone si te lo pregunta.
4. Abre Sideloadly. Tu iPhone debería aparecer arriba a la izquierda.
5. Arrastra el archivo `MTGInventario-sin-firmar.ipa` (el que descargaste de GitHub, descomprimido) al centro de la ventana.
6. En el campo Apple ID, escribe tu Apple ID normal (el de la App Store) y su contraseña. Sideloadly lo usa solo para pedirle a Apple un certificado de desarrollo gratuito, igual que hace Xcode — no publica nada ni sube tu app a ningún sitio.
7. Pulsa **Start**. Puede pedir un código de verificación en dos pasos de tu Apple ID: introdúcelo.
8. Cuando termine, la app "MTGInventario" aparece en tu iPhone.
9. Primera vez que la abras: **Ajustes → General → VPN y gestión de dispositivos** → toca tu Apple ID → **Confiar**. Igual que en el flujo con Xcode.

## Cuando caduque a los 7 días

Repite solo la Parte C (Sideloadly) con el mismo `.ipa` que ya tienes descargado — no hace falta volver a compilar en GitHub, a menos que hayas cambiado código.

## Si en algún momento consigues un Mac prestado un rato

Puedes ignorar todo esto y usar directamente `GUIA.md` (el otro documento que te di): abrir el proyecto en Xcode de verdad es más cómodo para depurar, y de paso la app dura más de 7 días si esa Apple ID entra en el programa de pago. Pero para lo que tienes ahora mismo, este camino funciona igual de bien para probar la app en tu iPhone.
