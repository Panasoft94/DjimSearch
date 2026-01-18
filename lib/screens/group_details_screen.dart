import 'package:flutter/material.dart';
import '../db_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final DBService _dbService = DBService();
  List<Map<String, dynamic>> _tabs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTabs();
  }

  Future<void> _loadTabs() async {
    setState(() => _isLoading = true);
    // Assurez-vous que l'ID est bien un int
    final groupId = widget.group['group_id'] as int; 
    final tabs = await _dbService.getTabsForGroup(groupId);
    if (mounted) {
      setState(() {
        _tabs = tabs;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTab(int tabId) async {
    await _dbService.deleteHistoryItem(tabId); // Nous utiliserons cette méthode pour l'instant car elle fait un DELETE
    _loadTabs();
  }

  Future<void> _deleteGroup() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce groupe ?'),
        content: Text('Voulez-vous vraiment supprimer le groupe "${widget.group['group_name']}" et tous les onglets qu\'il contient ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('SUPPRIMER')),
        ],
      ),
    );

    if (confirm == true) {
      final groupId = widget.group['group_id'] as int;
      await _dbService.deleteTabGroup(groupId);
      if (mounted) {
        // Retourne à l'écran précédent et indique que le groupe a été supprimé
        Navigator.pop(context, true); 
      }
    }
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
            title: Text(widget.group['group_name']),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadTabs,
                tooltip: 'Actualiser la liste',
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
                onPressed: _deleteGroup,
                tooltip: 'Supprimer le groupe',
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_tabs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tab_unselected_rounded, size: 80, color: colorScheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 24),
                    Text('Ce groupe est vide', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Ouvrez de nouveaux onglets pour les enregistrer ici.', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tab = _tabs[index];
                    return Dismissible(
                      key: Key('tab_${tab['tab_id']}'),
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
                      onDismissed: (_) => _deleteTab(tab['tab_id']),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.link_rounded, color: colorScheme.primary),
                          ),
                          title: Text(tab['tab_title'] ?? 'Sans titre', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                          subtitle: Text(tab['tab_url'], maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                          onTap: () {
                            final urlToSearch = tab['tab_url'] as String;
                            // Retourne l'URL à l'écran précédent pour déclencher la recherche/navigation sur l'écran d'accueil
                            Navigator.pop(context, urlToSearch);
                          },
                          trailing: Icon(Icons.open_in_new_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  },
                  childCount: _tabs.length,
                ),
              ),
            ),
        ],
      ),
      // Bouton flottant pour ouvrir tous les onglets (nouvelle fonctionnalité)
      floatingActionButton: _tabs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Ici, vous pourriez implémenter l'ouverture de tous les onglets
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ouvrir tous les onglets (À implémenter)')));
              },
              icon: const Icon(Icons.open_in_browser_rounded),
              label: Text('Ouvrir les ${_tabs.length} onglets'),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            )
          : null,
    );
  }
}