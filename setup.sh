#!/usr/bin/env bash
# Uso: conecta el móvil Android (depuración USB) y ejecuta ./setup.sh
set -e
flutter create --org com.focuspet --project-name focuspet --platforms android app
cd app
flutter pub add shared_preferences google_fonts
cp ../overlay/lib/*.dart lib/
K=android/app/src/main/kotlin/com/focuspet/focuspet
mkdir -p $K android/app/src/main/res/xml android/app/src/main/res/values
cp ../overlay/kotlin/*.kt $K/
cp ../overlay/res/xml/*.xml android/app/src/main/res/xml/
cp ../overlay/res/values/*.xml android/app/src/main/res/values/
python3 - <<'PY'
p='android/app/src/main/AndroidManifest.xml'
m=open(p).read(); s=open('../overlay/service.xml').read()
if 'BlockerService' not in m:
    open(p,'w').write(m.replace('</application>', s+'    </application>'))
PY
flutter run
