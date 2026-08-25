import os

file_path = r'C:\new class\nimo_ariza_bakim\lib\models\models.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """class GenericActivity extends ActivityRecord {
  GenericActivity({
    required super.id,
    required super.vehicleCode,
    required super.date,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}"""

if target in content:
    content = content.replace(target, '')
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("GenericActivity removed")
else:
    print("GenericActivity not found")
