#!/bin/bash

# 1. Descargar Flutter SDK (Versión estable)
FLUTTER_VERSION="3.47.2" # Cambia esto a la versión que uses
curl -O https://storage.googleapis.com/flutter_infra/releases/linux/flutter_linux_\${FLUTTER_VERSION}-stable.tar.xz

# 2. Extraer el archivo
tar xf flutter_linux_\${FLUTTER_VERSION}-stable.tar.xz

# 3. Agregar Flutter al PATH temporal del entorno
export PATH="\$PATH:`pwd`/flutter/bin"

# 4. Habilitar soporte web y compilar
flutter config --enable-web
flutter build web --release
