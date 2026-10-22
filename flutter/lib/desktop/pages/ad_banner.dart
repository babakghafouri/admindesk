import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({Key? key}) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  String? imageUrl;
  String? targetUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAd();
  }

  // گرفتن بنر از سرور شما (این لینک را بعداً با سرور خودتان عوض می‌کنید)
  Future<void> fetchAd() async {
    try {
      final response = await http.get(Uri.parse('https://your-server.com/api/get-ad'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['is_active'] == true) {
          setState(() {
            imageUrl = data['image_url'];
            targetUrl = data['target_url'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _openAdLink() async {
    if (targetUrl != null) {
      final Uri uri = Uri.parse(targetUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || imageUrl == null) {
      return const SizedBox.shrink(); // اگر بنر نبود، فضایی اشغال نکند
    }

    return InkWell(
      onTap: _openAdLink,
      child: Container(
        width: double.infinity,
        height: 60, // ارتفاع بنر
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}