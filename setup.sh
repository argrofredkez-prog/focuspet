#!/usr/bin/env bash
# Uso local: conecta el móvil (depuración USB) y ejecuta ./setup.sh
set -e
bash overlay/ci.sh
cd app
flutter run
