// ignore_for_file: prefer_const_constructors

import 'package:dcubo_iconify_generator/src/api.dart';
import 'package:test/test.dart';

void main() {
  group('Api', () {
    test('IconSetGithubApiResponse can be instantiated', () {
      expect(
        IconSetGithubApiResponse(
          name: 'name',
          sha: 'sha',
          downloadUrl: 'downloadUrl',
        ),
        isNotNull,
      );
    });

    test('IconSetGithubApiResponse can be instantiated from JSON', () {
      final instance = IconSetGithubApiResponse.fromJson({
        'name': 'name',
        'sha': 'sha',
        'download_url': 'download_url',
      });

      expect(instance, isNotNull);
      expect(instance.name, 'name');
      expect(instance.sha, 'sha');
      expect(instance.downloadUrl, 'download_url');
    });

    test('getIconSets returns a list of IconSetGithubApiResponse', () async {
      final iconSets = await getIconSets();

      expect(iconSets, isNotEmpty);
      expect(iconSets.first, isA<IconSetGithubApiResponse>());
    });
  });
}
