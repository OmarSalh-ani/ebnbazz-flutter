import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_model.dart';
import '../services/news_api_service.dart';

final newsApiServiceProvider = Provider((ref) => NewsApiService());

final newsProvider = FutureProvider<List<NewsModel>>((ref) async {
  return ref.read(newsApiServiceProvider).getNews();
});
