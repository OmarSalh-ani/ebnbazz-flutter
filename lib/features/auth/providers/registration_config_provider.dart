import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public_registration_models.dart';
import '../services/public_registration_api_service.dart';

final publicRegistrationApiServiceProvider =
    Provider<PublicRegistrationApiService>((ref) {
  return PublicRegistrationApiService();
});

final registrationConfigProvider =
    FutureProvider<PublicRegistrationConfig>((ref) async {
  final api = ref.watch(publicRegistrationApiServiceProvider);
  return api.getRegistrationConfig();
});

final countryDialCodesProvider =
    FutureProvider<List<CountryDialEntry>>((ref) async {
  final api = ref.watch(publicRegistrationApiServiceProvider);
  return api.getCountryDialCodes();
});
