import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const WebViewApp(),
    ),
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.uob.edu.bh/'));
  }

  // ✅ Request permission if needed (only for older Android versions)
  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidVersion = int.parse(
          Platform.operatingSystemVersion.split(' ')[1].split('.').first);
      if (androidVersion < 13) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          openAppSettings();
        }
      }
    }
  }

  // ✅ Download using MediaStore API (for Android 10+)
  Future<void> downloadFile(String url) async {
    try {
      final filename = url.split('/').last;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception("Failed to download file");
      }

      final bytes = response.bodyBytes;

      if (Platform.isAndroid) {
        const channel = MethodChannel('download_channel');
        await channel.invokeMethod('saveFileToDownloads', {
          'filename': filename,
          'bytes': bytes,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved to Downloads: $filename')),
        );
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project management'),
        backgroundColor: const Color.fromARGB(255, 172, 151, 57),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.reload();
            },
          ),
        ],
      ),
      body: WebViewWidget(
        controller: controller
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                final url = request.url;
                if (url.endsWith('.pdf') ||
                    url.endsWith('.doc') ||
                    url.endsWith('.docx') ||
                    url.endsWith('.xlsx') ||
                    url.endsWith('.zip') ||
                    url.contains("download")) {
                  downloadFile(url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          ),
      ),
    );
  }
}



