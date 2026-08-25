# -*- coding: utf-8 -*-
import re

file_path = r'C:\new class\nimo_ariza_bakim\lib\ui\screens\tire_change_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """              child: provider.selectedVehicle == null
                  ? const EmptyState(
                      icon: Icons.tire_repair_outlined,
                      title: 'Araç seçilmedi',
                      message: 'Lastik kayıtlarını görmek için yukarıdaki "Araç Seç" alanından bir araç seçin.',
                    )
                  : Column(
                      children: [
                        // Tablo başlıkları
                        const _TableHeader(),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F5)),
                        // Tablo satırları
                        Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: provider.tireRecords.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFEEF0F5),
                      ),
                      itemBuilder: (context, index) {
                        final record = provider.tireRecords[index];
                        final isEditing =
                            provider.editingTireNumber == record.tireNumber;
                        return _TireRow(
                          record: record,
                          isEditing: isEditing,
                        );
                      },
                    ),
                  ),
                ],
              ),"""

replacement = """              child: Column(
                children: [
                  const _TableHeader(),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F5)),
                  Expanded(
                    child: provider.selectedVehicle == null
                        ? const Center(
                            child: EmptyState(
                              icon: Icons.tire_repair_outlined,
                              title: 'Araç seçilmedi',
                              message: 'Lastik kayıtlarını görmek için yukarıdaki "Araç Seç" alanından bir araç seçin.',
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: provider.tireRecords.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFEEF0F5),
                            ),
                            itemBuilder: (context, index) {
                              final record = provider.tireRecords[index];
                              final isEditing =
                                  provider.editingTireNumber == record.tireNumber;
                              return _TireRow(
                                record: record,
                                isEditing: isEditing,
                              );
                            },
                          ),
                  ),
                ],
              ),"""

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Success')
else:
    print('Target not found')
