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
    final tabs = await _dbService.getTabsForGroup(widget.group['group_id']);
    if (mounted) {
      setState(() {
        _tabs = tabs;
        _isLoading = false;
      });
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
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_tabs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tab_unselected_rounded, size: 64, color: colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('Aucun onglet dans ce groupe', style: theme.textTheme.bodyLarge),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.public_rounded),
                        title: Text(tab['tab_title'] ?? 'Sans titre', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(tab['tab_url'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, tab['tab_url']),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                      ),
                    );
                  },
                  childCount: _tabs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
