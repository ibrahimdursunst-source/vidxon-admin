import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/core/locale/vidxon_product_locales.dart';
import 'package:vidxon_admin/features/campaigns/presentation/popup_campaign_form_dialog.dart';
import 'package:vidxon_admin/features/episodes/domain/media_locale.dart';

void main() {
  test('campaign and media selectors share the same 14 locales', () {
    expect(kSupportedLocales, VidxonProductLocales.all);
    expect(MediaLocale.suggestedLocales, VidxonProductLocales.all);
    expect(kSupportedLocales, hasLength(14));
    expect(kSupportedLocales.toSet(), hasLength(14));
  });

  test('campaign list includes new locales and excludes zh_Hant/ua', () {
    expect(
      kSupportedLocales,
      containsAll(['ru', 'fr', 'uk', 'ms', 'vi', 'zh_Hans', 'th']),
    );
    expect(kSupportedLocales, contains('pt'));
    expect(kSupportedLocales, contains('pt_BR'));
    expect(kSupportedLocales, isNot(contains('zh_Hant')));
    expect(kSupportedLocales, isNot(contains('ua')));
    expect(kSupportedLocales, isNot(contains('zh-Hans')));
  });

  test('display names are unique and include Simplified Chinese', () {
    expect(VidxonProductLocales.displayName('zh_Hans'), '简体中文');
    expect(
      VidxonProductLocales.displayName('pt'),
      isNot(equals(VidxonProductLocales.displayName('pt_BR'))),
    );
    expect(
      VidxonProductLocales.all.map(VidxonProductLocales.displayName).toSet(),
      hasLength(14),
    );
  });
}
