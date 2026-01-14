import 'package:djimsearch/screens/group_details_screen.dart';
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

  // NOUVEAU: Méthode de transition
  PageRouteBuilder _slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
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
  
  Future<void> _clearAllGroups() async {
     final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les groupes ?'),
        content: const Text('Voulez-vous vraiment supprimer tous les groupes d\'onglets ? Cette action est irréversible et supprimera tous les onglets qu\'ils contiennent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('SUPPRIMER TOUT')),
        ],
      ),
    );

    if (confirm == true) {
      final groups = await _dbService.getTabGroups();
      for (final group in groups) {
        await _dbService.deleteTabGroup(group['group_id'] as int);
      }
      _loadGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tous les groupes ont été supprimés.')));
      }
    }
  }

  void _showNewGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau Groupe',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez un nouvel espace pour organiser vos onglets.',
                 style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: groupNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom du groupe',
                  hintText: 'Ex: IT - Developpement',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
                ),
                onSubmitted: (value) async {
                   final name = value.isNotEmpty ? value : 'Groupe sans nom';
                  await _dbService.addTabGroup(name);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadGroups();
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.add_rounded),
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
                    label: const Text('Créer le groupe'),
                  ),
                ],
              ),
            ],
          ),
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
                tooltip: 'Actualiser la liste',
              ),
              if (!_isLoading && _groups.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
                  onPressed: _clearAllGroups,
                  tooltip: 'Supprimer tous les groupes',
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
                              // Sélectionne le groupe actif
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
                                    // Bouton d'action pour les détails du groupe
                                    IconButton(
                                      icon: Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          _slideTransition(GroupDetailsScreen(group: group)), // MODIFIÉ: Utilisation de _slideTransition
                                        );
                                        // Si le groupe a été supprimé depuis l'écran de détails, recharger la liste
                                        if (result == true) {
                                          _loadGroups();
                                        } else if (result is String) {
                                          // Si une URL a été retournée (ouverture d'un onglet), retourner à l'écran d'accueil
                                          if (mounted) Navigator.pop(context, result);
                                        } else {
                                          _loadGroups(); // Simple actualisation
                                        }
                                      },
                                      tooltip: 'Détails du groupe',
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
      // Le FAB est maintenant toujours visible pour créer un nouveau groupe
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewGroupDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau groupe'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
