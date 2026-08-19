import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(String uid) async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().auth.updateName(uid, _nameController.text);
      if (mounted) setState(() => _editing = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final user = state.user;

    return AppShell(
      currentTab: ShellTab.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Profile',
                subtitle: 'Your account details, saved from registration to Firebase.',
              ),
              if (profile == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.brand50,
                            child: Text(
                              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brand700),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _editing
                                ? TextField(
                                    controller: _nameController,
                                    autofocus: true,
                                    style: const TextStyle(
                                        fontSize: 17, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(isDense: true),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(profile.name,
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.gray900)),
                                      Text(profile.email,
                                          style: const TextStyle(
                                              fontSize: 12.5, color: AppColors.gray500)),
                                    ],
                                  ),
                          ),
                          if (_editing)
                            IconButton(
                              onPressed: _saving ? null : () => _saveName(user!.uid),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.check, color: AppColors.brand600),
                            )
                          else
                            IconButton(
                              onPressed: () {
                                _nameController.text = profile.name;
                                setState(() => _editing = true);
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gray500),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Divider(),
                      const _InfoRow(label: 'Membership', value: 'Flap Plan AI member'),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Email', value: profile.email),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Saved cases', value: '${state.savedCases.length}'),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    context.read<AppState>().signOut();
                  },
                  icon: const Icon(Icons.logout, size: 17, color: AppColors.red),
                  label: const Text('Sign out', style: TextStyle(color: AppColors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
      ],
    );
  }
}
