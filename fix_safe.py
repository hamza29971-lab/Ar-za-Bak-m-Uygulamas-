import os
import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\tire_change_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Imports
content = content.replace("import '../../services/publish_service.dart';", "import '../../services/publish_service.dart';\nimport '../../models/models.dart' as global_models;")

# 2. Autofocus
content = content.replace("autofocus: true,", "autofocus: false,")

# 3. Popup Confirmation
pattern1 = re.compile(r'(Future<void> _sendPending\([^)]+\)\s*async\s*\{)(\s*final List<PendingOperation> pending [^\n]+;)', re.DOTALL)
repl1 = r"""\1
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Emin misiniz?'),
          content: const Text('Bekleyen tüm işlemleri göndermek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF198754)),
              child: const Text('Evet, Gönder'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
\2"""
content = pattern1.sub(repl1, content, count=1)

# 4. _submit activity
pattern2 = re.compile(r"state\.addPending\(PendingOperation\([\s\S]*?\}\,\s*\)\);", re.DOTALL)
repl2 = """state.addPending(PendingOperation(
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
            global_models.ServiceReportActivity(
              id: 'tire-check-${DateTime.now().microsecondsSinceEpoch}',
              vehicleCode: vehicle.name,
              date: DateTime.now(),
              reportType: 'Lastik Kontrolü',
              description: actions.join('\\n'),
              imagePaths: [],
            )
          );"""
content = pattern2.sub(lambda m: repl2, content, count=1)

# 5. _sendPending notification
pattern3 = re.compile(r"setState\(\(\) => _sending = false\);\s*if \(\!result\.success\) \{", re.DOTALL)
repl3 = """setState(() => _sending = false);
  
      if (result.success) {
        state.addNotification(
          global_models.NotificationItem(
            title: 'Lastik işlemleri gönderildi',
            message: '${pending.length} işlem${vehicle != null ? ' – ${vehicle.name}' : ''}',
            date: DateTime.now(),
            kind: global_models.NotificationKind.tire,
          ),
        );
      }
  
      if (!result.success) {"""
content = pattern3.sub(lambda m: repl3, content, count=1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Safe fix applied to tire_change_screen.dart")
