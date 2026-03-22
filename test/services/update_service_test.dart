import 'package:caption_trans/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateService.compareVersions', () {
    test('ignores leading v prefix', () {
      expect(UpdateService.compareVersions('v1.2.0', '1.1.9'), greaterThan(0));
    });

    test('treats missing trailing segments as zero', () {
      expect(UpdateService.compareVersions('1.2', '1.2.0'), equals(0));
    });

    test('treats stable releases as newer than prereleases', () {
      expect(
        UpdateService.compareVersions('1.2.0', '1.2.0-beta.1'),
        greaterThan(0),
      );
    });
  });

  group('UpdateService.shouldPerformAutoCheck', () {
    test('returns true when no previous check exists', () {
      expect(UpdateService.shouldPerformAutoCheck(null), isTrue);
    });

    test('returns false within the minimum interval', () {
      final now = DateTime(2026, 3, 22, 12);
      final lastCheckedAt = now.subtract(const Duration(hours: 2));

      expect(
        UpdateService.shouldPerformAutoCheck(lastCheckedAt, now: now),
        isFalse,
      );
    });

    test('returns true after the minimum interval elapses', () {
      final now = DateTime(2026, 3, 22, 12);
      final lastCheckedAt = now.subtract(const Duration(hours: 12));

      expect(
        UpdateService.shouldPerformAutoCheck(lastCheckedAt, now: now),
        isTrue,
      );
    });
  });
}
