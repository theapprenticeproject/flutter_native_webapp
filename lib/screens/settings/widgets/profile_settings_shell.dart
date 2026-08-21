import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_nav.dart';
import '../models/profile_tab.dart';
import 'profile_side_nav.dart';
import 'profile_switcher.dart';

class ProfileSettingsShell extends StatelessWidget {
  const ProfileSettingsShell({
    required this.studentName,
    required this.activeTab,
    required this.onSwitchDialog,
    required this.onTabChanged,
    required this.child,
    super.key,
  });

  final String studentName;
  final ProfileTab activeTab;
  final VoidCallback onSwitchDialog;
  final ValueChanged<ProfileTab> onTabChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppNav(
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchProfileBar(
                studentName: studentName,
                onSwitchDialog: onSwitchDialog,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxHeight <= 0 ||
                        constraints.maxWidth <= 0) {
                      return const SizedBox.shrink();
                    }

                    final isWide = constraints.maxWidth >= 760;

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 28 : 16,
                        34,
                        isWide ? 28 : 16,
                        96,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 132,
                                      child: ProfileSideNav(
                                        activeTab: activeTab,
                                        onChanged: onTabChanged,
                                      ),
                                    ),
                                    const SizedBox(width: 34),
                                    Expanded(child: child),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ProfileSideNav(
                                      activeTab: activeTab,
                                      onChanged: onTabChanged,
                                      horizontal: true,
                                    ),
                                    const SizedBox(height: 22),
                                    child,
                                  ],
                                ),
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
    );
  }
}
