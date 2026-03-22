import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  final String version;
  final String buildNumber;

  const AppVersionInfo({required this.version, required this.buildNumber});

  String get displayVersion {
    if (buildNumber.isEmpty || buildNumber == '0') {
      return version;
    }
    return '$version+$buildNumber';
  }
}

class UpdateCheckResult {
  final AppVersionInfo currentVersion;
  final String latestVersion;
  final String latestTag;
  final String releasePageUrl;
  final String downloadUrl;
  final String? assetName;
  final String? releaseNotes;
  final bool isUpdateAvailable;

  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.latestTag,
    required this.releasePageUrl,
    required this.downloadUrl,
    required this.assetName,
    required this.releaseNotes,
    required this.isUpdateAvailable,
  });
}

class UpdateCheckException implements Exception {
  final String message;

  const UpdateCheckException(this.message);

  @override
  String toString() => message;
}

class UpdateService {
  static const String repositoryOwner = 'cddqssc';
  static const String repositoryName = 'Caption-Trans';
  static const Duration defaultAutoCheckInterval = Duration(hours: 12);

  static final Uri _latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/$repositoryOwner/$repositoryName/releases/latest',
  );
  static final Uri _releasePageUri = Uri.parse(
    'https://github.com/$repositoryOwner/$repositoryName/releases/latest',
  );

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static bool get supportsAutoUpdateCheck =>
      Platform.isMacOS || Platform.isWindows;

  static bool shouldPerformAutoCheck(
    DateTime? lastCheckedAt, {
    DateTime? now,
    Duration minInterval = defaultAutoCheckInterval,
  }) {
    if (lastCheckedAt == null) {
      return true;
    }

    final currentTime = now ?? DateTime.now();
    return currentTime.difference(lastCheckedAt) >= minInterval;
  }

  void dispose() {
    _client.close();
  }

  Future<AppVersionInfo> getCurrentVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppVersionInfo(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }

  Future<UpdateCheckResult> checkForUpdates() async {
    final currentVersion = await getCurrentVersionInfo();
    final response = await _client.get(
      _latestReleaseUri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'caption-trans-update-checker',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != HttpStatus.ok) {
      throw UpdateCheckException('GitHub API returned ${response.statusCode}.');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const UpdateCheckException('Invalid release payload.');
    }

    final latestTag = _readString(decoded['tag_name']);
    if (latestTag == null || latestTag.isEmpty) {
      throw const UpdateCheckException('Latest release tag is missing.');
    }

    final latestVersion = normalizeVersion(latestTag);
    final releasePageUrl =
        _readString(decoded['html_url']) ?? _releasePageUri.toString();
    final releaseNotes = _readString(decoded['body']);
    final assets = _parseAssets(decoded['assets']);
    final selectedAsset = _selectAssetForCurrentPlatform(assets);

    return UpdateCheckResult(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      latestTag: latestTag,
      releasePageUrl: releasePageUrl,
      downloadUrl: selectedAsset?.downloadUrl ?? releasePageUrl,
      assetName: selectedAsset?.name,
      releaseNotes: releaseNotes,
      isUpdateAvailable:
          compareVersions(latestVersion, currentVersion.version) > 0,
    );
  }

  static String normalizeVersion(String rawVersion) {
    final trimmed = rawVersion.trim();
    if (trimmed.isEmpty) return '0.0.0';

    final withoutPrefix = trimmed.startsWith('v') || trimmed.startsWith('V')
        ? trimmed.substring(1)
        : trimmed;
    return withoutPrefix.split('+').first.trim();
  }

  static int compareVersions(String left, String right) {
    return _ParsedVersion.parse(left).compareTo(_ParsedVersion.parse(right));
  }

  static String? _readString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<_ReleaseAsset> _parseAssets(dynamic rawAssets) {
    if (rawAssets is! List) {
      return const [];
    }

    final assets = <_ReleaseAsset>[];
    for (final item in rawAssets) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final name = _readString(item['name']);
      final downloadUrl = _readString(item['browser_download_url']);
      if (name == null || downloadUrl == null) {
        continue;
      }

      assets.add(_ReleaseAsset(name: name, downloadUrl: downloadUrl));
    }
    return assets;
  }

  static _ReleaseAsset? _selectAssetForCurrentPlatform(
    List<_ReleaseAsset> assets,
  ) {
    if (assets.isEmpty) {
      return null;
    }

    if (Platform.isMacOS) {
      return _findAsset(
            assets,
            exactName: 'caption_trans-macos-arm64.dmg',
            platformKeyword: 'macos',
            extension: '.dmg',
          ) ??
          _findAsset(assets, extension: '.dmg');
    }

    if (Platform.isWindows) {
      return _findAsset(
            assets,
            exactName: 'caption_trans-windows-x64.zip',
            platformKeyword: 'windows',
            extension: '.zip',
          ) ??
          _findAsset(assets, extension: '.zip');
    }

    return null;
  }

  static _ReleaseAsset? _findAsset(
    List<_ReleaseAsset> assets, {
    String? exactName,
    String? platformKeyword,
    String? extension,
  }) {
    for (final asset in assets) {
      final lowerName = asset.name.toLowerCase();
      if (exactName != null && lowerName == exactName.toLowerCase()) {
        return asset;
      }
    }

    for (final asset in assets) {
      final lowerName = asset.name.toLowerCase();
      final matchesPlatform = platformKeyword == null
          ? true
          : lowerName.contains(platformKeyword.toLowerCase());
      final matchesExtension = extension == null
          ? true
          : lowerName.endsWith(extension.toLowerCase());
      if (matchesPlatform && matchesExtension) {
        return asset;
      }
    }

    return null;
  }
}

class _ReleaseAsset {
  final String name;
  final String downloadUrl;

  const _ReleaseAsset({required this.name, required this.downloadUrl});
}

class _ParsedVersion implements Comparable<_ParsedVersion> {
  final List<int> core;
  final String prerelease;

  const _ParsedVersion({required this.core, required this.prerelease});

  factory _ParsedVersion.parse(String rawVersion) {
    final normalized = UpdateService.normalizeVersion(rawVersion);
    final dashIndex = normalized.indexOf('-');
    final coreVersion = dashIndex == -1
        ? normalized
        : normalized.substring(0, dashIndex);
    final prerelease = dashIndex == -1
        ? ''
        : normalized.substring(dashIndex + 1);
    final coreParts = coreVersion.split('.').map(_parseNumericPart).toList();

    return _ParsedVersion(core: coreParts, prerelease: prerelease);
  }

  static int _parseNumericPart(String rawPart) {
    final digits = RegExp(r'^\d+').stringMatch(rawPart.trim());
    return int.tryParse(digits ?? '') ?? 0;
  }

  @override
  int compareTo(_ParsedVersion other) {
    final maxLength = core.length > other.core.length
        ? core.length
        : other.core.length;

    for (var i = 0; i < maxLength; i++) {
      final left = i < core.length ? core[i] : 0;
      final right = i < other.core.length ? other.core[i] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }

    if (prerelease.isEmpty && other.prerelease.isNotEmpty) {
      return 1;
    }
    if (prerelease.isNotEmpty && other.prerelease.isEmpty) {
      return -1;
    }
    return prerelease.compareTo(other.prerelease);
  }
}
