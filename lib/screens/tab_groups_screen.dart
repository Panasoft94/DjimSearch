import 'package:flutter/material.dart';
import '../db_service.dart';

class TabGroupsScreen extends StatefulWidget {
  const TabGroupsScreen({super.key});

  @override
  State<TabGroupsScreen> createState() => _TabGroupsScreenState();
}

class _TabGroupsScreenState extends State<TabGroupsScreen> {
  final DBService _dbService = DBService();
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final groups = await _dbService.getTabGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGroup(int id) async {
    await _dbService.deleteTabGroup(id);
    _loadGroups();
  }

  void _showNewGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouveau Groupe'),
          content: TextField(
            controller: groupNameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nom du groupe',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ANNULER'),
            ),
            FilledButton(
              onPressed: () async {
                final name = groupNameController.text.isNotEmpty
                    ? groupNameController.text
                    : 'Groupe sans nom';
                await _dbService.addTabGroup(name);
                if (mounted) {
                  Navigator.pop(context);
                  _loadGroups();
                }
              },
              child: const Text('CRÉER'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Groupes d\'Onglets'),
            backgroundColor: colorScheme.surface,
            scrolledUnderElevation: 2,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadGroups,
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_groups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder_copy_outlined,
                          size: 84,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Aucun groupe créé',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Organisez vos onglets par thèmes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _showNewGroupDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer mon premier groupe'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final group = _groups[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(group['group_date']);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key('group_${group['group_id']}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
                          ),
                          onDismissed: (_) => _deleteGroup(group['group_id']),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: colorScheme.outlineVariant),
                            ),
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => Navigator.pop(context, group),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.folder_rounded, color: colorScheme.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group['group_name'],
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Créé le ${date.day}/${date.month}/${date.year}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.5)
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _groups.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _groups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showNewGroupDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau groupe'),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }
}
