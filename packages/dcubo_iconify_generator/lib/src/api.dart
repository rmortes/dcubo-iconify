import 'dart:convert';

import 'package:http/http.dart' as http;

/// The individual item in the response from the Github API
class IconSetListItemGithubApiResponse {
  /// Default constructor
  IconSetListItemGithubApiResponse({
    required this.name,
    required this.sha,
    required this.downloadUrl,
  });

  /// Factory constructor to create an instance of [IconSetListItemGithubApiResponse] from a JSON object
  factory IconSetListItemGithubApiResponse.fromJson(Map<String, dynamic> json) {
    return IconSetListItemGithubApiResponse(
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
    return 'IconSetListItemGithubApiResponse('
        'name: $name, sha: $sha, downloadUrl: $downloadUrl)';
  }
}

/// Fetches the icon sets from the Github API
Future<Iterable<IconSetListItemGithubApiResponse>> getIconSets(
    String token) async {
  final res = await http.get(
    Uri.parse('https://api.github.com/repos/iconify/icon-sets/contents/json'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to fetch icon sets');
  }

  final jsonResponse = jsonDecode(res.body) as List<dynamic>;

  return jsonResponse.map((dynamic json) =>
      IconSetListItemGithubApiResponse.fromJson(json as Map<String, dynamic>));
}

class IconSetDataInfo {
  IconSetDataInfo({
    required this.name,
    required this.total,
    required this.authorName,
    required this.authorUrl,
    required this.licenseTitle,
    required this.licenseSpdx,
    required this.licenseUrl,
    required this.palette,
    this.height,
    this.category,
    this.samples,
    this.displayHeight,
    this.version,
    this.tags,
  });

  factory IconSetDataInfo.fromJson(Map<String, dynamic> json) {
    return IconSetDataInfo(
      name: json['name'] as String,
      total: json['total'] as int,
      version: json['version'] as String?,
      authorName: json['author']['name'] as String,
      authorUrl: json['author']['url'] as String,
      licenseTitle: json['license']['title'] as String,
      licenseSpdx: json['license']['spdx'] as String,
      licenseUrl: json['license']['url'] as String,
      samples: (json['samples'] as List<dynamic>?)?.cast<String>(),
      height: json['height'] as int?,
      displayHeight: json['displayHeight'] as int?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      palette: json['palette'] as bool,
    );
  }

  final String name;
  final int total;
  final String? version;
  final String authorName;
  final String authorUrl;
  final String licenseTitle;
  final String licenseSpdx;
  final String licenseUrl;
  final List<String>? samples;
  final int? height;
  final int? displayHeight;
  final String? category;
  final List<String>? tags;
  final bool palette;

  @override
  String toString() {
    return 'IconSetInfoGithubApiResponse('
        'name: $name, '
        'total: $total, '
        'version: $version, '
        'authorName: $authorName, '
        'authorUrl: $authorUrl, '
        'licenseTitle: $licenseTitle, '
        'licenseSpdx: $licenseSpdx, '
        'licenseUrl: $licenseUrl, '
        'samples: $samples, '
        'height: $height, '
        'displayHeight: $displayHeight, '
        'category: $category, '
        'tags: $tags, '
        'palette: $palette)';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'total': total,
      'version': version,
      'authorName': authorName,
      'authorUrl': authorUrl,
      'licenseTitle': licenseTitle,
      'licenseSpdx': licenseSpdx,
      'licenseUrl': licenseUrl,
      'samples': samples,
      'height': height,
      'displayHeight': displayHeight,
      'category': category,
      'tags': tags,
      'palette': palette,
    };
  }
}

class IconData {
  IconData({
    required this.name,
    required this.body,
    this.width,
  });

  factory IconData.fromJson(Map<String, dynamic> json) {
    return IconData(
      name: json['name'] as String,
      body: json['body'] as String,
      width: json['width'] as int?,
    );
  }

  final String name;
  final String body;
  final int? width;

  @override
  String toString() {
    return 'IconData(body: $body, width: $width)';
  }

  Map<String, dynamic> toMap() {
    return {
      'body': body,
      'width': width,
      'name': name,
      'variableName': variableName,
      'iconPreview': iconPreview,
    };
  }

  /// This getter turns the `name` from kebab-case
  /// to camelCase for use as a Dart variable name
  String get variableName {
    var n = name.replaceAllMapped(
      RegExp(r'-(\w)'),
      (match) => match.group(1)!.toUpperCase(),
    );
    if (n.startsWith(RegExp(r'[0-9]'))) {
      n = 'i$n';
    }
    return n;
  }

  /// This getter returns a base64 encoded SVG string
  /// that can be used to preview the icon in vscode
  String get iconPreview => 'data:image/svg+xml;base64,'
      '${base64Encode(utf8.encode('<svg xmlns="http://www.w3.org/2000/svg">$body</svg>'))}';
}

/// The complete data of a single icon set from the Github API
class IconSetData {
  /// Default constructor
  IconSetData({
    required this.prefix,
    required this.info,
    required this.lastModified,
    required this.icons,
  });

  /// Factory constructor to create an instance of [IconSetData] from a JSON object
  factory IconSetData.fromJson(Map<String, dynamic> json) {
    return IconSetData(
      prefix: json['prefix'] as String,
      info: IconSetDataInfo.fromJson(json['info'] as Map<String, dynamic>),
      lastModified: json['lastModified'] as int,
      // Should be a list
      icons: (json['icons'] as Map<String, dynamic>)
          .map(
            (key, value) => MapEntry(
              key,
              IconData.fromJson({
                'name': key,
                ...value as Map<String, dynamic>,
              }),
            ),
          )
          .values
          .toList(),
    );
  }

  /// The prefix of the icon set
  final String prefix;

  /// The info of the icon set
  final IconSetDataInfo info;

  /// The last modified time of the icon set in Unix time
  final int lastModified;

  final List<IconData> icons;

  @override
  String toString() {
    return 'IconSetGithubApiResponse('
        'prefix: $prefix, '
        'lastModified: $lastModified, '
        'icons: $icons'
        'info: $info)';
  }

  Map<String, dynamic> toMap() {
    return {
      'prefix': prefix,
      'lastModified': lastModified,
      'info': info.toMap(),
      'icons': icons.map((e) => e.toMap()).toList(),
      'fileName': fileName,
      'className': className,
    };
  }

  String get fileName => prefix.replaceAll('-', '_');
  String get className => info.name.replaceAll(' ', '');
}

/// Fetches the icon sets from the Github API
Future<IconSetData> getIconSetData(
  String url,
  String token,
) async {
  final res = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to fetch icon sets');
  }

  final jsonResponse = jsonDecode(res.body) as Map<String, dynamic>;

  return IconSetData.fromJson(jsonResponse);
}
