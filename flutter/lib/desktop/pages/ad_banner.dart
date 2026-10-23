import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _adsApiUrl = 'https://admin98.ir/api/ads/';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({Key? key}) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  String? _imageUrl;
  String? _targetUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAd();
  }

  Future<void> _fetchAd() async {
    try {
      final response = await http
          .get(Uri.parse(_adsApiUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final ads = decoded['ads'];
      if (ads is! List || ads.isEmpty || ads.first is! Map) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final ad = Map<String, dynamic>.from(ads.first as Map);
      final image = ad['image_url'];
      final target = ad['target_url'];
      final imageUri = Uri.tryParse(image is String ? image : '');
      final targetUri = Uri.tryParse(target is String ? target : '');
      if (imageUri == null ||
          targetUri == null ||
          imageUri.scheme != 'https' ||
          !['http', 'https'].contains(targetUri.scheme)) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      if (mounted) {
        setState(() {
          _imageUrl = imageUri.toString();
          _targetUrl = targetUri.toString();
          _loading = false;
        });
      }
    } on TimeoutException {
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      // Ads are optional: network/API failures must not affect remote desktop.
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAdLink() async {
    final url = _targetUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignore link-launch failures; the client should remain usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _imageUrl == null || _targetUrl == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SizedBox(
        height: 64,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _openAdLink,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                _imageUrl!,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
