import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/active_profile_model.dart';
import '../../models/learner_state_model.dart';
import '../../models/profile_summary_model.dart';
import '../../providers/http_client_provider.dart';
import '../../providers/learner_state_provider.dart';
import '../../providers/profile_provider.dart';
import 'controllers/profile_form_controller.dart';
import 'models/profile_tab.dart';
import 'services/about_tap_loader.dart';
import 'services/profile_settings_actions.dart';
import 'widgets/about_tap_view.dart';
import 'widgets/profile_details_view.dart';
import 'widgets/profile_settings_shell.dart';
import 'widgets/profile_switcher.dart';
import 'widgets/settings_tab_view.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _aboutTapLoader = AboutTapLoader();
  static const _profileActions = ProfileSettingsActions();

  ProfileTab _activeTab = ProfileTab.profile;

  Map<String, dynamic>? _aboutData;
  bool _aboutLoading = false;
  bool _aboutError = false;

  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveError;

  final ProfileFormController _formController = ProfileFormController();
  final bool _hasSibling = false;

  ActiveProfileModel? _activeProfile;
  LearnerStateModel? _learnerState;
  bool _isLoadingProfile = true;
  bool _profileLoadFailed = false;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _bootstrapProfile();
  }

  @override
  void dispose() {
    _disposed = true;
    _formController.dispose();
    super.dispose();
  }

  bool get _canUpdate => mounted && !_disposed;

  Future<void> _bootstrapProfile() async {
    try {
      final snapshot = await _profileActions.load(ref);
      if (!_canUpdate) return;

      setState(() {
        _activeProfile = snapshot.activeProfile;
        _learnerState = snapshot.learnerState;
        _isLoadingProfile = false;
        _profileLoadFailed = false;
      });
      _syncControllersFromState();
    } catch (e) {
      debugPrint('Failed to load profile for settings: $e');
      if (!_canUpdate) return;
      setState(() {
        _isLoadingProfile = false;
        _profileLoadFailed = true;
      });
    }
  }

  Future<void> _loadAboutTap() async {
    if (_aboutData != null || _aboutLoading) return;
    setState(() {
      _aboutLoading = true;
      _aboutError = false;
    });
    try {
      final decoded = await _aboutTapLoader.load();
      if (!_canUpdate) return;
      setState(() {
        _aboutData = decoded;
        _aboutLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load about_tap.json: $e');
      if (!_canUpdate) return;
      setState(() {
        _aboutLoading = false;
        _aboutError = true;
      });
    }
  }

  void _syncControllersFromState() {
    _formController.sync(
      activeProfile: _activeProfile,
      learnerState: _learnerState,
    );
  }

  String _displayStudentName() =>
      (_learnerState?.profile?.studentName ?? _activeProfile?.studentName ?? '')
          .trim();

  String _verticalDisplay() {
    final course = _learnerState?.enrollment?.course;
    if (course == null || course.isEmpty) return '';
    return course;
  }

  void _startEditing() {
    _syncControllersFromState();
    setState(() {
      _isEditing = true;
      _saveError = null;
    });
  }

  void _cancelEditing() {
    _syncControllersFromState();
    setState(() {
      _isEditing = false;
      _saveError = null;
    });
  }

  Future<void> _saveEdits() async {
    final activeProfile = _activeProfile;
    if (activeProfile == null) return;

    final phone = await _resolvePhone();
    if (!_canUpdate) return;

    if (phone.isEmpty) {
      setState(() {
        _saveError = 'Could not verify your phone number. Please log in again.';
      });
      return;
    }

    final fullName = _formController.fullName;
    final grade = _formController.gradeValue;
    final updates = _formController.toUpdates();

    if (updates.isEmpty) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final result = await _profileActions.save(
        ref: ref,
        phone: phone,
        activeProfile: activeProfile,
        updates: updates,
        fullName: fullName,
        grade: grade,
      );

      if (!_canUpdate) return;

      ref.invalidate(activeProfileProvider);
      ref.invalidate(learnerStateDataProvider(activeProfile.learnerId));

      setState(() {
        if (result.updatedProfile != null) {
          _activeProfile = result.updatedProfile;
        }
        _learnerState = result.learnerState;
        _isEditing = false;
        _isSaving = false;
      });
      _syncControllersFromState();
      _showSavedSnack();
    } catch (e) {
      debugPrint('Profile save failed: $e');
      if (!_canUpdate) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Could not save your changes. Please try again.';
      });
    }
  }

  void _showSavedSnack() {
    if (!_canUpdate) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  void _onTabChanged(ProfileTab tab) {
    setState(() => _activeTab = tab);
    if (tab == ProfileTab.about) {
      _loadAboutTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsShell(
      studentName: _displayStudentName(),
      activeTab: _activeTab,
      onSwitchDialog: _showSwitchProfile,
      onTabChanged: _onTabChanged,
      child: _activeContent(),
    );
  }

  Widget _activeContent() {
    switch (_activeTab) {
      case ProfileTab.profile:
        return ProfileDetailsView(
          isLoading: _isLoadingProfile,
          loadFailed: _profileLoadFailed,
          isEditing: _isEditing,
          isSaving: _isSaving,
          saveError: _saveError,
          activeProfile: _activeProfile,
          learnerState: _learnerState,
          firstNameController: _formController.firstName,
          lastNameController: _formController.lastName,
          languageController: _formController.language,
          gradeController: _formController.grade,
          subjectDisplay: _verticalDisplay(),
          hasSibling: _hasSibling,
          onStartEditing: _startEditing,
          onCancelEditing: _cancelEditing,
          onSave: _saveEdits,
        );
      case ProfileTab.settings:
        return const SettingsTabView();
      case ProfileTab.about:
        return AboutTapView(
          data: _aboutData,
          loading: _aboutLoading,
          failed: _aboutError,
          onRetry: _loadAboutTap,
        );
    }
  }

  Future<String> _resolvePhone() async {
    final tokenStore = ref.read(secureTokenStoreProvider);
    final storedPhone = await tokenStore.readPhone();
    if (storedPhone != null && storedPhone.isNotEmpty) return storedPhone;
    return _activeProfile?.phone ?? '';
  }

  Future<void> _showSwitchProfile() async {
    final phone = await _resolvePhone();
    if (!mounted || _disposed) return;

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not verify your phone number. Please log in again.',
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: AppTheme.subtleShadow.withValues(alpha: 0.48),
      builder: (context) => SwitchProfileDialog(
        phone: phone,
        activeLearnerId: _activeProfile?.learnerId,
        onProfileSelected: _switchToProfile,
      ),
    );
  }

  Future<void> _switchToProfile(ProfileSummaryModel profile) async {
    final phone = await _resolvePhone();
    if (!mounted || _disposed) return;
    if (phone.isEmpty) return;

    try {
      final snapshot = await _profileActions.switchProfile(
        ref: ref,
        phone: phone,
        profile: profile,
      );

      if (!mounted || _disposed) return;

      ref.invalidate(activeProfileProvider);
      ref.invalidate(learnerStateDataProvider(profile.learnerId));

      setState(() {
        _activeProfile = snapshot.activeProfile;
        _learnerState = snapshot.learnerState;
      });
      _syncControllersFromState();

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Failed to switch profile: $e');
      if (!mounted || _disposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not switch profile. Please try again.'),
        ),
      );
    }
  }
}
