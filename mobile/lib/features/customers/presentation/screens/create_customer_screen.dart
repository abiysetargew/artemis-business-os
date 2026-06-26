import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  ConsumerState<CreateCustomerScreen> createState() =>
      _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends ConsumerState<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');

  List<String> _regions = [];
  final Map<String, List<String>> _regionCities = {};
  String? _selectedRegion;
  String? _selectedCity;
  bool _isLoadingRegions = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
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
        _isLoadingRegions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null) {
      showAppSnackBar(
        context,
        message: 'Please select a region',
        isError: true,
      );
      return;
    }
    if (_selectedCity == null) {
      showAppSnackBar(context, message: 'Please select a city', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
        '/customers',
        data: {
          'name': _nameController.text.trim(),
          'contactPerson': _contactController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'region': _selectedRegion,
          'city': _selectedCity,
          'creditLimit': double.tryParse(_creditLimitController.text) ?? 0,
        },
      );
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Customer "${response.data['name']}" created!',
          isSuccess: true,
        );
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
        title: const Text('New Customer'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingRegions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        _Section(
                          title: 'Basic Info',
                          icon: Icons.business_rounded,
                          accentColor: AppTheme.primaryColor,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Customer Name *',
                                hintText: 'e.g., Addis Ababa Distributors',
                                prefixIcon: Icon(Icons.business_rounded),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _contactController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Person',
                                hintText: 'e.g., Abebe Kebede',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                hintText: '+251911234567',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Phone is required';
                                }
                                if (v.length < 7) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                hintText: 'Bole Road',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Location',
                          icon: Icons.map_rounded,
                          accentColor: AppTheme.infoColor,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRegion,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Region *',
                                prefixIcon: Icon(Icons.map_rounded),
                              ),
                              items: _regions
                                  .map<DropdownMenuItem<String>>(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedRegion = v;
                                _selectedCity = null;
                              }),
                              validator: (v) =>
                                  v == null ? 'Region is required' : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCity,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'City *',
                                prefixIcon: const Icon(
                                  Icons.location_city_rounded,
                                ),
                                hintText: _selectedRegion == null
                                    ? 'Select region first'
                                    : 'Choose a city',
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
                              validator: (v) =>
                                  v == null ? 'City is required' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Credit',
                          icon: Icons.account_balance_rounded,
                          accentColor: AppTheme.successColor,
                          children: [
                            TextFormField(
                              controller: _creditLimitController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Credit Limit',
                                hintText: '0',
                                prefixIcon: Icon(Icons.account_balance_rounded),
                                prefixText: 'ETB ',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final n = double.tryParse(v);
                                if (n == null || n < 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.infoLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: AppTheme.infoColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.infoColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Customer will be created with ACTIVE status. You can edit details later.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.slate700,
                                    height: 1.4,
                                  ),
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
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
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
                              : const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                ),
                          label: const Text(
                            'Create Customer',
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

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderPro(title: title, icon: icon, accentColor: accentColor),
        GlassCard(
          accentColor: accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}
