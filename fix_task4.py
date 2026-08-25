import os
import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\screens\oil_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace VehiclePhoto in oil_screen.dart
pattern = re.compile(r"child: SizedBox\.expand\(child: VehiclePhoto\(vehicle: vehicle\)\),", re.DOTALL)
replacement = """child: SizedBox.expand(
                  child: vehicle == null 
                    ? const Center(
                        child: Text(
                          'Fotoğrafı görmek için bir araç seçin',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ) 
                    : VehiclePhoto(vehicle: vehicle)
                ),"""

content = pattern.sub(lambda m: replacement, content, count=1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Task 4 fixed")
