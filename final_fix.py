import os
import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\tire_change_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import for models.dart if not present
if "import '../../models/models.dart';" not in content:
    content = content.replace("import '../../services/publish_service.dart';", "import '../../services/publish_service.dart';\nimport '../../models/models.dart';")

# 2. Fix _submit to add ServiceReportActivity
submit_pattern = re.compile(r"state\.addPending\(PendingOperation\([\s\S]*?\}\,\s*\)\);", re.DOTALL)
submit_replacement = """state.addPending(PendingOperation(
            kind: PendingKind.tire,
            vehicleCode: vehicle.name,
            label: 'Lastik #${widget.record.tireNumber} kontrol edildi',
            date: DateTime.now(),
            payload: <String, Object?>{
              'op': 'lastik_kontrol',
              'tireId': 'Lastik #${widget.record.tireNumber}',
              'position': 'Lastik ${widget.record.tireNumber}',
              'items': actions,
            },
          ));
          state.addActivity(
            ServiceReportActivity(
              id: 'tire-check-${DateTime.now().microsecondsSinceEpoch}',
              vehicleCode: vehicle.name,
              date: DateTime.now(),
              reportType: 'Lastik Kontrolü',
              description: actions.join('\\n'),
              imagePaths: [],
            )
          );"""
content = submit_pattern.sub(lambda m: submit_replacement, content, count=1)

# 3. Fix _sendPending notification
send_pattern = re.compile(r"setState\(\(\) => _sending = false\);\s*if \(!result\.success\) \{", re.DOTALL)
send_replacement = """setState(() => _sending = false);
  
      if (result.success) {
        state.addNotification(
          NotificationItem(
            title: 'Lastik işlemleri gönderildi',
            message: '${pending.length} işlem${vehicle != null ? ' – ${vehicle.name}' : ''}',
            date: DateTime.now(),
            kind: NotificationKind.tire,
          ),
        );
      }
  
      if (!result.success) {"""
content = send_pattern.sub(lambda m: send_replacement, content, count=1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Final fix applied")
