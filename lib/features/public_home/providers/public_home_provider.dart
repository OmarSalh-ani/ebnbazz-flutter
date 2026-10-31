import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public_index_content.dart';
import '../services/public_index_api_service.dart';

final publicIndexApiServiceProvider = Provider<PublicIndexApiService>((ref) {
  return PublicIndexApiService();
});

final publicHomeDataProvider = FutureProvider<PublicHomeData>((ref) async {
  final api = ref.watch(publicIndexApiServiceProvider);
  final results = await Future.wait([
    api.getWebsiteContent(),
    api.getRegistrationConfig('default'),
    api.getRegistrationConfig('mregister'),
    api.getRegistrationConfig('wregister'),
    api.getMasgedSettings(),
  ]);

  final content = results[0] as PublicWebsiteContent;
  final defaultConfig = results[1] as RegistrationConfig;
  final menConfig = results[2] as RegistrationConfig;
  final womenConfig = results[3] as RegistrationConfig;
  final branding = results[4] as MasgedBranding;

  return PublicHomeData(
    content: content,
    branding: branding,
    registration: PublicRegistrationContext(
      menEnabled: menConfig.registrationEnabled,
      womenEnabled: womenConfig.registrationEnabled,
      labels: defaultConfig.labels,
    ),
  );
});
