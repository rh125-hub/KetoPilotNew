import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/database/models/user_model.dart';

// A starter list of common physical + mental conditions.
// You can expand this anytime.
const List<String> kCommonConditions = [
  // Physical
  'Diabetes (Type 1)',
  'Diabetes (Type 2)',
  'Prediabetes',
  'Hypertension (High blood pressure)',
  'High cholesterol',
  'Heart disease',
  'Asthma',
  'COPD',
  'Sleep apnea',
  'Hypothyroidism',
  'Hyperthyroidism',
  'PCOS',
  'IBS (Irritable bowel syndrome)',
  'GERD (Acid reflux)',
  'Celiac disease',
  'Fatty liver disease',
  'Kidney disease',
  'Arthritis',
  'Migraine',
  'Epilepsy',
  'Cancer (history)',
  // Mental
  'Depression',
  'Anxiety',
  'Bipolar disorder',
  'PTSD',
  'ADHD',
  'OCD',
  'Eating disorder',
  'Autism spectrum disorder',
  'Schizophrenia',
  'Substance use disorder',
];

@RoutePage()
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  String? _gender;
  DateTime? _dob;

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final _diseaseController = TextEditingController();
  final List<String> _selectedDiseases = [];
  List<String> _suggestions = [];

  bool _saving = false;

  // >>> CHANGE START: prefill fields from existing user profile (and load saved diseases)
  @override
  void initState() {
    super.initState();

    // read current user once during init
    final u = ref.read(userProvider).currentUser;
    if (u == null) return;

    _gender = u.gender;

    if (u.dateOfBirth != null) {
      _dob = DateTime.tryParse(u.dateOfBirth!);
    }

    if (u.heightCm != null) {
      _heightController.text = u.heightCm!.toString();
    }

    if (u.initialWeightKg != null) {
      _weightController.text = u.initialWeightKg!.toString();
    }

    // medicalConditions stored as JSON list string, load into chips
    if (u.medicalConditions != null && u.medicalConditions!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(u.medicalConditions!);
        if (decoded is List) {
          _selectedDiseases
            ..clear()
            ..addAll(decoded.map((e) => e.toString()).where((s) => s.trim().isNotEmpty));
        }
      } catch (_) {
        // If older data isn't valid JSON, ignore (don't crash onboarding)
      }
    }
  }
  // >>> CHANGE END

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _updateSuggestions(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final hits = kCommonConditions
        .where((c) => c.toLowerCase().contains(query))
        .take(10)
        .toList();
    setState(() => _suggestions = hits);
  }

  void _addDisease(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    if (_selectedDiseases.contains(n)) return;
    setState(() {
      _selectedDiseases.add(n);
      _diseaseController.clear();
      _suggestions = [];
    });
  }

  void _removeDisease(String name) {
    setState(() => _selectedDiseases.remove(name));
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final userNotifier = ref.read(userProvider.notifier);
    final u = ref.read(userProvider).currentUser;
    if (u == null) return;

    setState(() => _saving = true);

    try {
      // >>> CHANGE START: store null if no diseases selected (cleaner than "[]")
      final String? medicalConditionsJson =
      _selectedDiseases.isEmpty ? null : jsonEncode(_selectedDiseases);
      // >>> CHANGE END

      final updated = u.copyWith(
        gender: _gender,
        dateOfBirth: _dob?.toIso8601String().split('T')[0],
        heightCm: double.tryParse(_heightController.text.trim()),
        initialWeightKg: double.tryParse(_weightController.text.trim()),
        // Store diseases as JSON list string in medicalConditions:
        // >>> CHANGE START
        medicalConditions: medicalConditionsJson,
        // >>> CHANGE END
        updatedAt: DateTime.now().toIso8601String(),
      );

      final ok = await userNotifier.updateProfile(updated);

      if (!mounted) return;

      if (ok) {
        context.router.replaceNamed('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() {
    context.router.replaceNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(userProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // >>> CHANGE START: fix greeting logic (old version never became empty because it included "Hi ")
            Builder(
              builder: (context) {
                final name = (u?.fullName ?? '').trim();
                return Text(
                  name.isEmpty ? 'Hi!' : 'Hi $name!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                );
              },
            ),
            // >>> CHANGE END
            const SizedBox(height: 8),
            Text(
              'Answer a few questions to personalize your experience. You can skip and edit later in Profile.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Gender
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wc),
              ),
              items: const ['Male', 'Female', 'Other', 'Prefer not to say']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Please select one (or skip)' : null,
            ),
            const SizedBox(height: 16),

            // DOB
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                child: Text(
                  _dob == null
                      ? 'Tap to select'
                      : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Height + Weight
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final x = double.tryParse((v ?? '').trim());
                      if (x == null) return 'Enter a number';
                      if (x < 50 || x > 250) return '50–250';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final x = double.tryParse((v ?? '').trim());
                      if (x == null) return 'Enter a number';
                      if (x < 20 || x > 400) return '20–400';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Diseases (search + choose)
            Text(
              'Medical conditions (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _diseaseController,
              decoration: const InputDecoration(
                labelText: 'Search and add conditions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                helperText: 'Type to search, tap to add. You can also type your own and press enter.',
              ),
              onChanged: _updateSuggestions,
              onFieldSubmitted: (v) => _addDisease(v),
            ),

            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (_, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      title: Text(s),
                      onTap: () => _addDisease(s),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedDiseases
                  .map((d) => Chip(label: Text(d), onDeleted: () => _removeDisease(d)))
                  .toList(),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _saveAndContinue,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save & Continue'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : _skip,
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
