import 'package:flutter/material.dart';
import '../db_service.dart';
import 'package:intl/intl.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DBService _dbService = DBService();
  List<Map<String, dynamic>> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final downloads = await _dbService.getDownloads();
    setState(() {
      _downloads = downloads;
      _isLoading = false;
    });
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
        title: const Text('Téléchargements'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloads.isEmpty
              ? _buildEmptyState(colorScheme)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloads.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final download = _downloads[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(download['download_date']);
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.file_present_rounded, color: colorScheme.primary),
                        ),
                        title: Text(
                          download['file_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(download['file_size'] ?? 'Taille inconnue', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                            Text(formattedDate, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _deleteDownload(download['download_id']),
                        ),
                        onTap: () {
                          // Logique pour ouvrir le fichier (nécessite open_file ou similaire)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ouverture du fichier (À implémenter)')),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_download_outlined, size: 100, color: colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            'Aucun téléchargement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(
            'Vos fichiers téléchargés apparaîtront ici.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
