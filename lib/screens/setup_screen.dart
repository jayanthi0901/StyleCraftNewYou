// ---------------------------------------------------------------------------
// setup_screen.dart
//
// STYLIST SETUP SCREEN – fulfils User Story 3.
//
// The stylist can pick any profile combination and set a default opacity
// for it.  When saved, the consultation screen will automatically load that
// opacity whenever that profile is selected – no fiddling needed mid-session.
//
// Access this screen via the ⚙ icon on the consultation screen.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/styles_data.dart';
import '../models/style_profile.dart';
import '../providers/consultation_provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // Local copies of the profile dimensions so changes here don't affect the
  // live consultation until the stylist taps Save
  late String _faceShape;
  late String _occasion;
  late String _hairLength;
  late String _changeType;
  double _opacity = 0.65;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Start with the same profile currently selected in the consultation
    final p = context.read<ConsultationProvider>().profile;
    _faceShape  = p.faceShape;
    _occasion   = p.occasion;
    _hairLength = p.hairLength;
    _changeType = p.changeType;
    _loadSavedOpacity();
  }

  StyleProfile get _profile => StyleProfile(
        faceShape: _faceShape,
        occasion: _occasion,
        hairLength: _hairLength,
        changeType: _changeType,
      );

  Future<void> _loadSavedOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _opacity = prefs.getDouble('opacity_${_profile.storageKey}') ?? 0.65;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('opacity_${_profile.storageKey}', _opacity);
    setState(() => _saved = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default opacity ${(_opacity * 100).round()}% saved for '
            '$_faceShape / $_changeType',
          ),
          backgroundColor: const Color(0xFF4A90D9),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // When profile changes, reload previously saved opacity for that combination
  void _onProfileChanged() {
    setState(() => _saved = false);
    _loadSavedOpacity();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Stylist Setup',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF4A90D9),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Intro card ────────────────────────────────────────────────
          _InfoCard(
            icon: Icons.info_outline_rounded,
            text: 'Set a default overlay strength for each client profile. '
                'The consultation screen will load it automatically – '
                'no adjustments needed mid-session.',
          ),

          const SizedBox(height: 20),

          // ── Profile selectors ─────────────────────────────────────────
          const _SectionTitle('Client Profile'),
          const SizedBox(height: 10),

          _DropdownRow(
            label: 'Face Shape',
            value: _faceShape,
            options: kFaceShapes,
            onChanged: (v) { setState(() => _faceShape = v); _onProfileChanged(); },
          ),
          _DropdownRow(
            label: 'Occasion',
            value: _occasion,
            options: kOccasions,
            onChanged: (v) { setState(() => _occasion = v); _onProfileChanged(); },
          ),
          _DropdownRow(
            label: 'Hair Length',
            value: _hairLength,
            options: kHairLengths,
            onChanged: (v) { setState(() => _hairLength = v); _onProfileChanged(); },
          ),
          _DropdownRow(
            label: 'Change Type',
            value: _changeType,
            options: kChangeTypes,
            onChanged: (v) { setState(() => _changeType = v); _onProfileChanged(); },
          ),

          const SizedBox(height: 28),

          // ── Opacity control ───────────────────────────────────────────
          const _SectionTitle('Default Overlay Strength'),
          const SizedBox(height: 4),
          Text(
            'All styles for this profile will use this opacity automatically.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          _OpacityEditor(
            opacity: _opacity,
            onChanged: (v) => setState(() { _opacity = v; _saved = false; }),
          ),

          const SizedBox(height: 30),

          // ── Profile key (helpful for debugging) ───────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Profile key: ${_profile.storageKey}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Save button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(_saved ? Icons.check_circle : Icons.save_rounded),
              label: Text(_saved ? 'Saved!' : 'Save Default Opacity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved
                    ? Colors.green
                    : const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4A90D9), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2D6FA8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpacityEditor extends StatelessWidget {
  final double opacity;
  final ValueChanged<double> onChanged;

  const _OpacityEditor({required this.opacity, required this.onChanged});

  String get _activePreset {
    if (opacity <= 0.42) return 'Low';
    if (opacity <= 0.67) return 'Med';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Percentage display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(opacity * 100).round()}%',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A90D9),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'opacity',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4A90D9),
              inactiveTrackColor: const Color(0xFFD0E4F7),
              thumbColor: const Color(0xFF4A90D9),
              trackHeight: 6,
            ),
            child: Slider(value: opacity, min: 0, max: 1, onChanged: onChanged),
          ),
          const SizedBox(height: 12),
          // Preset chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Low', 'Med', 'High'].map((label) {
              final isActive = label == _activePreset;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isActive,
                  selectedColor: const Color(0xFFEAF3FD),
                  labelStyle: TextStyle(
                    color: isActive ? const Color(0xFF4A90D9) : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: isActive ? const Color(0xFF4A90D9) : Colors.grey.shade300,
                  ),
                  onSelected: (_) {
                    final val = label == 'Low' ? 0.30 : label == 'Med' ? 0.55 : 0.80;
                    onChanged(val);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
