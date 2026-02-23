import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final DBService _dbService = DBService();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _dbService.getHistory();
    if (mounted) {
      final validHistory = history.where((item) {
        final query = item['history_query'];
        final date = item['history_date'];
        return query is String && query.isNotEmpty && date is int;
      }).toList();

      setState(() {
        _history = validHistory;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> items,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final date = _formatDate(item['history_date'] as int);
      grouped.putIfAbsent(date, () => []).add(item);
    }
    return grouped;
  }

  void _deleteItem(int id) async {
    await _dbService.deleteHistoryItem(id);
    _loadHistory();
  }

  void _clearAll() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Effacer l\'historique ?'),
        content: const Text(
          'Voulez-vous supprimer toutes vos recherches récentes ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Effacer',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.clearHistory();
      _loadHistory();
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'Aujourd\'hui';
    if (itemDate == yesterday) return 'Hier';
    if (itemDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'Cette semaine';
    }
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Historique de recherche',
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
        actions: _history.isNotEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 24),
                    onPressed: _clearAll,
                    tooltip: 'Effacer tout',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _buildBody(colorScheme, theme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      );
    }

    if (_history.isEmpty) {
      return _buildEmptyState(colorScheme, theme);
    }

    final grouped = _groupByDate(_history);
    final sortedDates = grouped.keys.toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final items = grouped[date]!;
          return _buildDateGroup(date, items, colorScheme, theme);
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Aucun historique',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Vos recherches apparaîtront ici',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(
    String date,
    List<Map<String, dynamic>> items,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            child: Text(
              date,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final itemIndex = entry.key;
            final item = entry.value;
            return _buildHistoryItem(
              item,
              colorScheme,
              theme,
              isLast: itemIndex == items.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    Map<String, dynamic> item,
    ColorScheme colorScheme,
    ThemeData theme, {
    required bool isLast,
  }) {
    final query = item['history_query'] as String;
    final id = item['history_id'] as int;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? Spacing.lg : Spacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context, query);
          },
          borderRadius: BorderRadius.circular(Spacing.radiusRound),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(Spacing.radiusRound),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: Spacing.lg),
                Expanded(
                  child: Text(
                    query,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => _deleteItem(id),
                  tooltip: 'Supprimer',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.error,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

