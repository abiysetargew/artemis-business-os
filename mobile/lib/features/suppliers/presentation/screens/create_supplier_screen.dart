import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateSupplierScreen extends ConsumerStatefulWidget {
  const CreateSupplierScreen({super.key});

  @override
  ConsumerState<CreateSupplierScreen> createState() =>
      _CreateSupplierScreenState();
}

class _CreateSupplierScreenState extends ConsumerState<CreateSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _tin = TextEditingController();
  final _notes = TextEditingController();
  bool _isSaving = false;

  List<String> _regions = [];
  final Map<String, List<String>> _regionCities = {};
  String? _selectedRegion;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _region.dispose();
    _tin.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/locations/regions'),
        api.get('/locations/regions-cities'),
      ]);
      if (!mounted) return;
      setState(() {
        _regions = (results[0].data as List).cast<String>();
        _regionCities.clear();
        (results[1].data as Map).forEach((k, v) {
          _regionCities[k as String] = (v as List).cast<String>();
        });
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/suppliers',
        data: {
          'name': _name.text.trim(),
          'contactName': _contact.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'address': _address.text.trim(),
          'city': _selectedCity ?? _city.text.trim(),
          'region': _selectedRegion ?? _region.text.trim(),
          'tinNumber': _tin.text.trim(),
          'notes': _notes.text.trim(),
        },
      );
      if (mounted) {
        showAppSnackBar(context, message: 'Supplier created!', isSuccess: true);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('New Supplier'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  GlassCard(
                    accentColor: const Color(0xFF0F766E),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeaderPro(
                          title: 'Basic Info',
                          icon: Icons.business_rounded,
                          accentColor: Color(0xFF0F766E),
                        ),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Supplier Name *',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contact,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    accentColor: AppTheme.infoColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeaderPro(
                          title: 'Location',
                          icon: Icons.map_rounded,
                          accentColor: AppTheme.infoColor,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRegion,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Region',
                            prefixIcon: Icon(Icons.map_rounded),
                          ),
                          items: _regions
                              .map<DropdownMenuItem<String>>(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedRegion = v;
                            _selectedCity = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'City',
                            prefixIcon: const Icon(Icons.location_city_rounded),
                          ),
                          items: _selectedRegion == null
                              ? const <DropdownMenuItem<String>>[]
                              : (_regionCities[_selectedRegion] ?? [])
                                    .map<DropdownMenuItem<String>>(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                          onChanged: _selectedRegion == null
                              ? null
                              : (v) => setState(() => _selectedCity = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _address,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    accentColor: AppTheme.warningColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeaderPro(
                          title: 'Business Info',
                          icon: Icons.receipt_long_rounded,
                          accentColor: AppTheme.warningColor,
                        ),
                        TextFormField(
                          controller: _tin,
                          decoration: const InputDecoration(
                            labelText: 'TIN Number',
                            prefixIcon: Icon(Icons.numbers_rounded),
                            hintText: 'Tax ID (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notes,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            prefixIcon: Icon(Icons.note_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Create Supplier',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
