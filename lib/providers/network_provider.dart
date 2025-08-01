import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pretty_http_logger/pretty_http_logger.dart';

final httpProvider = Provider.autoDispose<http.BaseClient>((ref) {
  return defaultHttpClient();
});


http.BaseClient defaultHttpClient() {
  return HttpClientWithMiddleware.build(
      middlewares: [
        HttpLogger(logLevel: LogLevel.BODY),
      ]
  );
}