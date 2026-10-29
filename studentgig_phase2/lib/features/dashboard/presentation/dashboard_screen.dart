import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentgig/core/utils/snackbar.dart';
import 'package:studentgig/domain/entities/app_user.dart';
import 'package:studentgig/features/auth/application/auth_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({required this.role, super.key});

  final UserRole role;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  final Set<String> _savedGigIds = {};
  final Set<String> _appliedGigIds = {};
  final List<_Gig> _gigs = List.of(_sampleGigs);
  String _selectedCategory = 'All';
  int _selectedPage = 0;

  bool get _isStudent => widget.role == UserRole.student;

  List<String> get _categories => [
        'All',
        ...{for (final gig in _gigs) gig.category},
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final pages = _isStudent
        ? const ['Explore', 'Saved', 'Profile']
        : const ['Overview', 'My gigs', 'Profile'];
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 820;
    final content = _buildPage(context, user);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isWide ? 28 : 16,
        title: const _Brand(),
        actions: [
          if (isWide)
            for (var index = 0; index < pages.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PageButton(
                  label: pages[index],
                  selected: _selectedPage == index,
                  onPressed: () => setState(() => _selectedPage = index),
                ),
              ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: content,
          ),
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedPage,
              onDestinationSelected: (index) =>
                  setState(() => _selectedPage = index),
              destinations: _isStudent
                  ? const [
                      NavigationDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: 'Explore',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bookmark_border),
                        selectedIcon: Icon(Icons.bookmark),
                        label: 'Saved',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ]
                  : const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Overview',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.work_outline),
                        selectedIcon: Icon(Icons.work),
                        label: 'My gigs',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
            ),
    );
  }

  Widget _buildPage(BuildContext context, AppUser? user) {
    switch (_selectedPage) {
      case 0:
        return _isStudent
            ? _buildExplore(context, user)
            : _buildEmployerOverview(context, user);
      case 1:
        return _isStudent ? _buildSaved(context) : _buildEmployerGigs(context);
      default:
        return _buildProfile(context, user);
    }
  }

  Widget _buildExplore(BuildContext context, AppUser? user) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredGigs = _gigs.where((gig) {
      final matchesCategory =
          _selectedCategory == 'All' || gig.category == _selectedCategory;
      final searchable =
          '${gig.title} ${gig.company} ${gig.location} ${gig.category}'
              .toLowerCase();
      return matchesCategory && searchable.contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _Greeting(
          eyebrow: 'YOUR NEXT OPPORTUNITY',
          title: 'Find work that works for you.',
          subtitle:
              'Flexible gigs, great experience, and a little extra money.',
          name: user?.displayName.split(' ').first,
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search roles, companies, or locations',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return ChoiceChip(
                label: Text(category),
                selected: category == _selectedCategory,
                onSelected: (_) => setState(() => _selectedCategory = category),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeading(
          title: 'Recommended for you',
          trailing: '${filteredGigs.length} gigs',
        ),
        const SizedBox(height: 14),
        if (filteredGigs.isEmpty)
          const _EmptyState(
            icon: Icons.search_off,
            title: 'No gigs found',
            subtitle: 'Try another search or category.',
          )
        else
          _GigGrid(
            gigs: filteredGigs,
            isSaved: (gig) => _savedGigIds.contains(gig.id),
            isApplied: (gig) => _appliedGigIds.contains(gig.id),
            onSave: _toggleSaved,
            onApply: _applyToGig,
          ),
      ],
    );
  }

  Widget _buildSaved(BuildContext context) {
    final savedGigs =
        _gigs.where((gig) => _savedGigIds.contains(gig.id)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const _Greeting(
          eyebrow: 'YOUR SHORTLIST',
          title: 'Saved gigs',
          subtitle: 'Keep your favorite opportunities close.',
        ),
        const SizedBox(height: 24),
        if (savedGigs.isEmpty)
          const _EmptyState(
            icon: Icons.bookmark_border,
            title: 'Nothing saved yet',
            subtitle: 'Save a gig from Explore and it will show up here.',
          )
        else
          _GigGrid(
            gigs: savedGigs,
            isSaved: (_) => true,
            isApplied: (gig) => _appliedGigIds.contains(gig.id),
            onSave: _toggleSaved,
            onApply: _applyToGig,
          ),
      ],
    );
  }

  Widget _buildEmployerOverview(BuildContext context, AppUser? user) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        _EmployerHero(
          name: user?.displayName.split(' ').first,
          onCreate: _showCreateGigDialog,
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth < 560
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 3;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Active gigs',
                    value: '${_gigs.length}',
                    icon: Icons.work_outline,
                    color: const Color(0xFF3157A4),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _MetricCard(
                    label: 'Applications',
                    value: '12',
                    icon: Icons.people_outline,
                    color: Color(0xFF17856B),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _MetricCard(
                    label: 'Profile views',
                    value: '48',
                    icon: Icons.visibility_outlined,
                    color: Color(0xFF9864C5),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        _SectionHeading(
          title: 'Your latest gigs',
          trailing: 'Manage gigs',
          onTrailingTap: () => setState(() => _selectedPage = 1),
        ),
        const SizedBox(height: 14),
        ..._gigs.take(3).map((gig) => _EmployerGigTile(
              gig: gig,
              onDelete: () => _deleteGig(gig),
            )),
      ],
    );
  }

  Widget _buildEmployerGigs(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Row(
          children: [
            const Expanded(
              child: _Greeting(
                eyebrow: 'EMPLOYER SPACE',
                title: 'Manage your gigs',
                subtitle: 'Keep your opportunities up to date.',
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              tooltip: 'Create a gig',
              onPressed: _showCreateGigDialog,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_gigs.isEmpty)
          const _EmptyState(
            icon: Icons.work_outline,
            title: 'No gigs posted yet',
            subtitle: 'Create your first gig to get started.',
          )
        else
          ..._gigs.map((gig) => _EmployerGigTile(
                gig: gig,
                onDelete: () => _deleteGig(gig),
              )),
      ],
    );
  }

  Widget _buildProfile(BuildContext context, AppUser? user) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        const _Greeting(
          eyebrow: 'YOUR ACCOUNT',
          title: 'Profile',
          subtitle: 'Your StudentGig account details.',
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(
                    (user?.displayName.isNotEmpty ?? false)
                        ? user!.displayName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  user?.displayName ?? 'StudentGig member',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(user?.email ?? ''),
                const SizedBox(height: 14),
                Chip(
                  avatar: Icon(
                    _isStudent ? Icons.school_outlined : Icons.storefront,
                    size: 18,
                  ),
                  label: Text(_isStudent ? 'Student' : 'Employer'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  Future<void> _showCreateGigDialog() async {
    final gig = await showDialog<_Gig>(
      context: context,
      builder: (_) => const _CreateGigDialog(),
    );

    if (gig == null || !mounted) return;
    setState(() {
      _gigs.insert(0, gig);
      _selectedCategory = 'All';
    });
    showSnack(context, 'Your gig is now live.');
  }

  Future<void> _applyToGig(_Gig gig) async {
    if (_appliedGigIds.contains(gig.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apply for this gig?'),
        content: Text(
          'Your interest in ${gig.title} at ${gig.company} will be recorded on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _appliedGigIds.add(gig.id));
    showSnack(context, 'You applied for ${gig.title}.');
  }

  void _toggleSaved(_Gig gig) {
    setState(() {
      if (!_savedGigIds.add(gig.id)) _savedGigIds.remove(gig.id);
    });
  }

  void _deleteGig(_Gig gig) {
    setState(() {
      _gigs.removeWhere((item) => item.id == gig.id);
      _savedGigIds.remove(gig.id);
      _appliedGigIds.remove(gig.id);
    });
    showSnack(context, 'Gig removed.');
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/branding/studentgig_icon.png',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            semanticLabel: 'StudentGig app icon',
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'StudentGig',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.name,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name == null ? title : 'Hi, $name. $title',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          TextButton(
            onPressed: onTrailingTap,
            child: Text(trailing!),
          ),
      ],
    );
  }
}

class _GigGrid extends StatelessWidget {
  const _GigGrid({
    required this.gigs,
    required this.isSaved,
    required this.isApplied,
    required this.onSave,
    required this.onApply,
  });

  final List<_Gig> gigs;
  final bool Function(_Gig) isSaved;
  final bool Function(_Gig) isApplied;
  final ValueChanged<_Gig> onSave;
  final ValueChanged<_Gig> onApply;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 940
            ? 3
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final gig in gigs)
              SizedBox(
                width: cardWidth,
                child: _GigCard(
                  gig: gig,
                  saved: isSaved(gig),
                  applied: isApplied(gig),
                  onSave: () => onSave(gig),
                  onApply: () => onApply(gig),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GigCard extends StatelessWidget {
  const _GigCard({
    required this.gig,
    required this.saved,
    required this.applied,
    required this.onSave,
    required this.onApply,
  });

  final _Gig gig;
  final bool saved;
  final bool applied;
  final VoidCallback onSave;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: gig.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(gig.icon, color: gig.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    gig.company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: saved ? 'Remove saved gig' : 'Save gig',
                  onPressed: onSave,
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              gig.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              gig.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _InfoLabel(
                    icon: Icons.location_on_outlined, text: gig.location),
                _InfoLabel(icon: Icons.schedule, text: gig.category),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    gig.pay,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: applied ? null : onApply,
                  child: Text(applied ? 'Applied' : 'Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colors.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmployerHero extends StatelessWidget {
  const _EmployerHero({required this.name, required this.onCreate});

  final String? name;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.82)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMPLOYER DASHBOARD',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.82),
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                name == null ? 'Build your dream team.' : 'Welcome, $name.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Find motivated students ready to make an impact.',
                style:
                    TextStyle(color: colors.onPrimary.withValues(alpha: 0.9)),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: colors.onPrimary,
              foregroundColor: colors.primary,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Post a gig'),
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 18), button],
                )
              : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 18),
                    button,
                  ],
                );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployerGigTile extends StatelessWidget {
  const _EmployerGigTile({required this.gig, required this.onDelete});

  final _Gig gig;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: gig.color.withValues(alpha: 0.12),
          foregroundColor: gig.color,
          child: Icon(gig.icon),
        ),
        title: Text(gig.title),
        subtitle: Text('${gig.company} · ${gig.location} · ${gig.pay}'),
        trailing: IconButton(
          tooltip: 'Delete gig',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _CreateGigDialog extends StatefulWidget {
  const _CreateGigDialog();

  @override
  State<_CreateGigDialog> createState() => _CreateGigDialogState();
}

class _CreateGigDialogState extends State<_CreateGigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _payController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _payController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a gig'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  controller: _titleController,
                  label: 'Gig title',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _companyController,
                  label: 'Business name',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _locationController,
                  label: 'Location',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _payController,
                  label: 'Pay (for example, \$18/hr)',
                  validator: _requiredValidator,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _publish,
          child: const Text('Publish gig'),
        ),
      ],
    );
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _Gig(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim(),
        pay: _payController.text.trim(),
        category: 'New',
        description: 'A new opportunity from your business.',
        icon: Icons.work_outline,
        color: const Color(0xFF3157A4),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty)
          ? 'This field is required.'
          : null;
}

