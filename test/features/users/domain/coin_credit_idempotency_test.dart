import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/users/domain/coin_credit_idempotency.dart';

void main() {
  group('CoinCreditIdempotencyManager', () {
    test('generates key on first submit', () {
      var counter = 0;
      final manager = CoinCreditIdempotencyManager(
        generateUuid: () => 'uuid-${++counter}',
      );

      final key = manager.keyForPayload('payload-a');
      expect(key, 'uuid-1');
      expect(manager.currentKey, 'uuid-1');
    });

    test('reuses key for same payload retry', () {
      var counter = 0;
      final manager = CoinCreditIdempotencyManager(
        generateUuid: () => 'uuid-${++counter}',
      );

      final first = manager.keyForPayload('payload-a');
      final second = manager.keyForPayload('payload-a');

      expect(first, second);
      expect(counter, 1);
    });

    test('creates new key when payload changes', () {
      var counter = 0;
      final manager = CoinCreditIdempotencyManager(
        generateUuid: () => 'uuid-${++counter}',
      );

      final first = manager.keyForPayload('payload-a');
      final second = manager.keyForPayload('payload-b');

      expect(first, 'uuid-1');
      expect(second, 'uuid-2');
    });

    test('clears key after success', () {
      final manager = CoinCreditIdempotencyManager(
        generateUuid: () => 'uuid-1',
      );

      manager.keyForPayload('payload-a');
      manager.clear();

      expect(manager.currentKey, isNull);
      expect(manager.hasKeyForPayload('payload-a'), isFalse);
    });
  });
}
