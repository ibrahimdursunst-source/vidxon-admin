import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidxon_admin/core/locale/vidxon_product_locales.dart';
import 'package:vidxon_admin/features/admin_locale/application/admin_locale_controller.dart';
import 'package:vidxon_admin/features/admin_locale/domain/admin_ui_locales.dart';
import 'package:vidxon_admin/features/admin_locale/presentation/admin_language_selector.dart';
import 'package:vidxon_admin/features/admin_locale/presentation/admin_locale_scope.dart';
import 'package:vidxon_admin/features/campaigns/domain/campaign_destination.dart';
import 'package:vidxon_admin/features/dashboard/presentation/admin_home_page.dart';
import 'package:vidxon_admin/l10n/admin_l10n.dart';

import '../content/content_test_helpers.dart';

Widget _app({required AdminLocaleController controller, required Widget home}) {
  return AdminLocaleScope(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          locale: controller.locale,
          supportedLocales: AdminUiLocales.supportedLocales,
          localeResolutionCallback: (_, _) => controller.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default Admin locale is Turkish without a stored preference', () async {
    final controller = AdminLocaleController();
    await controller.load();
    expect(controller.languageCode, AdminUiLocales.tr);
    expect(controller.locale, const Locale('tr'));
  });

  test('invalid stored Admin locale falls back to Turkish', () async {
    SharedPreferences.setMockInitialValues({
      AdminLocaleController.storageKey: 'pt_BR',
    });
    final controller = AdminLocaleController();
    await controller.load();
    expect(controller.languageCode, AdminUiLocales.tr);
  });

  test('selected Admin locale is persisted and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final first = AdminLocaleController();
    await first.load();
    await first.setLanguageCode(AdminUiLocales.en);
    expect(first.languageCode, AdminUiLocales.en);

    final restored = AdminLocaleController();
    await restored.load();
    expect(restored.languageCode, AdminUiLocales.en);
  });

  test('Admin UI locale is independent from product/content locales', () async {
    final controller = AdminLocaleController();
    await controller.load();
    await controller.setLanguageCode(AdminUiLocales.en);

    expect(VidxonProductLocales.all, [
      'tr',
      'en',
      'es',
      'pt',
      'pt_BR',
      'ar',
      'id',
      'ru',
      'fr',
      'uk',
      'ms',
      'vi',
      'zh_Hans',
      'th',
    ]);
    expect(VidxonProductLocales.all.contains('pt'), isTrue);
    expect(VidxonProductLocales.all.contains('pt_BR'), isTrue);
    expect(VidxonProductLocales.all.contains('zh_Hans'), isTrue);
    expect(VidxonProductLocales.all.contains('uk'), isTrue);
    expect(VidxonProductLocales.all.contains('zh'), isFalse);
    expect(controller.languageCode, AdminUiLocales.en);
  });

  test('campaign destination stored values remain unchanged', () {
    expect(CampaignDestinationType.all, [
      CampaignDestinationType.none,
      CampaignDestinationType.series,
      CampaignDestinationType.episode,
      CampaignDestinationType.coinPurchase,
      CampaignDestinationType.membership,
    ]);
    expect(CampaignDestinationType.all, isNot(contains('home')));
    expect(CampaignDestinationType.all, isNot(contains('url')));
    expect(kCampaignDestinationOptions.map((item) => item.value), [
      'none',
      'series',
      'episode',
      'coin_purchase',
      'membership',
    ]);
  });

  testWidgets('Admin starts in Turkish and can switch to English and back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AdminLocaleController();
    await controller.load();

    await tester.pumpWidget(
      _app(
        controller: controller,
        home: AdminHomePage(
          email: 'admin@example.com',
          dashboardRepository: FakeDashboardRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Genel Bakış'), findsWidgets);
    expect(find.text('Overview'), findsNothing);
    expect(find.byKey(const Key('admin-ui-language-selector')), findsOneWidget);

    await controller.setLanguageCode(AdminUiLocales.en);
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Genel Bakış'), findsNothing);
    expect(find.byType(AdminHomePage), findsOneWidget);
    expect(find.byType(AdminLanguageSelector), findsOneWidget);

    await controller.setLanguageCode(AdminUiLocales.tr);
    await tester.pumpAndSettle();

    expect(find.text('Genel Bakış'), findsWidgets);
    expect(find.text('Overview'), findsNothing);
    expect(find.byType(AdminHomePage), findsOneWidget);
  });

  test('presentation helpers map stable values in Turkish and English', () {
    final tr = lookupAppLocalizations(const Locale('tr'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(adminSeriesStatusLabel(tr, 'ongoing'), 'Devam Ediyor');
    expect(adminSeriesStatusLabel(en, 'ongoing'), 'Ongoing');
    expect(adminPartnerStatusLabel(tr, 'suspended'), 'Askıda');
    expect(adminPartnerStatusLabel(en, 'suspended'), 'Suspended');
    expect(adminCampaignStatusLabel(tr, 'Gönderiliyor'), 'Gönderiliyor');
    expect(adminCampaignStatusLabel(en, 'Gönderiliyor'), 'Sending');
    expect(adminVideoStatusLabel(tr, 'Video Hazır'), 'Video Hazır');
    expect(adminVideoStatusLabel(en, 'Video Hazır'), 'Video Ready');
    expect(
      adminAuditActionLabel(tr, 'content.series_published'),
      'Dizi Yayınlandı',
    );
    expect(
      adminAuditActionLabel(en, 'content.series_published'),
      'Series Published',
    );
    expect(adminCoinCreditReasonLabel(tr, 'event_reward'), 'Etkinlik Ödülü');
    expect(adminCoinCreditReasonLabel(en, 'event_reward'), 'Event Reward');
    expect(adminDestinationTypeLabel(en, 'coin_purchase'), 'Buy Coins');
    expect(adminDestinationTypeLabel(tr, 'coin_purchase'), 'Jeton Satın Al');
  });

  testWidgets(
    'representative remaining screens switch labels with Admin locale',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = AdminLocaleController();
      await controller.load();

      await tester.pumpWidget(
        _app(
          controller: controller,
          home: AdminHomePage(
            email: 'admin@example.com',
            dashboardRepository: FakeDashboardRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

    expect(find.text('Kullanıcılar'), findsWidgets);
    expect(find.text('Partnerler'), findsWidgets);
    expect(find.text('İşlem Kayıtları'), findsWidgets);

    await controller.setLanguageCode(AdminUiLocales.en);
    await tester.pumpAndSettle();

    expect(find.text('Users'), findsWidgets);
    expect(find.text('Partners'), findsWidgets);
    expect(find.text('Activity Log'), findsWidgets);
      expect(find.byType(AdminHomePage), findsOneWidget);

      await controller.setLanguageCode(AdminUiLocales.tr);
      await tester.pumpAndSettle();

      expect(find.text('Kullanıcılar'), findsWidgets);
      expect(find.byType(AdminHomePage), findsOneWidget);
    },
  );
}
