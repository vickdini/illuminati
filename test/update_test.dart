import 'package:flutter_test/flutter_test.dart';
import 'package:illuminati/services/update_service.dart';

void main() {
  test('compares release versions numerically', () {
    expect(UpdateService.isNewer('1.0.1', '1.0.0'), isTrue);
    expect(UpdateService.isNewer('1.10.0', '1.9.9'), isTrue);
    expect(UpdateService.isNewer('2.0', '1.99.99'), isTrue);
    expect(UpdateService.isNewer('1.0.0', '1.0.0'), isFalse);
    expect(UpdateService.isNewer('1.0.0', '1.0.1'), isFalse);
    expect(UpdateService.isNewer('1.0.0+7', '1.0.0+3'), isFalse);
  });

  test('updates are off in builds without a release version', () {
    expect(appVersion, isEmpty);
    expect(UpdateService.enabled, isFalse);
  });
}
