import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Optional home-screen advertisement. Network failures never block AdminDesk.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({Key? key}) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  static final Uri _endpoint = Uri.https(
    'ads.admin98.ir',
    '/api/v1/ads',
    {'placement': 'windows-home-sidebar'},
  );
  static const _requestTimeout = Duration(seconds: 4);
  final http.Client _client = http.Client();
  Timer? _refreshTimer;
  Uri? _imageUrl;
  Uri? _targetUrl;
  String? _adId;

  @override
  void initState() {
    super.initState();
    _fetchAd();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _client.close();
    super.dispose();
  }

  Uri? _httpsUri(dynamic value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) return null;
    return uri;
  }

  Future<void> _fetchAd() async {
    Uri? image;
    Uri? target;
    String? id;
    var refreshSeconds = 300;
    try {
      final response = await _client.get(_endpoint).timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['is_active'] == true) {
          image = _httpsUri(data['image_url']);
          target = _httpsUri(data['target_url']);
          if (image != null && target != null && data['id'] is String) {
            id = data['id'] as String;
          } else {
            image = null;
            target = null;
          }
          if (data['refresh_seconds'] is int) {
            refreshSeconds =
                (data['refresh_seconds'] as int).clamp(60, 3600).toInt();
          }
        }
      }
    } catch (_) {
      // The ad service is optional; fail closed and preserve remote access.
    }
    if (!mounted) return;
    setState(() {
      _imageUrl = image;
      _targetUrl = target;
      _adId = id;
    });
    _refreshTimer?.cancel();
    _refreshTimer = Timer(Duration(seconds: refreshSeconds), _fetchAd);
  }

  Future<void> _openAdLink() async {
    final url = _targetUrl;
    if (url == null) return;
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Opening an advertisement must not affect the desktop UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    if (imageUrl == null || _targetUrl == null || _adId == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openAdLink,
          child: Image.network(
            imageUrl.toString(),
            width: double.infinity,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
