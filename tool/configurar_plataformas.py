"""Ajusta las carpetas android/ e ios/ que crea «flutter create» para Trilex.

Uso (desde la carpeta de la app, después de flutter create):  python3 tool/configurar_plataformas.py

Se puede ejecutar varias veces: cada cambio se aplica una sola vez.
- Nombre «Trilex» e identificador com.trilex.app (Android e iOS).
- Android: permisos (internet, notificaciones, reinicio), receptores de los recordatorios,
  consultas para la voz (TTS) y los enlaces, y «desugaring» (lo pide flutter_local_notifications).
- iOS: delegado de notificaciones en AppDelegate.swift y nombre visible.
"""

import os
import re
import sys

APP_ID = "com.trilex.app"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
done = []


def edit(path, fn):
    p = os.path.join(ROOT, path)
    if not os.path.exists(p):
        return False
    s = open(p, encoding="utf-8").read()
    t = fn(s)
    if t != s:
        open(p, "w", encoding="utf-8").write(t)
        done.append(path)
    return True


def manifest(s):
    perms = [
        "android.permission.INTERNET",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.RECEIVE_BOOT_COMPLETED",
    ]
    for perm in perms:
        if perm not in s:
            s = s.replace("<application", f'<uses-permission android:name="{perm}"/>\n    <application', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="Trilex"', s, count=1)
    if "ScheduledNotificationReceiver" not in s:
        receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>"""
        s = s.replace("</application>", receivers, 1)
    if "TTS_SERVICE" not in s:
        query = """        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
"""
        if "<queries>" in s:
            s = s.replace("<queries>", "<queries>\n" + query, 1)
        else:
            s = s.replace("</manifest>", "    <queries>\n" + query + "    </queries>\n</manifest>", 1)
    return s


def gradle_kts(s):
    s = re.sub(r'applicationId = "[^"]*"', f'applicationId = "{APP_ID}"', s)
    if "isCoreLibraryDesugaringEnabled" not in s:
        s = re.sub(r"compileOptions \{", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", s, count=1)
    if "desugar_jdk_libs" not in s:
        s = s.rstrip() + '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    return s


def gradle_groovy(s):
    s = re.sub(r'applicationId "[^"]*"', f'applicationId "{APP_ID}"', s)
    s = re.sub(r"applicationId = \"[^\"]*\"", f'applicationId = "{APP_ID}"', s)
    if "coreLibraryDesugaringEnabled" not in s:
        s = re.sub(r"compileOptions \{", "compileOptions {\n        coreLibraryDesugaringEnabled true", s, count=1)
    if "desugar_jdk_libs" not in s:
        s = s.rstrip() + "\n\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    return s


def app_delegate(s):
    if "UNUserNotificationCenter" in s:
        return s
    if "import UserNotifications" not in s:
        s = s.replace("import UIKit", "import UIKit\nimport UserNotifications", 1)
    return s.replace(
        "GeneratedPluginRegistrant.register(with: self)",
        "UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate\n"
        "    GeneratedPluginRegistrant.register(with: self)",
        1,
    )


def info_plist(s):
    s = re.sub(
        r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", r"\1Trilex\2", s, count=1
    )
    return s


def pbxproj(s):
    return re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = [A-Za-z0-9.\-]+?(\.RunnerTests)?;",
                  lambda m: f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID}{m.group(1) or ''};", s)


if not os.path.isdir(os.path.join(ROOT, "android")) or not os.path.isdir(os.path.join(ROOT, "ios")):
    sys.exit("Faltan las carpetas android/ e ios/: primero ejecuta\n"
             "  flutter create --org com.trilex --project-name trilex --platforms android,ios .")

edit("android/app/src/main/AndroidManifest.xml", manifest)
if not edit("android/app/build.gradle.kts", gradle_kts):
    edit("android/app/build.gradle", gradle_groovy)
edit("ios/Runner/AppDelegate.swift", app_delegate)
edit("ios/Runner/Info.plist", info_plist)
edit("ios/Runner.xcodeproj/project.pbxproj", pbxproj)
print("Archivos ajustados:" if done else "Nada que cambiar (ya estaba configurado).")
for p in done:
    print("  -", p)
