import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SmsScreen(),
    );
  }
}

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  static const MethodChannel _channel = MethodChannel('sms_channel');

  List<dynamic> smsList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initSmsFlow();
  }

  Future<void> initSmsFlow() async {
    await requestSmsPermission();
    await fetchSms();
  }

  Future<void> requestSmsPermission() async {
    var status = await Permission.sms.status;

    if (!status.isGranted) {
      await Permission.sms.request();
    }
  }

  Future<void> fetchSms() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSms');

      setState(() {
        smsList = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error fetching SMS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Fetch Test')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : smsList.isEmpty
          ? const Center(child: Text('No SMS found'))
          : ListView.builder(
              itemCount: smsList.length,
              itemBuilder: (context, index) {
                final sms = smsList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      sms['address'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      sms['body'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      DateTime.fromMillisecondsSinceEpoch(
                        sms['date'],
                      ).toLocal().toString().split('.')[0],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
