import 'package:flutter/material.dart';

import '../models/guide_model.dart';
import '../services/api_service.dart';
import '../services/guide_service.dart';
import '../theme/app_text_styles.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

class ApprovedGuidesScreen extends StatelessWidget {
  const ApprovedGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: ApprovedGuidesContent(standalone: true)),
    );
  }
}

class ApprovedGuidesContent extends StatefulWidget {
  final bool standalone;

  const ApprovedGuidesContent({super.key, this.standalone = false});

  @override
  State<ApprovedGuidesContent> createState() => _ApprovedGuidesContentState();
}

class _ApprovedGuidesContentState extends State<ApprovedGuidesContent> {
  final _area = TextEditingController();
  List<GuideModel> _guides = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_area.text.trim().isEmpty) {
      showAppMessage(context, 'Area is required.', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final guides = await GuideService().getApprovedGuides(
        area: _area.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _guides = guides;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HistoriaHeader(
          title: 'Find local guides',
          subtitle: 'Search approved HISTORIA guides by service area.',
          eyebrow: 'TOURIST DISCOVERY',
          icon: Icons.travel_explore,
          actions: [
            if (widget.standalone)
              HistoriaIconButton(
                icon: Icons.close,
                tooltip: 'Close',
                onPressed: () => Navigator.maybePop(context),
              ),
          ],
        ),
        HistoriaScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HistoriaInfoBox(
                title: 'Approved guide search',
                message:
                    'Only guides approved by an admin are returned from the backend.',
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 14),
              HistoriaTextField(
                label: 'Service area',
                hintText: 'Anuradhapura, Kandy, Galle',
                controller: _area,
                icon: Icons.map_outlined,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
              ),
              HistoriaButton(
                loading: _loading,
                onPressed: _search,
                icon: Icons.search,
                label: 'Search Guides',
              ),
              const SizedBox(height: 18),
              HistoriaSectionHeader(
                title: 'Guide results',
                subtitle: _searched
                    ? '${_guides.length} approved guide result(s)'
                    : 'Search by city or heritage area.',
              ),
              if (!_searched)
                const HistoriaEmptyState(
                  icon: Icons.search,
                  title: 'Start with a service area',
                  message: 'Try places such as Anuradhapura, Kandy, or Galle.',
                )
              else if (_guides.isEmpty)
                const HistoriaEmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No approved guides found',
                  message:
                      'Try another area or check again after admins approve more guides.',
                )
              else
                ..._guides.map(_guideCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guideCard(GuideModel guide) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HistoriaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guide.title, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 4),
                      Text(guide.email, style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ),
                const HistoriaStatusChip(status: 'APPROVED'),
              ],
            ),
            const SizedBox(height: 12),
            HistoriaListTile(
              icon: Icons.map_outlined,
              title: 'Primary area',
              subtitle: guide.primaryServiceArea,
            ),
            HistoriaListTile(
              icon: Icons.translate_outlined,
              title: 'Languages',
              subtitle: guide.languages.isEmpty
                  ? 'Not provided'
                  : guide.languages.join(', '),
            ),
            if (guide.specialties.isNotEmpty)
              HistoriaListTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Specialties',
                subtitle: guide.specialties.join(', '),
              ),
            if (guide.bio != null && guide.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(guide.bio!, style: AppTextStyles.bodyMuted),
              ),
          ],
        ),
      ),
    );
  }
}
