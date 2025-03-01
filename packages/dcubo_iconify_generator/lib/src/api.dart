import 'dart:convert';

import 'package:http/http.dart' as http;

/// The individual item in the response from the Github API
class IconSetGithubApiResponse {
  /// Default constructor
  IconSetGithubApiResponse({
    required this.name,
    required this.sha,
    required this.downloadUrl,
  });

  /// Factory constructor to create an instance of [IconSetGithubApiResponse] from a JSON object
  factory IconSetGithubApiResponse.fromJson(Map<String, dynamic> json) {
    return IconSetGithubApiResponse(
      name: json['name'] as String,
      sha: json['sha'] as String,
      downloadUrl: json['download_url'] as String,
    );
  }

  /// The name of the file
  final String name;

  /// The SHA of the file
  final String sha;

  /// The download URL of the file
  final String downloadUrl;

  @override
  String toString() {
    return 'IconSetGithubApiResponse('
        'name: $name, sha: $sha, downloadUrl: $downloadUrl)';
  }
}

/// Fetches the icon sets from the Github API
Future<Iterable<IconSetGithubApiResponse>> getIconSets() async {
  final res = await http.get(
    Uri.parse('https://api.github.com/repos/iconify/icon-sets/contents/json'),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to fetch icon sets');
  }

  final jsonResponse = jsonDecode(res.body) as List<dynamic>;

  return jsonResponse.map((dynamic json) =>
      IconSetGithubApiResponse.fromJson(json as Map<String, dynamic>));
}
