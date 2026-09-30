import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

class GuideResubmitScreen extends StatefulWidget {
  const GuideResubmitScreen({super.key});

  @override
  State<GuideResubmitScreen> createState() =>
      _GuideResubmitScreenState();
}

class _GuideResubmitScreenState extends State<GuideResubmitScreen> {
  final _stepKeys = List.generate(
    4,
        (_) => GlobalKey<FormState>(),
  );

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

  int _step = 0;

  bool _loading = false;
  bool _hidePassword = true;

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

  // ================================================================
  // CONTINUE
  // ================================================================

  void _continue() {
    if (_step < 3) {
      final form = _stepKeys[_step].currentState;

      if (form != null && !form.validate()) {
        return;
      }

      setState(() {
        _step += 1;
      });

      return;
    }

    _submit();
  }

  // ================================================================
  // BACK
  // ================================================================

  void _back() {
    if (_step > 0) {
      setState(() {
        _step -= 1;
      });

      return;
    }

    Navigator.maybePop(context);
  }

  // ================================================================
  // SUBMIT
  // ================================================================

  Future<void> _submit() async {
    if (!_validateAllFields()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final guide = await AuthService().resubmitGuide(
        data: {
          'email': _email.text.trim(),
          'password': _password.text,
          'displayName': _displayName.text.trim(),
          'primaryServiceArea': _primaryArea.text.trim(),
          'serviceAreas': splitCsv(
            _serviceAreas.text,
          ),
          'languages': splitCsv(
            _languages.text,
          ),
          'yearsExperience':
          int.tryParse(
            _experience.text.trim(),
          ) ??
              0,
          'headline': _headline.text.trim(),
          'bio': _bio.text.trim(),
          'specialties': splitCsv(
            _specialties.text,
          ),
        },
      );

      if (!mounted) return;

      showAppMessage(
        context,
        'Application resubmitted: ${guide.status}',
      );

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
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ================================================================
  // VALIDATION
  // ================================================================

  bool _validateAllFields() {
    final values = [
      _email.text,
      _password.text,
      _displayName.text,
      _primaryArea.text,
      _serviceAreas.text,
      _languages.text,
      _experience.text,
      _headline.text,
      _bio.text,
      _specialties.text,
    ];

    if (values.any(
          (value) => value.trim().isEmpty,
    )) {
      showAppMessage(
        context,
        'Complete all required fields.',
        error: true,
      );

      return false;
    }

    if (int.tryParse(
      _experience.text.trim(),
    ) ==
        null) {
      showAppMessage(
        context,
        'Years of experience must be a number.',
        error: true,
      );

      setState(() {
        _step = 2;
      });

      return false;
    }

    return true;
  }

  String? _required(
      String? value,
      String label,
      ) {
    return requiredText(
      value,
      label,
    );
  }

  String? _experienceValidator(
      String? value,
      ) {
    final required = _required(
      value,
      'Years of experience',
    );

    if (required != null) {
      return required;
    }

    if (int.tryParse(
      value!.trim(),
    ) ==
        null) {
      return 'Enter a valid number';
    }

    return null;
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final keyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    final titles = [
      'Confirm your account.',
      'Update service details.',
      'Refresh your guide profile.',
      'Review and resubmit.',
    ];

    final subtitles = [
      'Confirm the guide account that needs changes.',
      'Update where you guide and the languages you support.',
      'Update your experience and traveller-facing profile.',
      'Check your changes before sending them for review.',
    ];

    return PopScope(
      canPop: _step == 0,

      onPopInvokedWithResult: (
          didPop,
          _,
          ) {
        if (!didPop && _step > 0) {
          _back();
        }
      },

      child: Scaffold(
        resizeToAvoidBottomInset: true,

        backgroundColor:
        const Color(0xFFF0F7F3),

        body: Stack(
          children: [
            // ========================================================
            // BACKGROUND
            // ========================================================

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF9FCF9),
                    Color(0xFFF1F8F4),
                    Color(0xFFEAF5EF),
                  ],
                ),
              ),
            ),

            // ========================================================
            // BACKGROUND CIRCLE 1
            // ========================================================

            Positioned(
              top: 120,
              right: -80,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFFD3EBDD,
                  ).withValues(
                    alpha: 0.28,
                  ),
                ),
              ),
            ),

            // ========================================================
            // BACKGROUND CIRCLE 2
            // ========================================================

            Positioned(
              top: 350,
              left: -95,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFFDDEFE5,
                  ).withValues(
                    alpha: 0.24,
                  ),
                ),
              ),
            ),

            // ========================================================
            // PAGE
            // ========================================================

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 430,
                  ),

                  child: Column(
                    children: [
                      // =================================================
                      // HEADER
                      // =================================================

                      HistoriaHeader(
                        title: titles[_step],

                        subtitle:
                        subtitles[_step],

                        eyebrow:
                        'GUIDE RESUBMISSION · STEP ${(_step + 1).toString().padLeft(2, '0')} OF 04',

                        icon:
                        Icons.refresh_rounded,

                        actions: [
                          HistoriaIconButton(
                            icon: _step == 0
                                ? Icons.close
                                : Icons.arrow_back,

                            tooltip: _step == 0
                                ? 'Close'
                                : 'Back',

                            onPressed: _back,
                          ),
                        ],
                      ),

                      // =================================================
                      // BODY - NO SCROLL
                      // =================================================

                      Expanded(
                        child: Padding(
                          padding:
                          const EdgeInsets.fromLTRB(
                            17,
                            7,
                            17,
                            5,
                          ),

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,

                            children: [
                              // =========================================
                              // PROGRESS
                              // =========================================

                              HistoriaProgressStepper(
                                currentStep:
                                _step,
                                labels:
                                const [
                                  'Account',
                                  'Service',
                                  'Profile',
                                  'Review',
                                ],
                              ),

                              const SizedBox(
                                height: 7,
                              ),

                              // =========================================
                              // AVAILABLE FORM SPACE
                              // =========================================

                              Expanded(
                                child:
                                LayoutBuilder(
                                  builder: (
                                      context,
                                      constraints,
                                      ) {
                                    return FittedBox(
                                      fit:
                                      BoxFit.scaleDown,

                                      alignment:
                                      Alignment.topCenter,

                                      child:
                                      SizedBox(
                                        width:
                                        constraints.maxWidth,

                                        child:
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .stretch,

                                          children: [
                                            // =============================
                                            // NEEDS WORK CARD
                                            // =============================

                                            if (_step ==
                                                0)
                                              const _NeedsWorkCard(),

                                            if (_step ==
                                                0)
                                              const SizedBox(
                                                height:
                                                8,
                                              ),

                                            // =============================
                                            // MAIN STEP CARD
                                            // =============================

                                            Container(
                                              padding:
                                              const EdgeInsets
                                                  .fromLTRB(
                                                13,
                                                11,
                                                13,
                                                10,
                                              ),

                                              decoration:
                                              BoxDecoration(
                                                gradient:
                                                const LinearGradient(
                                                  begin:
                                                  Alignment.topLeft,
                                                  end:
                                                  Alignment.bottomRight,
                                                  colors: [
                                                    Color(
                                                      0xFFF7FBF8,
                                                    ),
                                                    Color(
                                                      0xFFECF6F0,
                                                    ),
                                                  ],
                                                ),

                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                  16,
                                                ),

                                                border:
                                                Border.all(
                                                  color:
                                                  const Color(
                                                    0xFFCFE3D8,
                                                  ),
                                                ),

                                                boxShadow:
                                                const [
                                                  BoxShadow(
                                                    color:
                                                    Color(
                                                      0x09123F30,
                                                    ),
                                                    blurRadius:
                                                    10,
                                                    offset:
                                                    Offset(
                                                      0,
                                                      3,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              child:
                                              Form(
                                                key:
                                                _stepKeys[
                                                _step],

                                                child:
                                                AnimatedSwitcher(
                                                  duration:
                                                  const Duration(
                                                    milliseconds:
                                                    180,
                                                  ),

                                                  switchInCurve:
                                                  Curves
                                                      .easeOut,

                                                  switchOutCurve:
                                                  Curves
                                                      .easeIn,

                                                  child:
                                                  KeyedSubtree(
                                                    key:
                                                    ValueKey(
                                                      _step,
                                                    ),

                                                    child:
                                                    _stepContent(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // =================================================
                      // FOOTER
                      //
                      // NO TEXT ABOVE FOOTER.
                      // =================================================

                      if (!keyboardOpen)
                        const _ResubmitFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // STEP ROUTER
  // ================================================================

  Widget _stepContent() {
    switch (_step) {
      case 1:
        return _serviceStep();

      case 2:
        return _profileStep();

      case 3:
        return _reviewStep();

      case 0:
      default:
        return _accountStep();
    }
  }

  // ================================================================
  // STEP 01 - ACCOUNT
  // ================================================================

  Widget _accountStep() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,

      children: [
        const _SectionHeading(
          icon:
          Icons.lock_person_outlined,

          title:
          'Account check',

          subtitle:
          'Use the email and password linked to your guide account.',
        ),

        const SizedBox(
          height: 9,
        ),

        HistoriaTextField(
          label:
          'Email address',

          hintText:
          'guide@example.com',

          controller:
          _email,

          icon:
          Icons.email_outlined,

          keyboardType:
          TextInputType.emailAddress,

          required:
          true,

          validator:
              (value) {
            return _required(
              value,
              'Email address',
            );
          },
        ),

        HistoriaTextField(
          label:
          'Password',

          hintText:
          'Enter your password',

          controller:
          _password,

          icon:
          Icons.lock_outline,

          obscureText:
          _hidePassword,

          required:
          true,

          validator:
              (value) {
            return _required(
              value,
              'Password',
            );
          },

          suffix:
          HistoriaPasswordSuffix(
            hidden:
            _hidePassword,

            onPressed:
                () {
              setState(() {
                _hidePassword =
                !_hidePassword;
              });
            },
          ),
        ),

        const SizedBox(
          height: 9,
        ),

        HistoriaButton(
          loading:
          _loading,

          onPressed:
          _continue,

          label:
          'Continue',

          icon:
          Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  // ================================================================
  // STEP 02 - SERVICE
  // ================================================================

  Widget _serviceStep() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,

      children: [
        const _SectionHeading(
          icon:
          Icons.map_outlined,

          title:
          'Service details',

          subtitle:
          'Update your public name, locations and supported languages.',
        ),

        const SizedBox(
          height: 9,
        ),

        _field(
          label:
          'Display Name',

          hint:
          'Name shown to travellers',

          controller:
          _displayName,

          icon:
          Icons.badge_outlined,
        ),

        _field(
          label:
          'Primary Service Area',

          hint:
          'Galle',

          controller:
          _primaryArea,

          icon:
          Icons.location_on_outlined,
        ),

        _field(
          label:
          'Service Areas',

          hint:
          'Galle, Kandy, Anuradhapura',

          controller:
          _serviceAreas,

          icon:
          Icons.route_outlined,
        ),

        _field(
          label:
          'Languages',

          hint:
          'English, Sinhala, Tamil',

          controller:
          _languages,

          icon:
          Icons.translate_outlined,
        ),

        const SizedBox(
          height: 9,
        ),

        HistoriaButton(
          loading:
          _loading,

          onPressed:
          _continue,

          label:
          'Continue',

          icon:
          Icons.arrow_forward_rounded,
        ),

        TextButton(
          onPressed:
          _loading
              ? null
              : _back,

          child:
          const Text(
            'Back to account check',
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STEP 03 - PROFILE
  // ================================================================

  Widget _profileStep() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,

      children: [
        const _SectionHeading(
          icon:
          Icons.person_outline,

          title:
          'Guide profile',

          subtitle:
          'Update your experience, headline, bio and specialties.',
        ),

        const SizedBox(
          height: 9,
        ),

        _field(
          label:
          'Years of Experience',

          hint:
          '3',

          controller:
          _experience,

          icon:
          Icons.history_edu_outlined,

          keyboardType:
          TextInputType.number,

          validator:
          _experienceValidator,
        ),

        _field(
          label:
          'Headline',

          hint:
          'Discover history with a local guide',

          controller:
          _headline,

          icon:
          Icons.short_text,
        ),

        _field(
          label:
          'Bio',

          hint:
          'Tell travellers about yourself and your guiding experience.',

          controller:
          _bio,

          icon:
          Icons.notes_outlined,

          maxLines:
          3,
        ),

        _field(
          label:
          'Specialties',

          hint:
          'Ancient cities, temples, local food',

          controller:
          _specialties,

          icon:
          Icons.workspace_premium_outlined,
        ),

        const SizedBox(
          height: 9,
        ),

        HistoriaButton(
          loading:
          _loading,

          onPressed:
          _continue,

          label:
          'Review changes',

          icon:
          Icons.fact_check_outlined,
        ),

        TextButton(
          onPressed:
          _loading
              ? null
              : _back,

          child:
          const Text(
            'Back to service details',
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STEP 04 - REVIEW
  // ================================================================

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,

      children: [
        const _SectionHeading(
          icon:
          Icons.fact_check_outlined,

          title:
          'Review changes',

          subtitle:
          'Confirm the updated information before resubmission.',
        ),

        const SizedBox(
          height: 9,
        ),

        _ReviewCard(
          title:
          'Account',

          icon:
          Icons.lock_person_outlined,

          rows: [
            _ReviewData(
              'Email',
              _email.text.trim(),
            ),
          ],
        ),

        const SizedBox(
          height: 6,
        ),

        _ReviewCard(
          title:
          'Service details',

          icon:
          Icons.map_outlined,

          rows: [
            _ReviewData(
              'Display name',
              _displayName.text.trim(),
            ),

            _ReviewData(
              'Primary area',
              _primaryArea.text.trim(),
            ),

            _ReviewData(
              'Service areas',
              _serviceAreas.text.trim(),
            ),

            _ReviewData(
              'Languages',
              _languages.text.trim(),
            ),
          ],
        ),

        const SizedBox(
          height: 6,
        ),

        _ReviewCard(
          title:
          'Guide profile',

          icon:
          Icons.person_outline,

          rows: [
            _ReviewData(
              'Experience',
              '${_experience.text.trim()} years',
            ),

            _ReviewData(
              'Headline',
              _headline.text.trim(),
            ),

            _ReviewData(
              'Specialties',
              _specialties.text.trim(),
            ),
          ],
        ),

        const SizedBox(
          height: 9,
        ),

        const HistoriaInfoBox(
          title:
          'Admin review',

          message:
          'After resubmission, your guide application will return to the admin review queue.',

          icon:
          Icons.admin_panel_settings_outlined,
        ),

        const SizedBox(
          height: 10,
        ),

        HistoriaButton(
          loading:
          _loading,

          onPressed:
          _submit,

          label:
          'Resubmit Application',

          icon:
          Icons.refresh_rounded,
        ),

        TextButton(
          onPressed:
          _loading
              ? null
              : _back,

          child:
          const Text(
            'Back to guide profile',
          ),
        ),
      ],
    );
  }

  // ================================================================
  // COMMON FIELD
  // ================================================================

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return HistoriaTextField(
      label:
      label,

      hintText:
      hint,

      controller:
      controller,

      icon:
      icon,

      keyboardType:
      keyboardType,

      maxLines:
      maxLines,

      required:
      true,

      validator:
      validator ??
              (value) {
            return _required(
              value,
              label,
            );
          },
    );
  }
}

// =====================================================================
// NEEDS WORK CARD
// =====================================================================

class _NeedsWorkCard
    extends StatelessWidget {
  const _NeedsWorkCard();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        11,
      ),

      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(
              0xFFFFFAEC,
            ),
            Color(
              0xFFFFF1D4,
            ),
          ],
        ),

        borderRadius:
        BorderRadius.circular(
          15,
        ),

        border:
        Border.all(
          color:
          const Color(
            0xFFF0DDAA,
          ),
        ),
      ),

      child:
      const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          CircleAvatar(
            radius:
            20,

            backgroundColor:
            Color(
              0xFFFFE6A7,
            ),

            child:
            Icon(
              Icons.edit_note_rounded,

              color:
              Color(
                0xFFC97900,
              ),

              size:
              22,
            ),
          ),

          SizedBox(
            width:
            10,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  'NEEDS WORK',

                  style:
                  TextStyle(
                    color:
                    Color(
                      0xFFA76700,
                    ),

                    fontSize:
                    8.3,

                    fontWeight:
                    FontWeight.w800,

                    letterSpacing:
                    0.7,
                  ),
                ),

                SizedBox(
                  height:
                  3,
                ),

                Text(
                  'Update requested details',

                  style:
                  TextStyle(
                    color:
                    Color(
                      0xFF4B3D1D,
                    ),

                    fontSize:
                    12.2,

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height:
                  3,
                ),

                Text(
                  'Make the requested changes and send your guide application back for review.',

                  style:
                  TextStyle(
                    color:
                    Color(
                      0xFF74684D,
                    ),

                    fontSize:
                    9.3,

                    height:
                    1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SECTION HEADING
// =====================================================================

class _SectionHeading
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Container(
          width:
          38,

          height:
          38,

          decoration:
          const BoxDecoration(
            color:
            Color(
              0xFFDDEFE5,
            ),

            shape:
            BoxShape.circle,
          ),

          child:
          Icon(
            icon,

            color:
            const Color(
              0xFF1D7452,
            ),

            size:
            20,
          ),
        ),

        const SizedBox(
          width:
          10,
        ),

        Expanded(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style:
                const TextStyle(
                  color:
                  Color(
                    0xFF123F32,
                  ),

                  fontSize:
                  13,

                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height:
                2,
              ),

              Text(
                subtitle,

                style:
                const TextStyle(
                  color:
                  Color(
                    0xFF6A7C73,
                  ),

                  fontSize:
                  9.4,

                  height:
                  1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// REVIEW
// =====================================================================

class _ReviewData {
  final String label;
  final String value;

  const _ReviewData(
      this.label,
      this.value,
      );
}

class _ReviewCard
    extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_ReviewData> rows;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        9,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF3F9F5,
        ),

        borderRadius:
        BorderRadius.circular(
          12,
        ),

        border:
        Border.all(
          color:
          const Color(
            0xFFD2E6DB,
          ),
        ),
      ),

      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,

                size:
                15,

                color:
                const Color(
                  0xFF237153,
                ),
              ),

              const SizedBox(
                width:
                6,
              ),

              Text(
                title,

                style:
                const TextStyle(
                  color:
                  Color(
                    0xFF174B39,
                  ),

                  fontSize:
                  10.8,

                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
            6,
          ),

          ...rows.map(
                (row) =>
                Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom:
                    4,
                  ),

                  child:
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      SizedBox(
                        width:
                        86,

                        child:
                        Text(
                          row.label,

                          style:
                          const TextStyle(
                            color:
                            Color(
                              0xFF789086,
                            ),

                            fontSize:
                            8.5,

                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),

                      Expanded(
                        child:
                        Text(
                          row.value.isEmpty
                              ? '—'
                              : row.value,

                          style:
                          const TextStyle(
                            color:
                            Color(
                              0xFF385B4C,
                            ),

                            fontSize:
                            9,

                            fontWeight:
                            FontWeight.w600,

                            height:
                            1.2,
                          ),
                        ),
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

// =====================================================================
// BOTTOM IMAGE
//
// NO EXTRA TEXT
// NO EXTRA WAVE
// =====================================================================

class _ResubmitFooter
    extends StatelessWidget {
  const _ResubmitFooter();

  @override
  Widget build(
      BuildContext context,
      ) {
    return SizedBox(
      width:
      double.infinity,

      height:
      140,

      child:
      Image.asset(
        'assets/images/historia_resubmit_footer.png',

        width:
        double.infinity,

        height:
        140,

        fit:
        BoxFit.cover,

        alignment:
        Alignment.bottomCenter,

        filterQuality:
        FilterQuality.high,

        errorBuilder:
            (
            context,
            error,
            stackTrace,
            ) {
          return Container(
            width:
            double.infinity,

            height:
            140,

            color:
            const Color(
              0xFFEAF5EE,
            ),
          );
        },
      ),
    );
  }
}