// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_ping/dart_ping.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VPNFerdosiApp());
}

class VPNFerdosiApp extends StatelessWidget {
  const VPNFerdosiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VPN فردوسی',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F28),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E3A8A),
          secondary: Color(0xFF3B82F6),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class ServerConfig {
  final String type;
  final String config;
  int ping;
  bool reachable;

  ServerConfig({
    required this.type,
    required this.config,
    this.ping = 100000,
    this.reachable = false,
  });

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        type: json['type'] as String? ?? '',
        config: json['config'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'type': type, 'config': config};
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<ServerConfig> _servers = [];
  String _status = 'آماده';
  bool _connected = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Initialize after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
    // Refresh configs & pings every 12h
    _refreshTimer =
        Timer.periodic(const Duration(hours: 12), (_) => _initialize());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _status = 'دریافت کانفیگ‌ها');
    if (!await _fetchConfigs()) {
      _showError('خطا در دانلود کانفیگ‌ها');
      return;
    }
    setState(() => _status = 'بررسی وضعیت سرورها');
    await _evaluateServers();
    setState(() => _status = 'آماده');
  }

  Future<bool> _fetchConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('configs');
      if (stored != null) {
        final list = jsonDecode(stored) as List;
        _servers
          ..clear()
          ..addAll(list
              .map((e) => ServerConfig.fromJson(e as Map<String, dynamic>)));
        return true;
      }
      final res = await http
          .get(Uri.parse(
              'https://raw.githubusercontent.com/mr-r0ot/FerdowsiVPN/refs/heads/Ate/Es.s'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return false;
      final list = jsonDecode(res.body) as List;
      _servers
        ..clear()
        ..addAll(list
            .map((e) => ServerConfig.fromJson(e as Map<String, dynamic>)));
      await prefs.setString(
          'configs', jsonEncode(_servers.map((e) => e.toJson()).toList()));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _evaluateServers() async {
    for (var s in _servers) {
      final host = _extractHost(s.config);
      s.ping = await _pingHost(host);
      s.reachable = s.ping < 10000;
      setState(() {});
    }
  }

  Future<int> _pingHost(String host) async {
    try {
      final ping = Ping(host, count: 1, timeout: 1000);
      final report = await ping.stream.first;
      return report.response?.time?.inMilliseconds ?? 100000;
    } catch (_) {
      return 100000;
    }
  }

  String _extractHost(String config) {
    final regex = RegExp(r'server\s*[:=]\s*"(.*?)"');
    final m = regex.firstMatch(config);
    return m?.group(1) ?? '1.1.1.1';
  }

  Future<void> _connect() async {
    setState(() => _status = 'در حال اتصال');
    final candidates = _servers.where((s) => s.reachable).toList();
    if (candidates.isEmpty) {
      _showError('هیچ سروری در دسترس نیست');
      return;
    }
    candidates.sort((a, b) => a.ping.compareTo(b.ping));
    final best = candidates.first;
    // TODO: اتصال V2Ray با best.config
    await Future.delayed(const Duration(seconds: 2));
    _connected = true;
    setState(() => _status = 'متصل با پینگ ${best.ping}ms');
    // تست دسترسی به سایت‌ها
    int ok = 0;
    for (var url in [
      'https://www.instagram.com',
      'https://telegram.org',
      'https://youtube.com'
    ]) {
      try {
        final r = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 3),
            );
        if (r.statusCode == 200) ok++;
      } catch (_) {}
    }
    setState(() =>
        _status = ok >= 2 ? 'اتصال پایدار' : 'اتصال ناپایدار ($ok/3)');
  }

  void _showError(String msg) {
    setState(() => _status = 'خطا');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطا'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('باشه'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avail = _servers.where((s) => s.reachable).length;
    final bestPing = _servers
        .where((s) => s.reachable)
        .map((s) => s.ping)
        .fold<int>(100000, (p, e) => e < p ? e : p);

    return Scaffold(
      appBar: AppBar(title: const Text('VPN فردوسی')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("وضعیت: $_status"),
            Text("سرورهای قابل‌استفاده: $avail"),
            Text("کمترین پینگ: ${bestPing < 100000 ? bestPing : '-'}ms"),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _connect,
                child: Text(_connected ? 'قطع اتصال' : 'اتصال'),
              ),
            ),
            const SizedBox(height: 20),
            const Text('لیست سرورها:'),
            Expanded(
              child: ListView.builder(
                itemCount: _servers.length,
                itemBuilder: (c, i) {
                  final s = _servers[i];
                  return ListTile(
                    title: Text(s.type),
                    subtitle: Text(
                        "پینگ: ${s.ping < 100000 ? s.ping : '-'}ms"),
                    trailing: Icon(
                      s.reachable ? Icons.check_circle : Icons.cancel,
                      color: s.reachable ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
