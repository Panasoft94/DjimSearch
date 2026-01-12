import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        elevation: 0,
        toolbarHeight: 85,
        leadingWidth: 80,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: Text(
          'À propos',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.search, size: 60, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 20),
                Text(
                  'Djim Search',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Navigateur web simple, rapide et vocal.\nDéveloppé par Panasoft Corporation.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      _slideTransition(const CustomLicenseScreen()),
                    );
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Voir les licences'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomLicenseScreen extends StatelessWidget {
  const CustomLicenseScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        elevation: 0,
        toolbarHeight: 85,
        leadingWidth: 80,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: Text(
          'Licences',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      body: FutureBuilder<List<List<String>>>(
        future: _loadLicenses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final licenses = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: licenses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = licenses[index];
              final packageName = item[0];
              final licenseText = item[1];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: colorScheme.surfaceVariant.withOpacity(0.5),
                title: Text(packageName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  licenseText.split('\n').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    _slideTransition(LicenseDetailScreen(
                      packageName: packageName,
                      licenseText: licenseText,
                    )),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<List<String>>> _loadLicenses() async {
    final List<List<String>> result = [];
    await for (final license in LicenseRegistry.licenses) {
      final packages = license.packages.toList();
      final paragraphs = license.paragraphs.toList();
      final text = paragraphs.map((p) => p.text).join('\n\n');
      for (final package in packages) {
        result.add([package, text]);
      }
    }
    return result;
  }
}

class LicenseDetailScreen extends StatelessWidget {
  final String packageName;
  final String licenseText;

  const LicenseDetailScreen({
    super.key,
    required this.packageName,
    required this.licenseText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        elevation: 0,
        toolbarHeight: 85,
        leadingWidth: 80,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: Text(
          packageName,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(licenseText, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
      ),
    );
  }
}

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, size: 24),
      onPressed: onPressed,
      tooltip: 'Retour',
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
    );
  }
}
