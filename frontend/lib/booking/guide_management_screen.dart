import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'booking_models.dart';
import 'booking_service.dart';
import 'booking_widgets.dart';

class GuideManagementScreen extends StatefulWidget {
  const GuideManagementScreen({super.key});
  @override
  State<GuideManagementScreen> createState() => _GuideManagementScreenState();
}

class _GuideManagementScreenState extends State<GuideManagementScreen> {
  final service = BookingService();
  Json data = {};
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await service.management();
      if (mounted) {
        setState(() {
          data = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = ApiService.instance.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([Json? package]) async {
    final name = TextEditingController(text: package?['name'] ?? ''),
        price = TextEditingController(
          text: '${package?['pricePerVisitor'] ?? 2500}',
        ),
        minutes = TextEditingController(
          text: '${package?['durationMinutes'] ?? 120}',
        ),
        min = TextEditingController(text: '${package?['minVisitors'] ?? 1}'),
        max = TextEditingController(text: '${package?['maxVisitors'] ?? 10}'),
        features = TextEditingController(text: package?['features'] ?? '');
    bool enabled = package?['enabled'] ?? true;
    final form = GlobalKey<FormState>();
    final result = await showDialog<Json>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(package == null ? 'Add package' : 'Edit package'),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Package name',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  TextFormField(
                    controller: features,
                    decoration: const InputDecoration(labelText: 'Features'),
                  ),
                  for (final entry in {
                    price: 'LKR per visitor',
                    minutes: 'Duration in minutes',
                    min: 'Minimum visitors',
                    max: 'Maximum visitors',
                  }.entries)
                    TextFormField(
                      controller: entry.key,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: entry.value),
                      validator: (v) =>
                          num.tryParse(v ?? '') == null || num.parse(v!) <= 0
                          ? 'Enter a positive number'
                          : null,
                    ),
                  SwitchListTile(
                    title: const Text('Accept bookings'),
                    value: enabled,
                    onChanged: (v) => set(() => enabled = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  if (int.tryParse(minutes.text) == null ||
                      int.tryParse(min.text) == null ||
                      int.tryParse(max.text) == null) {
                    return;
                  }
                  Navigator.pop(c, {
                    'id': package?['id'],
                    'name': name.text.trim(),
                    'features': features.text.trim(),
                    'pricePerVisitor': num.parse(price.text),
                    'durationMinutes': int.parse(minutes.text),
                    'minVisitors': int.parse(min.text),
                    'maxVisitors': int.parse(max.text),
                    'enabled': enabled,
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    // Dialog controllers are disposed after its closing animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final controller in [name, price, minutes, min, max, features]) {
      controller.dispose();
    }
    if (result != null) {
      try {
        await service.savePackage(result);
        await load();
      } catch (e) {
        if (mounted) {
          setState(() => error = ApiService.instance.getErrorMessage(e));
        }
      }
    }
  }

  Future<void> window() async {
    final day = await showDatePicker(
      context: context,
      firstDate: colomboNow(),
      lastDate: colomboNow().add(const Duration(days: 365)),
      initialDate: colomboNow(),
    );
    if (day == null || !mounted) return;
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (end == null) return;
    String stamp(TimeOfDay t) =>
        '${dateKey(day)}T${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00+05:30';
    try {
      await service.addWindow({'startsAt': stamp(start), 'endsAt': stamp(end)});
      await load();
    } catch (e) {
      if (mounted) {
        setState(() => error = ApiService.instance.getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => BookingShell(
    title: 'Packages & schedule',
    subtitle: 'Prices are per visitor. Schedules use Sri Lanka time.',
    nav: false,
    child: Column(
      children: [
        errorNotice(error, load),
        if (busy) const CircularProgressIndicator(),
        ...(data['packages'] as List? ?? []).map(
          (p) => BookingCard(
            child: Column(
              children: [
                detailRow(
                  p['name'],
                  '${money(p['pricePerVisitor'])} / visitor',
                ),
                Text(
                  '${p['durationMinutes']} minutes · ${p['minVisitors']}–${p['maxVisitors']} visitors · ${p['enabled'] ? 'Enabled' : 'Disabled'}',
                ),
                TextButton(
                  onPressed: () => edit(Json.from(p)),
                  child: const Text('Edit package'),
                ),
              ],
            ),
          ),
        ),
        bookingButton('Add package', () => edit()),
        const Divider(),
        bookingButton('Add availability window', window),
        ...(data['windows'] as List? ?? []).map(
          (w) => ListTile(
            title: Text(schedule(w['startsAt'])),
            subtitle: Text('Until ${schedule(w['endsAt'])}'),
            trailing: IconButton(
              tooltip: 'Remove availability (keeps existing bookings)',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                try {
                  await service.deleteWindow(w['id']);
                  await load();
                } catch (e) {
                  if (mounted) {
                    setState(
                      () => error = ApiService.instance.getErrorMessage(e),
                    );
                  }
                }
              },
            ),
          ),
        ),
      ],
    ),
  );
}
