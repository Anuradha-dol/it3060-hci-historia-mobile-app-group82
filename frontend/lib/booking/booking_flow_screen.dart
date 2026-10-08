import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'booking_models.dart';
import 'booking_provider.dart';
import 'booking_service.dart';
import 'booking_widgets.dart';
import 'guide_tracker_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});
  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int step = 0;
  bool paying = false;
  Future<void> back() async {
    final p = context.read<BookingProvider>();
    if (step == 2 && !await p.releaseHold()) return;
    if (!mounted) return;
    if (step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => step--);
    }
  }

  Future<void> pay(BookingProvider p) async {
    setState(() => paying = true);
    try {
      final contract = await p.service.checkout(p.reservation!.id);
      if (!mounted) return;
      if (!contract.demoEnabled) {
        throw StateError(
          'Live checkout is awaiting member 3 integration. No payment was taken.',
        );
      }
      final result = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Development checkout'),
          content: Text(
            'DEMO ONLY · No money is collected.\n${money(contract.amount)} ${contract.currency}\nChoose a test outcome.',
          ),
          actions: ['success', 'failure', 'cancel']
              .map(
                (o) => TextButton(
                  onPressed: () => Navigator.pop(c, o),
                  child: Text(o.toUpperCase()),
                ),
              )
              .toList(),
        ),
      );
      if (result == null) return;
      final booking = await p.service.pay(contract.bookingId, result);
      p.reservation = booking;
      if (!mounted) return;
      if (booking.active) {
        final owner = context.read<AuthProvider>().user!.id!;
        await BookingCache.save(owner, await p.service.mine());
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GuideTrackerScreen(initial: booking),
          ),
        );
      } else {
        if (result == 'cancel') {
          p.changed();
          if (mounted) setState(() => step = 0);
          await p.loadSlots();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'failure'
                    ? 'Demo payment failed. Retry before the hold expires.'
                    : 'Checkout cancelled. Slot released.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? e.message
                  : ApiService.instance.getErrorMessage(e),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BookingProvider>();
    return BookingShell(
      title: ['Customize visit.', 'Meeting Location', 'Review & pay.'][step],
      subtitle: [
        'Select your preferred tour package and schedule.',
        'Galle Fort UNESCO World Heritage Area',
        'Verify your tour details and proceed to checkout.',
      ][step],
      back: paying ? () {} : back,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          errorNotice(p.error, p.loadSlots),
          if (step == 0) ...[
            const Text(
              'SELECT TOUR PACKAGE',
              style: TextStyle(
                color: bookingGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (p.guide != null)
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 6,
                  children: p.guide!.packages
                      .map(
                        (pack) => SizedBox(
                          width: (constraints.maxWidth - 6) / 2,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => p.selectPackage(pack),
                              child: BookingCard(
                                selected: p.package?.id == pack.id,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      p.package?.id == pack.id
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: bookingGreen,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      pack.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${money(pack.price)}\nper visitor',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: bookingGreen,
                                      ),
                                    ),
                                    const Divider(height: 22),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: bookingGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '${pack.minutes} minutes',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      pack.features,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF758177),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text('${dateKey(p.date)} · Sri Lanka'),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: p.date,
                  firstDate: colomboNow(),
                  lastDate: colomboNow().add(const Duration(days: 365)),
                );
                if (d != null) await p.selectDate(d);
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'TIME SLOTS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: bookingGreen,
              ),
            ),
            if (p.loadingSlots)
              const LinearProgressIndicator()
            else if (p.slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('No available slots. Choose another date.'),
              )
            else
              Wrap(
                spacing: 8,
                children: p.slots
                    .map(
                      (s) => ChoiceChip(
                        label: Text(schedule(s).substring(12, 17)),
                        selected: p.slot == s,
                        onSelected: (_) => p.selectSlot(s),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            BookingCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Visitor stepper\nStandard admission',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fewer visitors',
                    onPressed: p.package == null || p.visitors <= p.package!.min
                        ? null
                        : () => p.count(p.visitors - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${p.visitors}'),
                  IconButton(
                    tooltip: 'More visitors',
                    onPressed: p.package == null || p.visitors >= p.package!.max
                        ? null
                        : () => p.count(p.visitors + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            detailRow(
              'Subtotal (${p.visitors} × ${money(p.package?.price ?? 0)})',
              money(p.subtotal),
            ),
            bookingButton(
              'Review booking details',
              p.slot == null || p.loadingSlots
                  ? null
                  : () => setState(() => step = 1),
            ),
          ],
          if (step == 1) ...[
            Wrap(
              spacing: 6,
              children: p.landmarks
                  .map(
                    (l) => ChoiceChip(
                      label: Text(l.name, style: const TextStyle(fontSize: 11)),
                      selected: p.meeting?.id == l.id,
                      onSelected: (_) => p.selectMeeting(l),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (p.meeting != null) ...[
              BookingCard(child: MeetingMap(landmark: p.meeting!)),
              BookingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHECKPOINT DESIGNATED',
                      style: TextStyle(fontSize: 10, color: bookingGreen),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.meeting!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(p.meeting!.description),
                    detailRow('Assigned guide', p.guide!.name),
                    detailRow('Meeting time', schedule(p.slot!)),
                    detailRow('Access information', p.meeting!.access),
                  ],
                ),
              ),
            ],
            bookingButton(
              p.busy ? 'Reserving…' : '✓  Confirm Meeting Point',
              p.busy || p.meeting == null
                  ? null
                  : () async {
                      if (await p.createHold() && mounted) {
                        setState(() => step = 2);
                      }
                    },
            ),
          ],
          if (step == 2 && p.reservation != null) ...[
            BookingCard(
              child: Column(
                children: [
                  detailRow('BOOKING SUMMARY', p.reservation!.reference),
                  MeetingMap(landmark: p.reservation!.landmark),
                  detailRow('Tour package', p.reservation!.json['packageName']),
                  detailRow('Assigned guide', p.reservation!.guide),
                  detailRow(
                    'Schedule',
                    schedule(p.reservation!.json['startsAt']),
                  ),
                  detailRow(
                    'Party size',
                    '${p.reservation!.json['visitors']} visitors',
                  ),
                  const Divider(),
                  detailRow(
                    'Total payable',
                    money(p.reservation!.json['amount']),
                  ),
                ],
              ),
            ),
            Text(
              'Slot held until ${schedule(p.reservation!.json['holdExpiresAt'])}',
              style: const TextStyle(fontSize: 12),
            ),
            bookingButton(
              paying ? 'Opening checkout…' : 'Pay Now  →',
              paying ? null : () => pay(p),
            ),
            Text(
              p.reservation!.json['demoPaymentEnabled'] == true
                  ? 'Development checkout · no real payment'
                  : 'Payment handoff requires the teammate gateway integration.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF758177)),
            ),
          ],
        ],
      ),
    );
  }
}
