import 'package:flutter/material.dart';

import '../../core/utils/media_url_helper.dart';

/// Loads [url] from the network when it is http/https, otherwise from assets.
class NetworkOrAssetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final String fallbackAsset;

  const NetworkOrAssetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/images/LoginHeaderImage.png',
  });

  String get _resolvedUrl => MediaUrlHelper.resolve(url) ?? url;

  bool get _isNetworkUrl {
    final resolved = _resolvedUrl;
    return resolved.startsWith('http://') || resolved.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkUrl) {
      return Image.network(
        _resolvedUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: fit),
      );
    }

    final assetPath = url.isNotEmpty ? url : fallbackAsset;
    return Image.asset(
      assetPath,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: fit),
    );
  }
}
