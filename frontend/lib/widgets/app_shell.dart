import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../screens/analytics_screen.dart';
import '../screens/case_entry_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Wraps every signed-in page. Renders a persistent sidebar + generous
/// max-width content area on web/desktop ("premium website" feel), and a
/// compact top bar + bottom navigation on phones ("neat mobile UI").
///
/// [child] is the current page's content (without its own Scaffold).
/// [currentTab] highlights the matching nav entry when the page is one of
/// the primary destinations (dashboard / new case / history / analytics / profile).
class AppShell extends StatelessWidget {
  final Widget child;
  final ShellTab? currentTab;

  const AppShell({super.key, required this.child, this.currentTab});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: child),
        bottomNavigationBar: _BottomNav(current: currentTab),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _Sidebar(current: currentTab),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum ShellTab { dashboard, newCase, history, analytics, profile }

class _Sidebar extends StatelessWidget {
  final ShellTab? current;

  const _Sidebar({required this.current});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Container(
      width: 244,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brand600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.medical_services_outlined,
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900),
                          children: [
                            TextSpan(text: 'FlapPlan'),
                            TextSpan(
                                text: 'AI', style: TextStyle(color: AppColors.brand600)),
                          ],
                        ),
                      ),
                      const Text('Periodontal outcomes',
                          style: TextStyle(fontSize: 10.5, color: AppColors.gray400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  active: current == ShellTab.dashboard,
                  onTap: () => _goDashboard(context),
                ),
                _NavItem(
                  icon: Icons.add_circle_outline,
                  label: 'New Case',
                  active: current == ShellTab.newCase,
                  onTap: () => _goNewCase(context),
                ),
                _NavItem(
                  icon: Icons.history_edu_outlined,
                  label: 'Case History',
                  active: current == ShellTab.history,
                  onTap: () => _goHistory(context),
                ),
                _NavItem(
                  icon: Icons.insights_outlined,
                  label: 'Analytics',
                  active: current == ShellTab.analytics,
                  onTap: () => _goAnalytics(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _goProfile(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.gray100,
                          child: Text(
                            (profile?.name.isNotEmpty == true
                                    ? profile!.name[0]
                                    : 'U')
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray600),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.name ?? 'Loading…',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray800),
                              ),
                              const Text('Flap Plan AI member',
                                  style: TextStyle(fontSize: 10.5, color: AppColors.gray400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => state.signOut(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 17, color: AppColors.gray500),
                        SizedBox(width: 10),
                        Text('Sign out',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500)),
                      ],
                    ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? AppColors.brand50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18, color: active ? AppColors.brand700 : AppColors.gray600),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.brand700 : AppColors.gray600,
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

class _BottomNav extends StatelessWidget {
  final ShellTab? current;

  const _BottomNav({required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gray200)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              active: current == ShellTab.dashboard,
              onTap: () => _goDashboard(context),
            ),
            _BottomItem(
              icon: Icons.history_edu_outlined,
              label: 'History',
              active: current == ShellTab.history,
              onTap: () => _goHistory(context),
            ),
            _BottomItem(
              icon: Icons.add_circle_outline,
              label: 'New Case',
              active: current == ShellTab.newCase,
              onTap: () => _goNewCase(context),
            ),
            _BottomItem(
              icon: Icons.insights_outlined,
              label: 'Analytics',
              active: current == ShellTab.analytics,
              onTap: () => _goAnalytics(context),
            ),
            _BottomItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: current == ShellTab.profile,
              onTap: () => _goProfile(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand600 : AppColors.gray400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

void _goDashboard(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const DashboardScreen()),
    (route) => false,
  );
}

void _goNewCase(BuildContext context) {
  context.read<AppState>().clearDraft();
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CaseEntryScreen()),
  );
}

void _goHistory(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const HistoryScreen()),
  );
}

void _goAnalytics(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
  );
}

void _goProfile(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ProfileScreen()),
  );
}

