#!/usr/bin/env bash
# Crea el proyecto Flutter y copia el código (se ejecuta desde la raíz del repositorio)
set -e
flutter create --org com.focuspet --project-name focuspet --platforms android app
cd app
flutter pub add shared_preferences
cp ../overlay/lib/*.dart lib/
K=android/app/src/main/kotlin/com/focuspet/focuspet
mkdir -p $K android/app/src/main/res/xml android/app/src/main/res/values
cp ../overlay/kotlin/*.kt $K/
cp ../overlay/res/xml/*.xml android/app/src/main/res/xml/
cp ../overlay/res/values/*.xml android/app/src/main/res/values/
python3 - <<'PY'
p = 'android/app/src/main/AndroidManifest.xml'
m = open(p).read()
s = open('../overlay/service.xml').read()
perms = ('<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n'
         '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n'
         '    <uses-permission android:name="android.permission.VIBRATE" />\n'
         '    ')
q = ('<intent>\n            <action android:name="android.intent.action.MAIN" />\n'
     '            <category android:name="android.intent.category.LAUNCHER" />\n        </intent>\n        ')
if 'BlockerService' not in m:
    m = m.replace('<application', perms + '<application', 1)
    m = m.replace('</application>', s + '    </application>')
    if '<queries>' in m:
        m = m.replace('<queries>', '<queries>\n        ' + q, 1)
    else:
        m = m.replace('</manifest>', '    <queries>\n        ' + q + '</queries>\n</manifest>')
    open(p, 'w').write(m)
PY
