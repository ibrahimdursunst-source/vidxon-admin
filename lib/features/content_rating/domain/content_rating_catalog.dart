/// Stable in-app content age ratings and descriptor ids for admin UI.
///
/// These are Vidxon product labels — not App Store / Google Play ratings.
abstract final class ContentRatingCatalog {
  static const ages = <int?>[null, 13, 16, 18];

  static const descriptorIds = <String>[
    'violence',
    'strong_violence',
    'profanity',
    'mature_themes',
    'sexual_content',
    'substance_references',
    'fear_horror',
  ];

  static String ageLabel(int? age) {
    return switch (age) {
      13 => '13+',
      16 => '16+',
      18 => '18+',
      _ => 'Belirtilmedi',
    };
  }

  static String descriptorLabel(String id) {
    return switch (id) {
      'violence' => 'Şiddet',
      'strong_violence' => 'Yoğun Şiddet',
      'profanity' => 'Kaba Dil',
      'mature_themes' => 'Olgun Temalar',
      'sexual_content' => 'Cinsel İçerik',
      'substance_references' => 'Alkol / Tütün / Uyuşturucu Referansları',
      'fear_horror' => 'Korku / Gerilim',
      _ => id,
    };
  }

  /// Keeps descriptor ids stable and mutually exclusive for violence tiers.
  static List<String> normalizeDescriptors(Iterable<String> selected) {
    final out = <String>[];
    var hasStrong = false;

    for (final raw in selected) {
      final id = raw.trim();
      if (id.isEmpty || !descriptorIds.contains(id)) {
        continue;
      }
      if (id == 'strong_violence') {
        hasStrong = true;
      }
    }

    for (final raw in selected) {
      final id = raw.trim();
      if (id.isEmpty || !descriptorIds.contains(id)) {
        continue;
      }
      if (hasStrong && id == 'violence') {
        continue;
      }
      if (!out.contains(id)) {
        out.add(id);
      }
    }

    return out;
  }

  static int? parseAgeRating(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = value is int
        ? value
        : value is num
        ? value.toInt()
        : int.tryParse(value.toString().trim().replaceAll('+', ''));

    if (parsed == 13 || parsed == 16 || parsed == 18) {
      return parsed;
    }

    return null;
  }

  static List<String> parseDescriptors(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      return const [];
    }

    return normalizeDescriptors(
      value.map((item) => item?.toString() ?? ''),
    );
  }

  /// Episode descriptors: null means inherit; list (including empty) is override.
  static List<String>? parseNullableDescriptors(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is! List) {
      return null;
    }

    return normalizeDescriptors(
      value.map((item) => item?.toString() ?? ''),
    );
  }
}
