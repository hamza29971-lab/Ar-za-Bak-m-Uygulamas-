import os

file_path = r'C:\new class\nimo_ariza_bakim\android\app\src\main\AndroidManifest.xml'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if 'android.permission.INTERNET' not in content:
    content = content.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET" />'
    )
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Internet permission added")
else:
    print("Already has internet permission")
