import 'package:flutter/material.dart';
import '../db_service.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  final DBService _dbService = DBService();
  List<Map<String, dynamic>> _tabs = [];
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadTabs();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTabs() async {
    setState(() => _isLoading = true);
    final groupId = widget.group['group_id'] as int;
    final tabs = await _dbService.getTabsForGroup(groupId);
    if (mounted) {
      setState(() {
        _tabs = tabs;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  Future<void> _deleteTab(int tabId) async {
    await _dbService.deleteHistoryItem(tabId);
    _loadTabs();
  }

  Future<void> _deleteGroup() async {
    final theme = Theme.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce groupe ?'),
        content: Text('Voulez-vous supprimer "${widget.group['group_name']}" et tous ses onglets ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('SUPPRIMER', style: TextStyle(color: theme.colorScheme.error))),
        ],
      ),
    );

    if (confirm == true) {
      final groupId = widget.group['group_id'] as int;
      await _dbService.deleteTabGroup(groupId);
      if (mounted) {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(widget.group['group_name'], style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadTabs, tooltip: 'Actualiser'),
          IconButton(icon: Icon(Icons.delete_sweep_rounded, color: colorScheme.error), onPressed: _deleteGroup, tooltip: 'Supprimer le groupe'),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _tabs.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
                    itemCount: _tabs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: Spacing.md),
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      return _buildTabCard(tab, theme, colorScheme);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tab_rounded, size: 80, color: colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: Spacing.xl),
          Text('Aucun onglet', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(height: Spacing.sm),
          Text('Les onglets enregistrés apparaîtront ici', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildTabCard(Map<String, dynamic> tab, ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.radiusRound),
        onTap: () => Navigator.pop(context, tab['tab_url']),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(Spacing.radiusRound),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Spacing.radiusMedium)),
                child: Icon(Icons.link_rounded, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tab['tab_title'] ?? 'Sans titre', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Spacing.xs),
                    Text(tab['tab_url'] ?? '', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), color: colorScheme.error, onPressed: () => _deleteTab(tab['tab_id']), tooltip: 'Supprimer', visualDensity: VisualDensity.compact),
            ],
          ),
        ),
      ),
    );
  }
}

