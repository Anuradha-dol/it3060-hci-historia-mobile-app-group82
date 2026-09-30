import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

class GuideResubmitScreen extends StatefulWidget {
  const GuideResubmitScreen({super.key});

  @override
  State<GuideResubmitScreen> createState() => _GuideResubmitScreenState();
}

class _GuideResubmitScreenState extends State<GuideResubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _primaryArea = TextEditingController();
  final _serviceAreas = TextEditingController();
  final _languages = TextEditingController();
  final _experience = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _specialties = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [
      _email,
      _password,
      _displayName,
      _primaryArea,
      _serviceAreas,
      _languages,
      _experience,
      _headline,
      _bio,
      _specialties,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final guide = await AuthService().resubmitGuide(
        data: {
          'email': _email.text.trim(),
          'password': _password.text,
          'displayName': _displayName.text.trim(),
          'primaryServiceArea': _primaryArea.text.trim(),
          'serviceAreas': splitCsv(_serviceAreas.text),
          'languages': splitCsv(_languages.text),
          'yearsExperience': int.tryParse(_experience.text.trim()) ?? 0,
          'headline': _headline.text.trim(),
          'bio': _bio.text.trim(),
          'specialties': splitCsv(_specialties.text),
        },
      );

      if (!mounted) return;
      showAppMessage(context, 'Application resubmitted: ${guide.status}');
      Navigator.pop(context);
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

  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: obscure ? 1 : maxLines,
        decoration: fieldDecoration(label),
        validator: (value) => requiredText(value, label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                HistoriaHeader(
                  title: 'Resubmit application',
                  subtitle:
                      'Update guide details after an admin requests changes.',
                  eyebrow: 'GUIDE APPLICATION',
                  icon: Icons.refresh,
                  actions: [
                    HistoriaIconButton(
                      icon: Icons.close,
                      tooltip: 'Close',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                HistoriaScreenPadding(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HistoriaStatusCard(
                          status: 'NEEDS_WORK',
                          title: 'Needs work resubmission',
                          message:
                              'Only applications currently marked as NEEDS_WORK can use this flow.',
                        ),
                        const SizedBox(height: 14),
                        HistoriaProfileSection(
                          title: 'Account check',
                          children: [
                            _field(
                              'Email',
                              _email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _field('Password', _password, obscure: true),
                          ],
                        ),
                        const SizedBox(height: 14),
                        HistoriaProfileSection(
                          title: 'Updated guide details',
                          children: [
                            _field('Display Name', _displayName),
                            _field('Primary Service Area', _primaryArea),
                            _field(
                              'Service Areas (comma separated)',
                              _serviceAreas,
                            ),
                            _field('Languages (comma separated)', _languages),
                            _field(
                              'Years of Experience',
                              _experience,
                              keyboardType: TextInputType.number,
                            ),
                            _field('Headline', _headline),
                            _field('Bio', _bio, maxLines: 4),
                            _field(
                              'Specialties (comma separated)',
                              _specialties,
                            ),
                            AsyncButton(
                              loading: _loading,
                              onPressed: _submit,
                              label: 'Resubmit Application',
                              icon: Icons.refresh,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
