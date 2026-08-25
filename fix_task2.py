import os
import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\tire_change_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('autofocus: true,', 'autofocus: false,')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Autofocus disabled")
