import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'booking_models.dart';
import 'booking_service.dart';
import 'booking_provider.dart';
import 'booking_widgets.dart';
import 'booking_flow_screen.dart';
import 'my_bookings_screen.dart';

class GuideDirectoryScreen extends StatefulWidget {
  final String initialArea;

  const GuideDirectoryScreen({
    super.key,
    this.initialArea = 'Galle Fort',
  });

  @override
  State<GuideDirectoryScreen> createState() => _GuideDirectoryScreenState();
}

class _GuideDirectoryScreenState extends State<GuideDirectoryScreen> {
  late final TextEditingController search;
  late final TextEditingController area;
  late final TextEditingController specialty;
  final service = BookingService();
  List<BookableGuide> guides = [];
  String? error, language;
  bool busy = true, certified = false, rated = false, available = false;
  DateTime date = colomboNow();
  TimeOfDay? time;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    search = TextEditingController();
    area = TextEditingController(text: widget.initialArea);
    specialty = TextEditingController();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    area.dispose();
    specialty.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final request = ++generation;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await service.guides({
        'q': search.text.trim(),
        'area': area.text.trim(),
        'specialty': specialty.text.trim(),
        'language': language ?? '',
        'certified': certified,
        if (rated) 'rating': 4.8,
        'date': dateKey(date),
        if (time != null)
          'at': DateTime.parse(
            '${dateKey(date)}T${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}:00+05:30',
          ).toUtc().toIso8601String(),
      });
      if (mounted && request == generation) setState(() => guides = result);
    } catch (e) {
      if (mounted && request == generation) {
        setState(() => error = ApiService.instance.getErrorMessage(e));
      }
    } finally {
      if (mounted && request == generation) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = guides.where((g) => !available || g.available).toList();
    return BookingShell(
      title: 'Find a guide.',
      subtitle:
          'HISTORICAL SITE: ${area.text}\nChoose a local guide for your walking tour.',
      actions: [
        IconButton(
          tooltip: 'My guide bookings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
          ),
          icon: const Icon(Icons.event_note),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: search,
            onSubmitted: (_) => load(),
            decoration: InputDecoration(
              hintText: 'Guide name or historical interest…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: load,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Chip(label: Text('All Guides (${shown.length})')),
              FilterChip(
                label: const Text('Certified'),
                selected: certified,
                onSelected: (v) {
                  setState(() => certified = v);
                  load();
                },
              ),
              FilterChip(
                label: const Text('Top rated 4.8+'),
                selected: rated,
                onSelected: (v) {
                  setState(() => rated = v);
                  load();
                },
              ),
              FilterChip(
                label: const Text('Available'),
                selected: available,
                onSelected: (v) => setState(() => available = v),
              ),
              ...['English', 'Sinhala', 'Tamil'].map(
                (l) => FilterChip(
                  label: Text(l),
                  selected: language == l,
                  onSelected: (v) {
                    setState(() => language = v ? l : null);
                    load();
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Schedule & filters · ${dateKey(date)}',
              style: const TextStyle(fontSize: 13),
            ),
            children: [
              TextField(
                controller: area,
                decoration: const InputDecoration(labelText: 'Service area'),
                onSubmitted: (_) => load(),
              ),
              TextField(
                controller: specialty,
                decoration: const InputDecoration(labelText: 'Specialty'),
                onSubmitted: (_) => load(),
              ),
              Wrap(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateKey(date)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: colomboNow(),
                        lastDate: colomboNow().add(const Duration(days: 365)),
                      );
                      if (d != null && mounted) {
                        setState(() => date = d);
                        load();
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime:
                            time ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (t != null && mounted) {
                        setState(() => time = t);
                        load();
                      }
                    },
                    child: Text(time?.format(context) ?? 'Any time'),
                  ),
                  if (time != null)
                    TextButton(
                      onPressed: () {
                        setState(() => time = null);
                        load();
                      },
                      child: const Text('Clear time'),
                    ),
                ],
              ),
              bookingButton('Apply filters', load),
            ],
          ),
          errorNotice(error, load),
          if (busy)
            const Center(child: CircularProgressIndicator())
          else if (error == null && shown.isEmpty)
            const BookingCard(
              child: Text(
                'No eligible guides match these filters. Try another date or service area.',
              ),
            )
          else
            ...shown.map(
              (g) => BookingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFEAF3ED),
                          child: Text(g.name.isEmpty ? '?' : g.name[0]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            g.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: g.languages
                          .map(
                            (l) => Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                l,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    Text(
                      '${g.json['yearsExperience']} years experience · ${(g.json['specialties'] as List).join(' · ')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      g.json['demo'] == true
                          ? 'DEMO listing · sample certification & rating'
                          : g.json['certified'] == true
                          ? 'Verified certification'
                          : 'Certification not supplied',
                      style: const TextStyle(fontSize: 12, color: bookingGreen),
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          g.json['rating'] == null
                              ? 'No ratings yet'
                              : '★ ${g.json['rating']} (${g.json['reviewCount']} reviews)',
                        ),
                        Text(
                          g.available
                              ? 'Slots available'
                              : 'No slots on selected schedule',
                          style: const TextStyle(
                            color: bookingGreen,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      g.packages.isEmpty
                          ? 'Packages not configured'
                          : 'From ${money(g.packages.map((p) => p.price).reduce((a, b) => a < b ? a : b))} / visitor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bookingGreen,
                      ),
                    ),
                    bookingButton(
                      'Select Guide  →',
                      g.packages.isEmpty
                          ? null
                          : () {
                              final state = BookingProvider()..date = date;
                              state.selectGuide(g);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider(
                                    create: (_) => state,
                                    child: const BookingFlowScreen(),
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
