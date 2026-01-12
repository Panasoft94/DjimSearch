import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_service.dart';

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _dbService.getHistory();
    if (mounted) {
      // Filtre les éléments d'historique non valides pour éviter les plantages.
      // Cela affecte uniquement l'affichage et ne supprime aucune donnée.
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
        title: const Text('Effacer l\'historique ?'),
        content: const Text('Voulez-vous supprimer toutes vos recherches récentes ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Effacer', style: TextStyle(color: theme.colorScheme.error))
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
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
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
      appBar: AppBar(
        toolbarHeight: 85,
        elevation: 0,
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        shape: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
        centerTitle: true,
        leadingWidth: 80,
        leading: Center(
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 24),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Retour',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.outline.withOpacity(0.5))
            ),
          ),
        ),
        title: Text(
          'Historique', 
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        ),
        actions: [
          if (_history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: Icon(Icons.delete_sweep_outlined, color: colorScheme.error),
                onPressed: _clearAll,
                tooltip: 'Tout effacer',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer.withOpacity(0.2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildHistoryList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Aucun historique',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final bool showHeader = index == 0 || 
            _formatDate(item['history_date']) != _formatDate(_history[index - 1]['history_date']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
                child: Text(
                  _formatDate(item['history_date']),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                title: Text(
                  item['history_query'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(item['history_date'])),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _deleteItem(item['history_id']),
                ),
                onTap: () {
                  Navigator.pop(context, item['history_query']);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
