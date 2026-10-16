import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// HTTP client that resolves hostnames via Cloudflare DNS-over-HTTPS
/// when system DNS fails (common with broken VPN DNS on Android).
class DohHttp {
  static final Map<String, String> _cache = {};

  /// Resolve hostname to IPv4 using Cloudflare DoH (1.1.1.1)
  static Future<String?> resolve(String hostname) async {
    if (_cache.containsKey(hostname)) return _cache[hostname];

    try {
      // Talk to Cloudflare by IP so we don't need system DNS for the resolver itself
      final uri = Uri.parse(
        'https://1.1.1.1/dns-query?name=${Uri.encodeComponent(hostname)}&type=A',
      );

      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        // 1.1.1.1 serves a cert for cloudflare-dns.com / 1.1.1.1
        return host == '1.1.1.1' || host == 'cloudflare-dns.com';
      };

      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/dns-json');
      request.headers.set('Host', 'cloudflare-dns.com');

      final response = await request.close().timeout(const Duration(seconds: 10));
      final body = await response.transform(utf8.decoder).join();
      client.close(force: true);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(body);
      final answers = data['Answer'] as List?;
      if (answers == null || answers.isEmpty) return null;

      for (final a in answers) {
        if (a is Map && a['type'] == 1 && a['data'] is String) {
          final ip = a['data'] as String;
          _cache[hostname] = ip;
          return ip;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// GET with DoH fallback
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    } on SocketException catch (e) {
      if (!_isDnsError(e)) rethrow;
      return await _requestWithResolvedIp('GET', uri, headers: headers);
    }
  }

  /// POST with DoH fallback
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      return await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 60));
    } on SocketException catch (e) {
      if (!_isDnsError(e)) rethrow;
      return await _requestWithResolvedIp('POST', uri, headers: headers, body: body);
    }
  }

  static bool _isDnsError(SocketException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('failed host lookup') ||
        msg.contains('no address associated') ||
        e.osError?.errorCode == 7;
  }

  static Future<http.Response> _requestWithResolvedIp(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final host = uri.host;
    final ip = await resolve(host);
    if (ip == null) {
      throw SocketException('Failed host lookup: \'$host\' (DoH also failed)');
    }

    final ipUri = uri.replace(host: ip);

    final httpClient = HttpClient();
    // Keep original hostname for TLS SNI + certificate check
    httpClient.badCertificateCallback = (cert, certHost, port) {
      // Accept if cert is valid for the real hostname
      return certHost == host || cert.subject.contains(host);
    };

    try {
      final request = method == 'POST'
          ? await httpClient.postUrl(ipUri)
          : await httpClient.getUrl(ipUri);

      request.headers.set('Host', host);
      headers?.forEach((k, v) {
        if (k.toLowerCase() != 'host') request.headers.set(k, v);
      });

      if (body != null) {
        final bytes = body is String ? utf8.encode(body) : body as List<int>;
        request.add(bytes);
      }

      final response = await request.close().timeout(const Duration(seconds: 60));
      final responseBody = await response.transform(utf8.decoder).join();

      return http.Response(
        responseBody,
        response.statusCode,
        headers: {
          for (final h in response.headers.entries)
            h.key: h.value.join(','),
        },
      );
    } finally {
      httpClient.close(force: true);
    }
  }
}
