import 'package:flutter/material.dart';
import '../db_service.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';
import 'package:intl/intl.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  final DBService _dbService = DBService();
  List<Map<String, dynamic>> _downloads = [];
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
    _loadDownloads();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final downloads = await _dbService.getDownloads();
    if (mounted) {
      setState(() {
        _downloads = downloads;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  Future<void> _deleteDownload(int id) async {
    await _dbService.deleteDownload(id);
    _loadDownloads();
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
        title: Text(
          'Téléchargements',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : _downloads.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
                    itemCount: _downloads.length,
                    separatorBuilder: (context, index) => const SizedBox(height: Spacing.md),
                    itemBuilder: (context, index) {
                      final download = _downloads[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(download['download_date']);
                      final formattedDate = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);

                      return _buildDownloadItem(download, formattedDate, theme, colorScheme);
                    },
                  ),
                ),
    );
  }

  Widget _buildDownloadItem(
    Map<String, dynamic> download,
    String formattedDate,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.radiusRound),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ouverture du fichier (À implémenter)')),
          );
        },
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
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                ),
                child: Icon(Icons.file_download_done_rounded, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      download['file_name'] ?? 'Fichier',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Text(
                          download['file_size'] ?? 'Taille inconnue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Text(' • '),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: colorScheme.error,
                onPressed: () => _deleteDownload(download['download_id']),
                tooltip: 'Supprimer',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 80,
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'Aucun téléchargement',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Vos fichiers téléchargés apparaîtront ici',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
