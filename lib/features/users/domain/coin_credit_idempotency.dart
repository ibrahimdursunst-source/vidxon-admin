typedef UuidGenerator = String Function();

class CoinCreditIdempotencyManager {
  CoinCreditIdempotencyManager({UuidGenerator? generateUuid})
    : _generateUuid = generateUuid ?? _defaultGenerateUuid;

  final UuidGenerator _generateUuid;

  String? _currentKey;
  String? _payloadFingerprint;

  String? get currentKey => _currentKey;

  String keyForPayload(String payloadFingerprint) {
    if (_currentKey != null && _payloadFingerprint == payloadFingerprint) {
      return _currentKey!;
    }

    _payloadFingerprint = payloadFingerprint;
    _currentKey = _generateUuid();
    return _currentKey!;
  }

  void clear() {
    _currentKey = null;
    _payloadFingerprint = null;
  }

  bool hasKeyForPayload(String payloadFingerprint) {
    return _currentKey != null && _payloadFingerprint == payloadFingerprint;
  }
}

String _defaultGenerateUuid() {
  throw UnsupportedError(
    'CoinCreditIdempotencyManager requires a UUID generator.',
  );
}