class _Gig {
  const _Gig({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.pay,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String pay;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
}

const _sampleGigs = [
  _Gig(
    id: 'gig-campus-ambassador',
    title: 'Campus Brand Ambassador',
    company: 'Brightside',
    location: 'On campus',
    pay: '\$18 / hour',
    category: 'Flexible',
    description:
        'Share exciting student offers and help grow a campus community.',
    icon: Icons.campaign_outlined,
    color: Color(0xFF3157A4),
  ),
  _Gig(
    id: 'gig-cafe-assistant',
    title: 'Weekend Cafe Assistant',
    company: 'Little Fern Cafe',
    location: 'Downtown',
    pay: '\$20 / hour',
    category: 'Hospitality',
    description: 'Join a friendly team serving coffee and weekend brunch.',
    icon: Icons.coffee_outlined,
    color: Color(0xFF17856B),
  ),
  _Gig(
    id: 'gig-design-intern',
    title: 'Junior Design Intern',
    company: 'Northstar Studio',
    location: 'Hybrid',
    pay: '\$24 / hour',
    category: 'Creative',
    description: 'Bring fresh ideas to real brand and digital design projects.',
    icon: Icons.palette_outlined,
    color: Color(0xFF9864C5),
  ),
  _Gig(
    id: 'gig-math-tutor',
    title: 'Part-time Math Tutor',
    company: 'Study Circle',
    location: 'Remote',
    pay: '\$26 / hour',
    category: 'Education',
    description: 'Help high school students feel confident with math.',
    icon: Icons.menu_book_outlined,
    color: Color(0xFFD47A2A),
  ),
];
