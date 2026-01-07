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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        toolbarHeight: 85,
        leadingWidth: 80,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: const Text(
          'À propos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, size: 60, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Djim Search',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Navigateur web simple, rapide et vocal.\nDéveloppé par Panasoft Corporation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        toolbarHeight: 85,
        leadingWidth: 80,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: const Text(
          'Licences',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      body: FutureBuilder<List<List<String>>>(
        future: _loadLicenses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final licenses = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: licenses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = licenses[index];
              final packageName = item[0];
              final licenseText = item[1];
              return ListTile(
                title: Text(packageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  licenseText.split('\n').first,
                  style: TextStyle(color: Colors.grey[600], overflow: TextOverflow.ellipsis),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        toolbarHeight: 85,
        leadingWidth: 80,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: Text(
          packageName,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(licenseText, style: const TextStyle(fontSize: 14, height: 1.4)),
      ),
    );
  }
}

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[700], size: 24),
        onPressed: onPressed,
        tooltip: 'Retour',
      ),
    );
  }
}
