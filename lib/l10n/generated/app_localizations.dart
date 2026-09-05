import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vidxon Admin'**
  String get appTitle;

  /// No description provided for @appBrand.
  ///
  /// In tr, this message translates to:
  /// **'VIDXON'**
  String get appBrand;

  /// No description provided for @appBrandAdmin.
  ///
  /// In tr, this message translates to:
  /// **'VIDXON ADMIN'**
  String get appBrandAdmin;

  /// No description provided for @adminPanel.
  ///
  /// In tr, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @missingSupabaseConfig.
  ///
  /// In tr, this message translates to:
  /// **'Supabase bağlantı bilgileri eksik.\n\nUygulamayı SUPABASE_URL ve SUPABASE_PUBLISHABLE_KEY değerleriyle çalıştır.'**
  String get missingSupabaseConfig;

  /// No description provided for @loginUnexpectedError.
  ///
  /// In tr, this message translates to:
  /// **'Giriş sırasında beklenmeyen bir hata oluştu.'**
  String get loginUnexpectedError;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @emailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresini gir.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifreni gir.'**
  String get passwordRequired;

  /// No description provided for @signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get signOut;

  /// No description provided for @authorizationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yetki kontrolü başarısız'**
  String get authorizationFailed;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @accessDenied.
  ///
  /// In tr, this message translates to:
  /// **'Erişim reddedildi'**
  String get accessDenied;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesap Vidxon admin kullanıcıları arasında bulunmuyor.'**
  String get accessDeniedMessage;

  /// No description provided for @adminContextLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Admin oturum bilgisi yüklenemedi.'**
  String get adminContextLoadFailed;

  /// No description provided for @navOverview.
  ///
  /// In tr, this message translates to:
  /// **'Genel Bakış'**
  String get navOverview;

  /// No description provided for @navSeries.
  ///
  /// In tr, this message translates to:
  /// **'Diziler'**
  String get navSeries;

  /// No description provided for @navUsers.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar'**
  String get navUsers;

  /// No description provided for @navAudit.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Kayıtları'**
  String get navAudit;

  /// No description provided for @navPartners.
  ///
  /// In tr, this message translates to:
  /// **'Partnerler'**
  String get navPartners;

  /// No description provided for @navCampaigns.
  ///
  /// In tr, this message translates to:
  /// **'Kampanyalar'**
  String get navCampaigns;

  /// No description provided for @navAdmins.
  ///
  /// In tr, this message translates to:
  /// **'Yöneticiler'**
  String get navAdmins;

  /// No description provided for @navEpisodes.
  ///
  /// In tr, this message translates to:
  /// **'Bölümler'**
  String get navEpisodes;

  /// No description provided for @navCategories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get navCategories;

  /// No description provided for @navMedia.
  ///
  /// In tr, this message translates to:
  /// **'Medya'**
  String get navMedia;

  /// No description provided for @refresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get refresh;

  /// No description provided for @comingSoonSection.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm yakında eklenecek.'**
  String get comingSoonSection;

  /// No description provided for @dataLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yüklenemedi'**
  String get dataLoadFailed;

  /// No description provided for @overviewSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik istatistiklerinin özeti'**
  String get overviewSubtitle;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @dismiss.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get dismiss;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @create.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get create;

  /// No description provided for @update.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get update;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get remove;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @loadMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha Fazla Yükle'**
  String get loadMore;

  /// No description provided for @published.
  ///
  /// In tr, this message translates to:
  /// **'Yayında'**
  String get published;

  /// No description provided for @notPublished.
  ///
  /// In tr, this message translates to:
  /// **'Yayında Değil'**
  String get notPublished;

  /// No description provided for @draft.
  ///
  /// In tr, this message translates to:
  /// **'Taslak'**
  String get draft;

  /// No description provided for @archived.
  ///
  /// In tr, this message translates to:
  /// **'Arşivlenmiş'**
  String get archived;

  /// No description provided for @archive.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv'**
  String get archive;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get inactive;

  /// No description provided for @scheduled.
  ///
  /// In tr, this message translates to:
  /// **'Planlanmış'**
  String get scheduled;

  /// No description provided for @expired.
  ///
  /// In tr, this message translates to:
  /// **'Süresi Dolmuş'**
  String get expired;

  /// No description provided for @statusOngoing.
  ///
  /// In tr, this message translates to:
  /// **'Devam Ediyor'**
  String get statusOngoing;

  /// No description provided for @statusCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get statusCompleted;

  /// No description provided for @statusComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get statusComingSoon;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @allStatuses.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Durumlar'**
  String get allStatuses;

  /// No description provided for @free.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get free;

  /// No description provided for @destinationType.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Türü'**
  String get destinationType;

  /// No description provided for @destinationNone.
  ///
  /// In tr, this message translates to:
  /// **'Bilgilendirme'**
  String get destinationNone;

  /// No description provided for @destinationSeries.
  ///
  /// In tr, this message translates to:
  /// **'Dizi'**
  String get destinationSeries;

  /// No description provided for @destinationEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm'**
  String get destinationEpisode;

  /// No description provided for @destinationCoinPurchase.
  ///
  /// In tr, this message translates to:
  /// **'Jeton Satın Al'**
  String get destinationCoinPurchase;

  /// No description provided for @destinationMembership.
  ///
  /// In tr, this message translates to:
  /// **'Üyelik'**
  String get destinationMembership;

  /// No description provided for @priority.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get priority;

  /// No description provided for @priorityHelper.
  ///
  /// In tr, this message translates to:
  /// **'Aynı anda birden fazla uygun kampanya varsa, daha yüksek öncelikli kampanya önce gösterilir. Eşit öncelikte daha yeni başlangıç tarihi kazanır. Varsayılan: 0.'**
  String get priorityHelper;

  /// No description provided for @changeSeries.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Değiştir'**
  String get changeSeries;

  /// No description provided for @changeEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Değiştir'**
  String get changeEpisode;

  /// No description provided for @searchSeries.
  ///
  /// In tr, this message translates to:
  /// **'Dizi ara'**
  String get searchSeries;

  /// No description provided for @titleOrSlug.
  ///
  /// In tr, this message translates to:
  /// **'Başlık veya slug'**
  String get titleOrSlug;

  /// No description provided for @noMatchingSeries.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşen dizi yok'**
  String get noMatchingSeries;

  /// No description provided for @seriesUnavailableBanner.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı dizi artık kullanılamıyor. Mevcut hedef korunur; yeni bir dizi seçmezseniz önceki hedef değişmez.'**
  String get seriesUnavailableBanner;

  /// No description provided for @episodeUnavailableBanner.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı bölüm artık kullanılamıyor. Mevcut hedef korunur; yeni bir bölüm seçmezseniz önceki hedef değişmez.'**
  String get episodeUnavailableBanner;

  /// No description provided for @selectSeriesFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir dizi seçin.'**
  String get selectSeriesFirst;

  /// No description provided for @episodesLoading.
  ///
  /// In tr, this message translates to:
  /// **'Bölümler yükleniyor...'**
  String get episodesLoading;

  /// No description provided for @episodesLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bölümler yüklenemedi.'**
  String get episodesLoadFailed;

  /// No description provided for @episodesEmptyForSeries.
  ///
  /// In tr, this message translates to:
  /// **'Bu dizide henüz bölüm bulunmuyor.'**
  String get episodesEmptyForSeries;

  /// No description provided for @selectEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm seçin'**
  String get selectEpisode;

  /// No description provided for @episodePickerLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm {number} · {title}'**
  String episodePickerLabel(int number, String title);

  /// No description provided for @episodePickerNumberOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm {number}'**
  String episodePickerNumberOnly(int number);

  /// No description provided for @selectSeries.
  ///
  /// In tr, this message translates to:
  /// **'Dizi seçin'**
  String get selectSeries;

  /// No description provided for @campaigns.
  ///
  /// In tr, this message translates to:
  /// **'Kampanyalar'**
  String get campaigns;

  /// No description provided for @popupTab.
  ///
  /// In tr, this message translates to:
  /// **'Pop-up\'lar'**
  String get popupTab;

  /// No description provided for @pushTab.
  ///
  /// In tr, this message translates to:
  /// **'Push Bildirimleri'**
  String get pushTab;

  /// No description provided for @editPopup.
  ///
  /// In tr, this message translates to:
  /// **'Pop-up Düzenle'**
  String get editPopup;

  /// No description provided for @createPopup.
  ///
  /// In tr, this message translates to:
  /// **'Pop-up Oluştur'**
  String get createPopup;

  /// No description provided for @newPopup.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Pop-up'**
  String get newPopup;

  /// No description provided for @newPush.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Push Bildirimi'**
  String get newPush;

  /// No description provided for @schedule.
  ///
  /// In tr, this message translates to:
  /// **'Zamanlama'**
  String get schedule;

  /// No description provided for @messageForLocaleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj ({locale}) *'**
  String messageForLocaleRequired(String locale);

  /// No description provided for @messageRequired.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj zorunlu'**
  String get messageRequired;

  /// No description provided for @ctaRequired.
  ///
  /// In tr, this message translates to:
  /// **'CTA zorunlu'**
  String get ctaRequired;

  /// No description provided for @ctaButtonForLocale.
  ///
  /// In tr, this message translates to:
  /// **'CTA Butonu ({locale})'**
  String ctaButtonForLocale(String locale);

  /// No description provided for @ctaButtonForLocaleRequired.
  ///
  /// In tr, this message translates to:
  /// **'CTA Butonu ({locale}) *'**
  String ctaButtonForLocaleRequired(String locale);

  /// No description provided for @image.
  ///
  /// In tr, this message translates to:
  /// **'Görsel'**
  String get image;

  /// No description provided for @targetLanguages.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Diller'**
  String get targetLanguages;

  /// No description provided for @startsAt.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get startsAt;

  /// No description provided for @endsAtOptional.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş (opsiyonel)'**
  String get endsAtOptional;

  /// No description provided for @endsAt.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get endsAt;

  /// No description provided for @imageUploadingWait.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yükleniyor, lütfen bekleyin.'**
  String get imageUploadingWait;

  /// No description provided for @imageUploadMustFinish.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yüklemesi tamamlanmadan kaydedilemez.'**
  String get imageUploadMustFinish;

  /// No description provided for @imageFileUnreadable.
  ///
  /// In tr, this message translates to:
  /// **'Görsel dosyası okunamadı.'**
  String get imageFileUnreadable;

  /// No description provided for @imageUploadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yüklenemedi.'**
  String get imageUploadFailed;

  /// No description provided for @imageUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yüklendi'**
  String get imageUploaded;

  /// No description provided for @imageNotSelectedOptional.
  ///
  /// In tr, this message translates to:
  /// **'Görsel seçilmedi (opsiyonel)'**
  String get imageNotSelectedOptional;

  /// No description provided for @changeImage.
  ///
  /// In tr, this message translates to:
  /// **'Görseli Değiştir'**
  String get changeImage;

  /// No description provided for @uploadImage.
  ///
  /// In tr, this message translates to:
  /// **'Görsel Yükle'**
  String get uploadImage;

  /// No description provided for @removeImage.
  ///
  /// In tr, this message translates to:
  /// **'Görseli Kaldır'**
  String get removeImage;

  /// No description provided for @noPopupCampaigns.
  ///
  /// In tr, this message translates to:
  /// **'Henüz pop-up kampanyası oluşturulmadı.'**
  String get noPopupCampaigns;

  /// No description provided for @title.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get title;

  /// No description provided for @titleRequiredStar.
  ///
  /// In tr, this message translates to:
  /// **'Başlık *'**
  String get titleRequiredStar;

  /// No description provided for @titleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık zorunludur.'**
  String get titleRequired;

  /// No description provided for @titleRequiredShort.
  ///
  /// In tr, this message translates to:
  /// **'Başlık zorunlu'**
  String get titleRequiredShort;

  /// No description provided for @titleForLocaleRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlık ({locale}) *'**
  String titleForLocaleRequired(String locale);

  /// No description provided for @descriptionForLocale.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama ({locale})'**
  String descriptionForLocale(String locale);

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @languages.
  ///
  /// In tr, this message translates to:
  /// **'Diller'**
  String get languages;

  /// No description provided for @target.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get target;

  /// No description provided for @editPush.
  ///
  /// In tr, this message translates to:
  /// **'Push Düzenle'**
  String get editPush;

  /// No description provided for @createPush.
  ///
  /// In tr, this message translates to:
  /// **'Push Oluştur'**
  String get createPush;

  /// No description provided for @delivery.
  ///
  /// In tr, this message translates to:
  /// **'Gönderim'**
  String get delivery;

  /// No description provided for @chooseSchedule.
  ///
  /// In tr, this message translates to:
  /// **'Zamanlama Seç'**
  String get chooseSchedule;

  /// No description provided for @saveDraft.
  ///
  /// In tr, this message translates to:
  /// **'Taslak Kaydet'**
  String get saveDraft;

  /// No description provided for @sendPush.
  ///
  /// In tr, this message translates to:
  /// **'Push Gönder'**
  String get sendPush;

  /// No description provided for @sendPushConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" kampanyasını şimdi göndermek istiyor musunuz?'**
  String sendPushConfirm(String title);

  /// No description provided for @send.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get send;

  /// No description provided for @pushSendStarted.
  ///
  /// In tr, this message translates to:
  /// **'Push gönderimi başlatıldı.'**
  String get pushSendStarted;

  /// No description provided for @noPushCampaigns.
  ///
  /// In tr, this message translates to:
  /// **'Henüz push bildirimi oluşturulmadı.'**
  String get noPushCampaigns;

  /// No description provided for @planOrDelivery.
  ///
  /// In tr, this message translates to:
  /// **'Plan/Gönderim'**
  String get planOrDelivery;

  /// No description provided for @sent.
  ///
  /// In tr, this message translates to:
  /// **'Gönderildi'**
  String get sent;

  /// No description provided for @failed.
  ///
  /// In tr, this message translates to:
  /// **'Başarısız'**
  String get failed;

  /// No description provided for @sendNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Gönder'**
  String get sendNow;

  /// No description provided for @cancelAction.
  ///
  /// In tr, this message translates to:
  /// **'İptal Et'**
  String get cancelAction;

  /// No description provided for @contentRating.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Derecelendirmesi'**
  String get contentRating;

  /// No description provided for @contentRatingDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bunlar Vidxon uygulama içi uygunluk etiketleridir; App Store / Google Play derecelendirmelerinin yerine geçmez.'**
  String get contentRatingDisclaimer;

  /// No description provided for @ageRating.
  ///
  /// In tr, this message translates to:
  /// **'Yaş Derecesi'**
  String get ageRating;

  /// No description provided for @contentDescriptors.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Tanımlayıcıları'**
  String get contentDescriptors;

  /// No description provided for @validCoinPrice.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir coin fiyatı girin.'**
  String get validCoinPrice;

  /// No description provided for @validEpisodeNumber.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir bölüm numarası girin.'**
  String get validEpisodeNumber;

  /// No description provided for @episodeUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm başarıyla güncellendi.'**
  String get episodeUpdated;

  /// No description provided for @episodeCreated.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm başarıyla oluşturuldu.'**
  String get episodeCreated;

  /// No description provided for @unexpectedRetry.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'**
  String get unexpectedRetry;

  /// No description provided for @editEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Bölümü Düzenle'**
  String get editEpisode;

  /// No description provided for @newEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Bölüm'**
  String get newEpisode;

  /// No description provided for @episodeNumberStar.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Numarası *'**
  String get episodeNumberStar;

  /// No description provided for @episodeNumberReorderHint.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm numarası sıralama ekranından değiştirilir.'**
  String get episodeNumberReorderHint;

  /// No description provided for @episodeNumberMustBePositive.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm numarası 0\'dan büyük olmalıdır.'**
  String get episodeNumberMustBePositive;

  /// No description provided for @useDifferentRatingForEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm için farklı derecelendirme kullan'**
  String get useDifferentRatingForEpisode;

  /// No description provided for @episodeSpecificRating.
  ///
  /// In tr, this message translates to:
  /// **'Bölüme özel derecelendirme'**
  String get episodeSpecificRating;

  /// No description provided for @useSeriesRating.
  ///
  /// In tr, this message translates to:
  /// **'Dizi derecelendirmesini kullan'**
  String get useSeriesRating;

  /// No description provided for @inheritDescriptorsFromSeries.
  ///
  /// In tr, this message translates to:
  /// **'Tanımlayıcıları diziden miras al'**
  String get inheritDescriptorsFromSeries;

  /// No description provided for @seriesDescriptorsUsed.
  ///
  /// In tr, this message translates to:
  /// **'Dizi tanımlayıcıları kullanılır'**
  String get seriesDescriptorsUsed;

  /// No description provided for @episodeNoDescriptors.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölümde tanımlayıcı yok (açık boş liste)'**
  String get episodeNoDescriptors;

  /// No description provided for @episodeSpecificDescriptors.
  ///
  /// In tr, this message translates to:
  /// **'Bölüme özel tanımlayıcı listesi'**
  String get episodeSpecificDescriptors;

  /// No description provided for @freeEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz Bölüm'**
  String get freeEpisode;

  /// No description provided for @coinPrice.
  ///
  /// In tr, this message translates to:
  /// **'Coin Fiyatı'**
  String get coinPrice;

  /// No description provided for @coinPriceNotNegative.
  ///
  /// In tr, this message translates to:
  /// **'Coin fiyatı negatif olamaz.'**
  String get coinPriceNotNegative;

  /// No description provided for @coinPriceMax.
  ///
  /// In tr, this message translates to:
  /// **'Coin fiyatı en fazla {max} olabilir.'**
  String coinPriceMax(int max);

  /// No description provided for @freeEpisodeCoinMustBeZero.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz bölümlerde coin fiyatı 0 olmalıdır.'**
  String get freeEpisodeCoinMustBeZero;

  /// No description provided for @releaseDate.
  ///
  /// In tr, this message translates to:
  /// **'Yayın Tarihi'**
  String get releaseDate;

  /// No description provided for @notSelected.
  ///
  /// In tr, this message translates to:
  /// **'Seçilmedi'**
  String get notSelected;

  /// No description provided for @publishStatus.
  ///
  /// In tr, this message translates to:
  /// **'Yayın Durumu'**
  String get publishStatus;

  /// No description provided for @status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get status;

  /// No description provided for @video.
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @pendingVideo.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Video'**
  String get pendingVideo;

  /// No description provided for @qualifiedViews.
  ///
  /// In tr, this message translates to:
  /// **'Nitelikli İzlenme'**
  String get qualifiedViews;

  /// No description provided for @legacyCounterSeed.
  ///
  /// In tr, this message translates to:
  /// **'Eski Sayaç (seed)'**
  String get legacyCounterSeed;

  /// No description provided for @mediaTracksLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Medya parçaları yüklenemedi. Lütfen tekrar deneyin.'**
  String get mediaTracksLoadFailed;

  /// No description provided for @invalidLocaleExample.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz dil kodu. Örnek: tr, en, pt_BR, zh_Hans.'**
  String get invalidLocaleExample;

  /// No description provided for @originalAudioUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Orijinal ses dili güncellendi.'**
  String get originalAudioUpdated;

  /// No description provided for @audioUploadAccepted.
  ///
  /// In tr, this message translates to:
  /// **'Ses parçası yükleme isteği alındı.'**
  String get audioUploadAccepted;

  /// No description provided for @audioReplaceAccepted.
  ///
  /// In tr, this message translates to:
  /// **'Ses parçası değiştirme isteği alındı.'**
  String get audioReplaceAccepted;

  /// No description provided for @subtitleUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı yüklendi.'**
  String get subtitleUploaded;

  /// No description provided for @subtitleReplaced.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı değiştirildi.'**
  String get subtitleReplaced;

  /// No description provided for @removeAudioTrack.
  ///
  /// In tr, this message translates to:
  /// **'Ses parçasını kaldır'**
  String get removeAudioTrack;

  /// No description provided for @removeAudioTrackConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{locale} dilindeki dublaj kaldırılsın mı?'**
  String removeAudioTrackConfirm(String locale);

  /// No description provided for @audioTrackRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Ses parçası kaldırıldı.'**
  String get audioTrackRemoved;

  /// No description provided for @audioTrackRemoveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ses parçası kaldırılamadı.'**
  String get audioTrackRemoveFailed;

  /// No description provided for @removeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Altyazıyı kaldır'**
  String get removeSubtitle;

  /// No description provided for @removeSubtitleConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{locale} dilindeki altyazı kaldırılsın mı?'**
  String removeSubtitleConfirm(String locale);

  /// No description provided for @subtitleRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı kaldırıldı.'**
  String get subtitleRemoved;

  /// No description provided for @subtitleRemoveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı kaldırılamadı.'**
  String get subtitleRemoveFailed;

  /// No description provided for @statusUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Durum güncellenemedi.'**
  String get statusUpdateFailed;

  /// No description provided for @audioSubtitles.
  ///
  /// In tr, this message translates to:
  /// **'Ses / Altyazı'**
  String get audioSubtitles;

  /// No description provided for @originalAudioHelp.
  ///
  /// In tr, this message translates to:
  /// **'Videonun gömülü program sesinin dili. Dublaj dilleri bu değerden farklı olmalıdır.'**
  String get originalAudioHelp;

  /// No description provided for @noDubsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz dublaj yok.'**
  String get noDubsYet;

  /// No description provided for @subtitles.
  ///
  /// In tr, this message translates to:
  /// **'Altyazılar'**
  String get subtitles;

  /// No description provided for @noSubtitlesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz altyazı yok.'**
  String get noSubtitlesYet;

  /// No description provided for @episodeDurationSeconds.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm süresi: {seconds}s'**
  String episodeDurationSeconds(int seconds);

  /// No description provided for @localeCode.
  ///
  /// In tr, this message translates to:
  /// **'Dil kodu'**
  String get localeCode;

  /// No description provided for @updateStatus.
  ///
  /// In tr, this message translates to:
  /// **'Durumu Güncelle'**
  String get updateStatus;

  /// No description provided for @replace.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get replace;

  /// No description provided for @dubCannotMatchOriginal.
  ///
  /// In tr, this message translates to:
  /// **'Dublaj dili orijinal ses diliyle aynı olamaz.'**
  String get dubCannotMatchOriginal;

  /// No description provided for @severeDurationNeedsConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Ciddi süre farkı için onay kutusu işaretlenmeden yükleme yapılamaz.'**
  String get severeDurationNeedsConfirm;

  /// No description provided for @uploadFailedRetry.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme başarısız oldu. Lütfen tekrar deneyin.'**
  String get uploadFailedRetry;

  /// No description provided for @replaceAudioTrack.
  ///
  /// In tr, this message translates to:
  /// **'Ses parçasını değiştir'**
  String get replaceAudioTrack;

  /// No description provided for @addAudioTrack.
  ///
  /// In tr, this message translates to:
  /// **'Ses parçası ekle'**
  String get addAudioTrack;

  /// No description provided for @audioDurationSeconds.
  ///
  /// In tr, this message translates to:
  /// **'Ses süresi (saniye)'**
  String get audioDurationSeconds;

  /// No description provided for @audioDurationHint.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm süresiyle karşılaştırmak için girin'**
  String get audioDurationHint;

  /// No description provided for @severeDurationConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Süre farkının ciddi olduğunu ve yine de yüklemek istediğimi onaylıyorum.'**
  String get severeDurationConfirm;

  /// No description provided for @selectAudioFile.
  ///
  /// In tr, this message translates to:
  /// **'Ses dosyası seç (MP3 / M4A / AAC)'**
  String get selectAudioFile;

  /// No description provided for @upload.
  ///
  /// In tr, this message translates to:
  /// **'Yükle'**
  String get upload;

  /// No description provided for @replaceSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Altyazıyı değiştir'**
  String get replaceSubtitle;

  /// No description provided for @addSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı ekle'**
  String get addSubtitle;

  /// No description provided for @selectWebvtt.
  ///
  /// In tr, this message translates to:
  /// **'WebVTT (.vtt) seç'**
  String get selectWebvtt;

  /// No description provided for @previewLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme yüklenemedi.'**
  String get previewLoadFailed;

  /// No description provided for @pendingVideoPreview.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Video Önizleme'**
  String get pendingVideoPreview;

  /// No description provided for @activeVideoPreview.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Video Önizleme'**
  String get activeVideoPreview;

  /// No description provided for @noActiveVideo.
  ///
  /// In tr, this message translates to:
  /// **'Aktif video bulunmuyor.'**
  String get noActiveVideo;

  /// No description provided for @activeVideoNotReady.
  ///
  /// In tr, this message translates to:
  /// **'Aktif video henüz önizlemeye hazır değil.'**
  String get activeVideoNotReady;

  /// No description provided for @pendingVideoNotReady.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen video henüz önizlemeye hazır değil.'**
  String get pendingVideoNotReady;

  /// No description provided for @previewWebOnly.
  ///
  /// In tr, this message translates to:
  /// **'Video önizleme yalnızca web ortamında desteklenir.'**
  String get previewWebOnly;

  /// No description provided for @reorderSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama kaydedilemedi.'**
  String get reorderSaveFailed;

  /// No description provided for @reorderLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Güncel sıralama yüklenemedi. Lütfen sayfayı kapatıp tekrar deneyin.'**
  String get reorderLoadFailed;

  /// No description provided for @unsavedReorder.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilmemiş sıralama'**
  String get unsavedReorder;

  /// No description provided for @unsavedReorderMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama değişiklikleri kaydedilmedi. Çıkmak istiyor musunuz?'**
  String get unsavedReorderMessage;

  /// No description provided for @leave.
  ///
  /// In tr, this message translates to:
  /// **'Çık'**
  String get leave;

  /// No description provided for @episodeOrder.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Sıralaması'**
  String get episodeOrder;

  /// No description provided for @saveOrder.
  ///
  /// In tr, this message translates to:
  /// **'Sıralamayı Kaydet'**
  String get saveOrder;

  /// No description provided for @manageSeriesEpisodes.
  ///
  /// In tr, this message translates to:
  /// **'Seçili dizinin bölümlerini yönetin'**
  String get manageSeriesEpisodes;

  /// No description provided for @editOrder.
  ///
  /// In tr, this message translates to:
  /// **'Sıralamayı Düzenle'**
  String get editOrder;

  /// No description provided for @access.
  ///
  /// In tr, this message translates to:
  /// **'Erişim'**
  String get access;

  /// No description provided for @publish.
  ///
  /// In tr, this message translates to:
  /// **'Yayın'**
  String get publish;

  /// No description provided for @actions.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get actions;

  /// No description provided for @releaseAtLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yayın: {value}'**
  String releaseAtLabel(String value);

  /// No description provided for @noEpisodesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bölüm yok'**
  String get noEpisodesYet;

  /// No description provided for @createFirstEpisode.
  ///
  /// In tr, this message translates to:
  /// **'Bu dizi için ilk bölümü oluşturabilirsiniz.'**
  String get createFirstEpisode;

  /// No description provided for @episodesLoadFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölümler yüklenemedi'**
  String get episodesLoadFailedTitle;

  /// No description provided for @validatingForm.
  ///
  /// In tr, this message translates to:
  /// **'Form doğrulanıyor'**
  String get validatingForm;

  /// No description provided for @preparingUploadLink.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme bağlantısı hazırlanıyor'**
  String get preparingUploadLink;

  /// No description provided for @uploadingPoster.
  ///
  /// In tr, this message translates to:
  /// **'Poster yükleniyor'**
  String get uploadingPoster;

  /// No description provided for @savingSeries.
  ///
  /// In tr, this message translates to:
  /// **'Dizi kaydediliyor'**
  String get savingSeries;

  /// No description provided for @posterUnreadable.
  ///
  /// In tr, this message translates to:
  /// **'Poster dosyası okunamadı.'**
  String get posterUnreadable;

  /// No description provided for @posterRequired.
  ///
  /// In tr, this message translates to:
  /// **'Poster seçimi zorunludur.'**
  String get posterRequired;

  /// No description provided for @posterPathFailed.
  ///
  /// In tr, this message translates to:
  /// **'Poster yolu oluşturulamadı.'**
  String get posterPathFailed;

  /// No description provided for @seriesCreated.
  ///
  /// In tr, this message translates to:
  /// **'Dizi başarıyla oluşturuldu.'**
  String get seriesCreated;

  /// No description provided for @posterAlreadyUploadedRetry.
  ///
  /// In tr, this message translates to:
  /// **'Poster zaten yüklendi. Bilgileri düzenleyip tekrar deneyebilirsiniz.'**
  String get posterAlreadyUploadedRetry;

  /// No description provided for @seriesCreatedPartnerFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dizi oluşturuldu ancak Partner ataması başarısız: {message}'**
  String seriesCreatedPartnerFailed(String message);

  /// No description provided for @seriesCreatedRetryPartner.
  ///
  /// In tr, this message translates to:
  /// **'Dizi kaydı oluştu. Partner atamasını dizi detayından yeniden deneyin.'**
  String get seriesCreatedRetryPartner;

  /// No description provided for @posterAlreadyUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Poster zaten yüklendi. Tekrar deneyebilirsiniz.'**
  String get posterAlreadyUploaded;

  /// No description provided for @newSeries.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Dizi'**
  String get newSeries;

  /// No description provided for @slugHint.
  ///
  /// In tr, this message translates to:
  /// **'Küçük harf, rakam ve tire'**
  String get slugHint;

  /// No description provided for @validSlug.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir slug girin.'**
  String get validSlug;

  /// No description provided for @selectDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Seç'**
  String get selectDate;

  /// No description provided for @selectPoster.
  ///
  /// In tr, this message translates to:
  /// **'Poster Seç'**
  String get selectPoster;

  /// No description provided for @publishSettings.
  ///
  /// In tr, this message translates to:
  /// **'Yayın Ayarları'**
  String get publishSettings;

  /// No description provided for @featured.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan'**
  String get featured;

  /// No description provided for @collaborationPartner.
  ///
  /// In tr, this message translates to:
  /// **'İş Birliği Ortağı'**
  String get collaborationPartner;

  /// No description provided for @categories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get categories;

  /// No description provided for @categoriesLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler yüklenemedi.'**
  String get categoriesLoadFailed;

  /// No description provided for @noCategoriesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kategori bulunmuyor.'**
  String get noCategoriesYet;

  /// No description provided for @createSeries.
  ///
  /// In tr, this message translates to:
  /// **'Diziyi Oluştur'**
  String get createSeries;

  /// No description provided for @seriesLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dizi yüklenemedi.'**
  String get seriesLoadFailed;

  /// No description provided for @assignmentHistoryLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Atama geçmişi yüklenemedi.'**
  String get assignmentHistoryLoadFailed;

  /// No description provided for @removePartnerAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Partner atamasını kaldır'**
  String get removePartnerAssignment;

  /// No description provided for @changePartnerAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Partner atamasını değiştir'**
  String get changePartnerAssignment;

  /// No description provided for @removeAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Atamayı Kaldır'**
  String get removeAssignment;

  /// No description provided for @changeAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Atamayı Değiştir'**
  String get changeAssignment;

  /// No description provided for @seriesUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Dizi güncellendi.'**
  String get seriesUpdated;

  /// No description provided for @seriesUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dizi güncellenemedi.'**
  String get seriesUpdateFailed;

  /// No description provided for @posterUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Poster güncellendi.'**
  String get posterUpdated;

  /// No description provided for @posterUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Poster güncellenemedi.'**
  String get posterUpdateFailed;

  /// No description provided for @actionIncomplete.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı.'**
  String get actionIncomplete;

  /// No description provided for @publishSeries.
  ///
  /// In tr, this message translates to:
  /// **'Yayınla'**
  String get publishSeries;

  /// No description provided for @publishSeriesConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu dizi yayına alınsın mı?'**
  String get publishSeriesConfirm;

  /// No description provided for @seriesPublished.
  ///
  /// In tr, this message translates to:
  /// **'Dizi yayınlandı.'**
  String get seriesPublished;

  /// No description provided for @unpublish.
  ///
  /// In tr, this message translates to:
  /// **'Yayından Kaldır'**
  String get unpublish;

  /// No description provided for @unpublishSeriesConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu dizi yayından kaldırılsın mı?'**
  String get unpublishSeriesConfirm;

  /// No description provided for @seriesUnpublished.
  ///
  /// In tr, this message translates to:
  /// **'Dizi yayından kaldırıldı.'**
  String get seriesUnpublished;

  /// No description provided for @archiveAction.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get archiveAction;

  /// No description provided for @archiveSeriesConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu dizi arşivlenecek. Arşivlenmiş içerik yayından kaldırılır ve düzenleme kısıtlanabilir.'**
  String get archiveSeriesConfirm;

  /// No description provided for @seriesArchived.
  ///
  /// In tr, this message translates to:
  /// **'Dizi arşivlendi.'**
  String get seriesArchived;

  /// No description provided for @restore.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get restore;

  /// No description provided for @restoreSeriesConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu dizi arşivden geri yüklensin mi?'**
  String get restoreSeriesConfirm;

  /// No description provided for @seriesRestored.
  ///
  /// In tr, this message translates to:
  /// **'Dizi geri yüklendi.'**
  String get seriesRestored;

  /// No description provided for @seriesDetail.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Detayı'**
  String get seriesDetail;

  /// No description provided for @seriesNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Dizi bulunamadı.'**
  String get seriesNotFound;

  /// No description provided for @saveChanges.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikleri Kaydet'**
  String get saveChanges;

  /// No description provided for @partnerChangeClosesAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik mevcut atamayı şimdi kapatır; geçmiş korunur.'**
  String get partnerChangeClosesAssignment;

  /// No description provided for @episodeCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'{count} bölüm'**
  String episodeCountLabel(int count);

  /// No description provided for @selectNewPoster.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Poster Seç'**
  String get selectNewPoster;

  /// No description provided for @changePoster.
  ///
  /// In tr, this message translates to:
  /// **'Posteri Değiştir'**
  String get changePoster;

  /// No description provided for @seriesInfo.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Bilgileri'**
  String get seriesInfo;

  /// No description provided for @publishAndArchive.
  ///
  /// In tr, this message translates to:
  /// **'Yayın ve Arşiv'**
  String get publishAndArchive;

  /// No description provided for @noSeriesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz dizi yok'**
  String get noSeriesYet;

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResults;

  /// No description provided for @noSeriesMatchFilters.
  ///
  /// In tr, this message translates to:
  /// **'Arama veya filtre kriterlerinize uygun dizi bulunamadı.'**
  String get noSeriesMatchFilters;

  /// No description provided for @seriesCatalogSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Vidxon içerik kataloğundaki dizileri yönetin'**
  String get seriesCatalogSubtitle;

  /// No description provided for @searchSeriesNameOrSlug.
  ///
  /// In tr, this message translates to:
  /// **'Dizi adı veya slug ara...'**
  String get searchSeriesNameOrSlug;

  /// No description provided for @seriesName.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Adı'**
  String get seriesName;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @lastUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Son Güncelleme'**
  String get lastUpdate;

  /// No description provided for @editOrDetail.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle / Detay'**
  String get editOrDetail;

  /// No description provided for @updatedAtLabel.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme: {value}'**
  String updatedAtLabel(String value);

  /// No description provided for @seriesLoadFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diziler yüklenemedi'**
  String get seriesLoadFailedTitle;

  /// No description provided for @seriesCatalogLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Diziler yüklenemedi. Lütfen tekrar deneyin.'**
  String get seriesCatalogLoadFailed;

  /// No description provided for @noSeriesInCatalog.
  ///
  /// In tr, this message translates to:
  /// **'Katalogda listelenecek dizi bulunmuyor.'**
  String get noSeriesInCatalog;

  /// No description provided for @newSeriesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kataloga yeni bir dizi ekleyin'**
  String get newSeriesSubtitle;

  /// No description provided for @basicInfo.
  ///
  /// In tr, this message translates to:
  /// **'Temel Bilgiler'**
  String get basicInfo;

  /// No description provided for @slugRequiredStar.
  ///
  /// In tr, this message translates to:
  /// **'Slug *'**
  String get slugRequiredStar;

  /// No description provided for @poster.
  ///
  /// In tr, this message translates to:
  /// **'Poster'**
  String get poster;

  /// No description provided for @posterRequiredStar.
  ///
  /// In tr, this message translates to:
  /// **'Poster *'**
  String get posterRequiredStar;

  /// No description provided for @posterFormatsHint.
  ///
  /// In tr, this message translates to:
  /// **'JPG, PNG veya WEBP · En fazla 10 MiB'**
  String get posterFormatsHint;

  /// No description provided for @premium.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @detail.
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get detail;

  /// No description provided for @qualifiedViewsCount.
  ///
  /// In tr, this message translates to:
  /// **'Nitelikli: {count}'**
  String qualifiedViewsCount(int count);

  /// No description provided for @users.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar'**
  String get users;

  /// No description provided for @usersSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıları arayın, detaylarını görüntüleyin ve jeton yükleyin'**
  String get usersSubtitle;

  /// No description provided for @searchUsersHint.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID, e-posta veya görünen ad ile ara'**
  String get searchUsersHint;

  /// No description provided for @clearSearch.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı temizle'**
  String get clearSearch;

  /// No description provided for @displayName.
  ///
  /// In tr, this message translates to:
  /// **'Görünen Ad'**
  String get displayName;

  /// No description provided for @userId.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID'**
  String get userId;

  /// No description provided for @coins.
  ///
  /// In tr, this message translates to:
  /// **'Jeton'**
  String get coins;

  /// No description provided for @registration.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt'**
  String get registration;

  /// No description provided for @copyUserId.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID kopyala'**
  String get copyUserId;

  /// No description provided for @userIdCopied.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID kopyalandı.'**
  String get userIdCopied;

  /// No description provided for @registeredAt.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt: {value}'**
  String registeredAt(String value);

  /// No description provided for @userNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bulunamadı'**
  String get userNotFound;

  /// No description provided for @noUsersMatch.
  ///
  /// In tr, this message translates to:
  /// **'Arama kriterlerinize uygun kullanıcı yok.'**
  String get noUsersMatch;

  /// No description provided for @usersLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar yüklenemedi'**
  String get usersLoadFailed;

  /// No description provided for @userDetail.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Detayı'**
  String get userDetail;

  /// No description provided for @creditCoins.
  ///
  /// In tr, this message translates to:
  /// **'Jeton Yükle'**
  String get creditCoins;

  /// No description provided for @debitCoins.
  ///
  /// In tr, this message translates to:
  /// **'Jeton Eksilt'**
  String get debitCoins;

  /// No description provided for @coinLedger.
  ///
  /// In tr, this message translates to:
  /// **'Jeton Hareket Geçmişi'**
  String get coinLedger;

  /// No description provided for @registeredDate.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tarihi'**
  String get registeredDate;

  /// No description provided for @lastSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Son giriş'**
  String get lastSignIn;

  /// No description provided for @currentCoinBalance.
  ///
  /// In tr, this message translates to:
  /// **'Güncel jeton bakiyesi'**
  String get currentCoinBalance;

  /// No description provided for @walletLastUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Wallet son güncelleme'**
  String get walletLastUpdate;

  /// No description provided for @totalLedgerRecords.
  ///
  /// In tr, this message translates to:
  /// **'Toplam ledger kaydı'**
  String get totalLedgerRecords;

  /// No description provided for @adminCreditTotal.
  ///
  /// In tr, this message translates to:
  /// **'Admin yüklemesi toplamı'**
  String get adminCreditTotal;

  /// No description provided for @coinsAmount.
  ///
  /// In tr, this message translates to:
  /// **'{count} jeton'**
  String coinsAmount(int count);

  /// No description provided for @type.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get type;

  /// No description provided for @previous.
  ///
  /// In tr, this message translates to:
  /// **'Önceki'**
  String get previous;

  /// No description provided for @admin.
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @noCoinMovements.
  ///
  /// In tr, this message translates to:
  /// **'Henüz jeton hareketi yok.'**
  String get noCoinMovements;

  /// No description provided for @userDetailLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı detayı yüklenemedi'**
  String get userDetailLoadFailed;

  /// No description provided for @adminAccountsNoManualCoins.
  ///
  /// In tr, this message translates to:
  /// **'Admin hesaplarında manuel jeton işlemleri yapılamaz.'**
  String get adminAccountsNoManualCoins;

  /// No description provided for @coinsSuperAdminOnly.
  ///
  /// In tr, this message translates to:
  /// **'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.'**
  String get coinsSuperAdminOnly;

  /// No description provided for @confirmTransaction.
  ///
  /// In tr, this message translates to:
  /// **'İşlemi Onayla'**
  String get confirmTransaction;

  /// No description provided for @coinAmount.
  ///
  /// In tr, this message translates to:
  /// **'Jeton miktarı'**
  String get coinAmount;

  /// No description provided for @supportReferenceOptional.
  ///
  /// In tr, this message translates to:
  /// **'Destek / işlem referansı (opsiyonel)'**
  String get supportReferenceOptional;

  /// No description provided for @user.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get user;

  /// No description provided for @toCredit.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenecek'**
  String get toCredit;

  /// No description provided for @thisChangesBalance.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem kullanıcı bakiyesini değiştirecek.'**
  String get thisChangesBalance;

  /// No description provided for @creditCoinsAmount.
  ///
  /// In tr, this message translates to:
  /// **'{amount} Jeton Yükle'**
  String creditCoinsAmount(int amount);

  /// No description provided for @coinsCredited.
  ///
  /// In tr, this message translates to:
  /// **'Jetonlar başarıyla yüklendi.'**
  String get coinsCredited;

  /// No description provided for @idempotentCredit.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem daha önce tamamlanmıştı. Güncel bakiye yenilendi.'**
  String get idempotentCredit;

  /// No description provided for @insufficientBalance.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcının bakiyesi bu işlem için yetersiz.'**
  String get insufficientBalance;

  /// No description provided for @idempotentDebit.
  ///
  /// In tr, this message translates to:
  /// **'İşlem daha önce tamamlanmıştı. Güncel bakiye: {balance}'**
  String idempotentDebit(String balance);

  /// No description provided for @caseReferenceOptional.
  ///
  /// In tr, this message translates to:
  /// **'Vaka / Referans (isteğe bağlı)'**
  String get caseReferenceOptional;

  /// No description provided for @debitDoesNotDeleteLedger.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem mevcut ledger kayıtlarını silmez. Kullanıcının bakiyesine yeni bir negatif işlem kaydı eklenir.'**
  String get debitDoesNotDeleteLedger;

  /// No description provided for @auditTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Kayıtları'**
  String get auditTitle;

  /// No description provided for @auditSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Admin paneli işlem geçmişi'**
  String get auditSubtitle;

  /// No description provided for @actionType.
  ///
  /// In tr, this message translates to:
  /// **'İşlem türü'**
  String get actionType;

  /// No description provided for @targetUserId.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kullanıcı ID'**
  String get targetUserId;

  /// No description provided for @action.
  ///
  /// In tr, this message translates to:
  /// **'İşlem'**
  String get action;

  /// No description provided for @noAuditRecords.
  ///
  /// In tr, this message translates to:
  /// **'İşlem kaydı bulunamadı.'**
  String get noAuditRecords;

  /// No description provided for @filterWalletCredit.
  ///
  /// In tr, this message translates to:
  /// **'Jeton Yükleme'**
  String get filterWalletCredit;

  /// No description provided for @filterWalletDebit.
  ///
  /// In tr, this message translates to:
  /// **'Jeton Eksiltme'**
  String get filterWalletDebit;

  /// No description provided for @filterSeriesUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Güncellendi'**
  String get filterSeriesUpdated;

  /// No description provided for @filterPosterReplaced.
  ///
  /// In tr, this message translates to:
  /// **'Poster Değiştirildi'**
  String get filterPosterReplaced;

  /// No description provided for @filterSeriesPublished.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Yayınlandı'**
  String get filterSeriesPublished;

  /// No description provided for @filterSeriesArchived.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Arşivlendi'**
  String get filterSeriesArchived;

  /// No description provided for @filterEpisodeUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Güncellendi'**
  String get filterEpisodeUpdated;

  /// No description provided for @filterEpisodeReorder.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Sıralaması'**
  String get filterEpisodeReorder;

  /// No description provided for @filterVideoReplacement.
  ///
  /// In tr, this message translates to:
  /// **'Video Değişimi'**
  String get filterVideoReplacement;

  /// No description provided for @filterAdminRoleChange.
  ///
  /// In tr, this message translates to:
  /// **'Admin Rolü Değişikliği'**
  String get filterAdminRoleChange;

  /// No description provided for @filterAdminAccessRevoke.
  ///
  /// In tr, this message translates to:
  /// **'Admin Erişimi Kaldırma'**
  String get filterAdminAccessRevoke;

  /// No description provided for @adminsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yöneticiler'**
  String get adminsTitle;

  /// No description provided for @adminsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Admin paneli erişimi olan hesaplar'**
  String get adminsSubtitle;

  /// No description provided for @addAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici Ekle'**
  String get addAdmin;

  /// No description provided for @selectRole.
  ///
  /// In tr, this message translates to:
  /// **'Rol Seç'**
  String get selectRole;

  /// No description provided for @searchByIdEmailName.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID, e-posta veya görünen ad ile arayın.'**
  String get searchByIdEmailName;

  /// No description provided for @searchQuery.
  ///
  /// In tr, this message translates to:
  /// **'Arama sorgusu'**
  String get searchQuery;

  /// No description provided for @makeAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici Yap'**
  String get makeAdmin;

  /// No description provided for @adminRole.
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @superAdminRole.
  ///
  /// In tr, this message translates to:
  /// **'Super Admin'**
  String get superAdminRole;

  /// No description provided for @thisGrantsAdminAccess.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem kullanıcının mevcut hesabını, profilini, cüzdanını veya geçmişini değiştirmez. Kullanıcıya admin paneli erişimi verir.'**
  String get thisGrantsAdminAccess;

  /// No description provided for @confirmRoleChange.
  ///
  /// In tr, this message translates to:
  /// **'Rol Değişikliğini Onayla'**
  String get confirmRoleChange;

  /// No description provided for @newRole.
  ///
  /// In tr, this message translates to:
  /// **'Yeni rol: {role}'**
  String newRole(String role);

  /// No description provided for @roleChangeAffectsPermissions.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem kullanıcının admin paneli yetkilerini değiştirir.'**
  String get roleChangeAffectsPermissions;

  /// No description provided for @roleUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Rol güncellendi.'**
  String get roleUpdated;

  /// No description provided for @revokeAdminAccess.
  ///
  /// In tr, this message translates to:
  /// **'Admin Erişimini Kaldır'**
  String get revokeAdminAccess;

  /// No description provided for @revokeAccessDoesNotDelete.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem kullanıcının giriş hesabını, profilini, cüzdanını veya geçmişini silmez. Yalnızca admin paneli erişimini kaldırır.'**
  String get revokeAccessDoesNotDelete;

  /// No description provided for @revokeAccess.
  ///
  /// In tr, this message translates to:
  /// **'Erişimi Kaldır'**
  String get revokeAccess;

  /// No description provided for @adminAccessRevoked.
  ///
  /// In tr, this message translates to:
  /// **'Admin erişimi kaldırıldı.'**
  String get adminAccessRevoked;

  /// No description provided for @superAdminRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfaya erişim için Super Admin yetkisi gerekiyor.'**
  String get superAdminRequired;

  /// No description provided for @manager.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get manager;

  /// No description provided for @role.
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @becameAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici olma'**
  String get becameAdmin;

  /// No description provided for @accountCreated.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluşturma'**
  String get accountCreated;

  /// No description provided for @yourAccount.
  ///
  /// In tr, this message translates to:
  /// **'Kendi hesabınız'**
  String get yourAccount;

  /// No description provided for @makeAdminAction.
  ///
  /// In tr, this message translates to:
  /// **'Admin Yap'**
  String get makeAdminAction;

  /// No description provided for @makeSuperAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Super Admin Yap'**
  String get makeSuperAdmin;

  /// No description provided for @noAdminsFound.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı yönetici bulunamadı.'**
  String get noAdminsFound;

  /// No description provided for @partners.
  ///
  /// In tr, this message translates to:
  /// **'Partnerler'**
  String get partners;

  /// No description provided for @partnersSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İş birliği ortakları, üyeler ve analitikleri yönetin'**
  String get partnersSubtitle;

  /// No description provided for @createPartner.
  ///
  /// In tr, this message translates to:
  /// **'Partner Oluştur'**
  String get createPartner;

  /// No description provided for @editPartner.
  ///
  /// In tr, this message translates to:
  /// **'Partner Düzenle'**
  String get editPartner;

  /// No description provided for @partnerListLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Partner listesi yüklenemedi.'**
  String get partnerListLoadFailed;

  /// No description provided for @analyticsHealthLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Analitik sağlık durumu yüklenemedi.'**
  String get analyticsHealthLoadFailed;

  /// No description provided for @partnerCreated.
  ///
  /// In tr, this message translates to:
  /// **'Partner oluşturuldu.'**
  String get partnerCreated;

  /// No description provided for @noPartnersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Partner yok.'**
  String get noPartnersYet;

  /// No description provided for @members.
  ///
  /// In tr, this message translates to:
  /// **'Üyeler'**
  String get members;

  /// No description provided for @activeAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Atama'**
  String get activeAssignment;

  /// No description provided for @createdAt.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get createdAt;

  /// No description provided for @unassigned.
  ///
  /// In tr, this message translates to:
  /// **'Atanmamış'**
  String get unassigned;

  /// No description provided for @partnerNamed.
  ///
  /// In tr, this message translates to:
  /// **'Partner ({name})'**
  String partnerNamed(String name);

  /// No description provided for @displayNameStar.
  ///
  /// In tr, this message translates to:
  /// **'Görünen Ad *'**
  String get displayNameStar;

  /// No description provided for @displayNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Görünen ad zorunludur.'**
  String get displayNameRequired;

  /// No description provided for @actionFailed.
  ///
  /// In tr, this message translates to:
  /// **'İşlem başarısız oldu.'**
  String get actionFailed;

  /// No description provided for @partnerDetailLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Partner detayı yüklenemedi.'**
  String get partnerDetailLoadFailed;

  /// No description provided for @partnerUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Partner güncellendi.'**
  String get partnerUpdated;

  /// No description provided for @memberAdded.
  ///
  /// In tr, this message translates to:
  /// **'Üye eklendi.'**
  String get memberAdded;

  /// No description provided for @changeMemberStatus.
  ///
  /// In tr, this message translates to:
  /// **'Üye durumunu değiştir'**
  String get changeMemberStatus;

  /// No description provided for @memberStatusUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Üye durumu güncellendi.'**
  String get memberStatusUpdated;

  /// No description provided for @partner.
  ///
  /// In tr, this message translates to:
  /// **'Partner'**
  String get partner;

  /// No description provided for @analyticsNeedsAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Analitik için önce bir dizi ataması gerekir.'**
  String get analyticsNeedsAssignment;

  /// No description provided for @addMember.
  ///
  /// In tr, this message translates to:
  /// **'Üye Ekle'**
  String get addMember;

  /// No description provided for @noMembersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz üye yok.'**
  String get noMembersYet;

  /// No description provided for @analyticsSeries.
  ///
  /// In tr, this message translates to:
  /// **'Analitik Dizisi'**
  String get analyticsSeries;

  /// No description provided for @emailRequiredShort.
  ///
  /// In tr, this message translates to:
  /// **'E-posta zorunludur.'**
  String get emailRequiredShort;

  /// No description provided for @userSearchFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı aranamadı.'**
  String get userSearchFailed;

  /// No description provided for @memberAddFailed.
  ///
  /// In tr, this message translates to:
  /// **'Üye eklenemedi.'**
  String get memberAddFailed;

  /// No description provided for @findExistingAccount.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut bir Vidxon hesabını tam e-posta ile bulun.'**
  String get findExistingAccount;

  /// No description provided for @findUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıyı Bul'**
  String get findUser;

  /// No description provided for @addAsMember.
  ///
  /// In tr, this message translates to:
  /// **'Üye Olarak Ekle'**
  String get addAsMember;

  /// No description provided for @assignmentHistory.
  ///
  /// In tr, this message translates to:
  /// **'Partner Atama Geçmişi'**
  String get assignmentHistory;

  /// No description provided for @assignmentHistoryHint.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş aralıklar değiştirilemez. Atamalar [başlangıç, bitiş) ile kaydedilir.'**
  String get assignmentHistoryHint;

  /// No description provided for @noPartnerAssignments.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Partner ataması yok.'**
  String get noPartnerAssignments;

  /// No description provided for @analyticsReportLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Analitik raporu yüklenemedi.'**
  String get analyticsReportLoadFailed;

  /// No description provided for @pageSnapshotMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa anlık görüntüsü uyuşmuyor. Yenileyin.'**
  String get pageSnapshotMismatch;

  /// No description provided for @episodePageLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm sayfası yüklenemedi.'**
  String get episodePageLoadFailed;

  /// No description provided for @startDateUtc.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç tarihi (UTC günü)'**
  String get startDateUtc;

  /// No description provided for @endDateExclusiveUtc.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş tarihi (hariç, UTC)'**
  String get endDateExclusiveUtc;

  /// No description provided for @seriesAnalytics.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Analitiği'**
  String get seriesAnalytics;

  /// No description provided for @analyticsReadonlyHint.
  ///
  /// In tr, this message translates to:
  /// **'Salt okunur · UTC dönem · Kazanç/ödeme yok'**
  String get analyticsReadonlyHint;

  /// No description provided for @reportUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Rapor kullanılamıyor'**
  String get reportUnavailable;

  /// No description provided for @errorNotShownAsZero.
  ///
  /// In tr, this message translates to:
  /// **'Hata durumu sıfır aktivite olarak gösterilmez.'**
  String get errorNotShownAsZero;

  /// No description provided for @reportNotReliable.
  ///
  /// In tr, this message translates to:
  /// **'Rapor şu an güvenilir sayısal sonuç üretmiyor.'**
  String get reportNotReliable;

  /// No description provided for @episodeDistribution.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Dağılımı'**
  String get episodeDistribution;

  /// No description provided for @episodeDistributionHidden.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm dağılımı, bütünlük uyarısı nedeniyle yetkili sonuç olarak gösterilmiyor.'**
  String get episodeDistributionHidden;

  /// No description provided for @noEpisodeRecordsInPeriod.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde bölüme ait kayıt yok.'**
  String get noEpisodeRecordsInPeriod;

  /// No description provided for @loadMoreEpisodes.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla bölüm yükle'**
  String get loadMoreEpisodes;

  /// No description provided for @statusSuspended.
  ///
  /// In tr, this message translates to:
  /// **'Askıda'**
  String get statusSuspended;

  /// No description provided for @statusEnded.
  ///
  /// In tr, this message translates to:
  /// **'Sonlandırılmış'**
  String get statusEnded;

  /// No description provided for @contentConflictReloaded.
  ///
  /// In tr, this message translates to:
  /// **'Bu içerik başka bir yönetici tarafından değiştirildi. Güncel veriler yeniden yüklendi; lütfen değişikliğinizi tekrar kontrol edin.'**
  String get contentConflictReloaded;

  /// No description provided for @reorderConflictReloaded.
  ///
  /// In tr, this message translates to:
  /// **'İçerik düzenleme sırasında değişti. En güncel sıralama yüklendi.'**
  String get reorderConflictReloaded;

  /// No description provided for @videoReplacementUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Yeni video yüklendi. Mevcut video yayında kalmaya devam eder; hazır olduğunda otomatik devreye alınır.'**
  String get videoReplacementUploaded;

  /// No description provided for @videoAttachedProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Video yüklendi ve bölüme bağlandı. Cloudflare Stream videoyu işlemeye devam ediyor.'**
  String get videoAttachedProcessing;

  /// No description provided for @replaceVideo.
  ///
  /// In tr, this message translates to:
  /// **'Videoyu Değiştir'**
  String get replaceVideo;

  /// No description provided for @replaceVideoConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yeni video hazır olana kadar mevcut video yayında kalmaya devam eder.'**
  String get replaceVideoConfirm;

  /// No description provided for @publishEpisodeConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm yayına alınsın mı?'**
  String get publishEpisodeConfirm;

  /// No description provided for @episodePublished.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm yayınlandı.'**
  String get episodePublished;

  /// No description provided for @unpublishEpisodeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölümü Yayından Kaldır?'**
  String get unpublishEpisodeTitle;

  /// No description provided for @unpublishEpisodeConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm kullanıcılar tarafından erişilemez hâle gelecektir. Daha sonra tekrar yayınlayabilirsiniz.'**
  String get unpublishEpisodeConfirm;

  /// No description provided for @episodeUnpublished.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm yayından kaldırıldı.'**
  String get episodeUnpublished;

  /// No description provided for @archiveEpisodeConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm arşivlenecek.'**
  String get archiveEpisodeConfirm;

  /// No description provided for @episodeArchived.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm arşivlendi.'**
  String get episodeArchived;

  /// No description provided for @episodeRestored.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm geri yüklendi.'**
  String get episodeRestored;

  /// No description provided for @archivedEpisodes.
  ///
  /// In tr, this message translates to:
  /// **'Arşivlenmiş Bölümler'**
  String get archivedEpisodes;

  /// No description provided for @uploadVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video Yükle'**
  String get uploadVideo;

  /// No description provided for @previewActiveVideo.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Videoyu Önizle'**
  String get previewActiveVideo;

  /// No description provided for @previewPendingVideo.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Videoyu Önizle'**
  String get previewPendingVideo;

  /// No description provided for @videoNone.
  ///
  /// In tr, this message translates to:
  /// **'Video Yok'**
  String get videoNone;

  /// No description provided for @videoProcessing.
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor'**
  String get videoProcessing;

  /// No description provided for @videoReady.
  ///
  /// In tr, this message translates to:
  /// **'Video Hazır'**
  String get videoReady;

  /// No description provided for @videoError.
  ///
  /// In tr, this message translates to:
  /// **'Video Hatası'**
  String get videoError;

  /// No description provided for @pendingProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Değişim: İşleniyor'**
  String get pendingProcessing;

  /// No description provided for @pendingReady.
  ///
  /// In tr, this message translates to:
  /// **'Değişim: Hazır'**
  String get pendingReady;

  /// No description provided for @pendingError.
  ///
  /// In tr, this message translates to:
  /// **'Değişim: Hata'**
  String get pendingError;

  /// No description provided for @pendingWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Değişim: Bekliyor'**
  String get pendingWaiting;

  /// No description provided for @originalAudioLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Orijinal ses dili'**
  String get originalAudioLanguage;

  /// No description provided for @dubs.
  ///
  /// In tr, this message translates to:
  /// **'Dublajlar'**
  String get dubs;

  /// No description provided for @videoNotSelected.
  ///
  /// In tr, this message translates to:
  /// **'Video seçilmedi'**
  String get videoNotSelected;

  /// No description provided for @uploadingVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video Cloudflare\'a yükleniyor'**
  String get uploadingVideo;

  /// No description provided for @attachingVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video bölüme bağlanıyor'**
  String get attachingVideo;

  /// No description provided for @uploadCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme tamamlandı'**
  String get uploadCompleted;

  /// No description provided for @uploadFailedShort.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme başarısız'**
  String get uploadFailedShort;

  /// No description provided for @videoUploadedAttachFailed.
  ///
  /// In tr, this message translates to:
  /// **'Video yüklendi fakat bölüme bağlanamadı. Videoyu yeniden yüklemeyin; bağlama işlemini tekrar deneyin.'**
  String get videoUploadedAttachFailed;

  /// No description provided for @uploadInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme devam ediyor'**
  String get uploadInProgress;

  /// No description provided for @uploadInProgressLeave.
  ///
  /// In tr, this message translates to:
  /// **'Video yüklemesi sürerken sayfadan ayrılırsanız işlem yarıda kalabilir. Yine de çıkmak istiyor musunuz?'**
  String get uploadInProgressLeave;

  /// No description provided for @videoFile.
  ///
  /// In tr, this message translates to:
  /// **'Video Dosyası'**
  String get videoFile;

  /// No description provided for @selectMp4.
  ///
  /// In tr, this message translates to:
  /// **'MP4 Seç'**
  String get selectMp4;

  /// No description provided for @noVideoSelectedYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz video seçilmedi.'**
  String get noVideoSelectedYet;

  /// No description provided for @retryAttach.
  ///
  /// In tr, this message translates to:
  /// **'Bağlamayı Tekrar Dene'**
  String get retryAttach;

  /// No description provided for @videoProcessingContinues.
  ///
  /// In tr, this message translates to:
  /// **'Video Cloudflare Stream tarafından işlenmeye devam edecek. İşlem tamamlandığında bölüm listesinde durum güncellenecektir.'**
  String get videoProcessingContinues;

  /// No description provided for @networkDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.'**
  String get networkDisconnected;

  /// No description provided for @adminRoleDescription.
  ///
  /// In tr, this message translates to:
  /// **'Admin; kullanıcıları ve cüzdan işlemlerini yönetebilir, işlem kayıtlarını görüntüleyebilir.'**
  String get adminRoleDescription;

  /// No description provided for @superAdminRoleDescription.
  ///
  /// In tr, this message translates to:
  /// **'Super Admin; yönetici rollerini değiştirebilir, admin erişimini kaldırabilir ve tüm işlem kayıtlarını görüntüleyebilir.'**
  String get superAdminRoleDescription;

  /// No description provided for @addedAsAdmin.
  ///
  /// In tr, this message translates to:
  /// **'{name} Admin olarak eklendi.'**
  String addedAsAdmin(String name);

  /// No description provided for @addedAsSuperAdmin.
  ///
  /// In tr, this message translates to:
  /// **'{name} Super Admin olarak eklendi.'**
  String addedAsSuperAdmin(String name);

  /// No description provided for @userNamed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı: {name}'**
  String userNamed(String name);

  /// No description provided for @emailNamed.
  ///
  /// In tr, this message translates to:
  /// **'E-posta: {email}'**
  String emailNamed(String email);

  /// No description provided for @userIdNamed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID: {id}'**
  String userIdNamed(String id);

  /// No description provided for @targetNamed.
  ///
  /// In tr, this message translates to:
  /// **'Hedef: {name}'**
  String targetNamed(String name);

  /// No description provided for @becameAdminAt.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici olma: {value}'**
  String becameAdminAt(String value);

  /// No description provided for @lastSignInAt.
  ///
  /// In tr, this message translates to:
  /// **'Son giriş: {value}'**
  String lastSignInAt(String value);

  /// No description provided for @previousBalance.
  ///
  /// In tr, this message translates to:
  /// **'Önceki bakiye: {value}'**
  String previousBalance(String value);

  /// No description provided for @createdAtPrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma {value}'**
  String createdAtPrefixed(String value);

  /// No description provided for @qualifiedViewsHelp.
  ///
  /// In tr, this message translates to:
  /// **'Bir kullanıcının bir bölümü ilk kez doğrulanmış izleme süresinde gerekli eşiğe ulaştırmasıyla oluşur. Aynı kullanıcının aynı bölümü tekrar izlemesi sayıyı artırmaz. Geçersiz veya manipülatif trafik hariç tutulur.'**
  String get qualifiedViewsHelp;

  /// No description provided for @uniqueViewersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tekil İzleyici'**
  String get uniqueViewersTitle;

  /// No description provided for @uniqueViewersHelp.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen dönemde ilgili içerikte en az bir doğrulanmış nitelikli izleme oluşturan farklı izleyici sayısı.'**
  String get uniqueViewersHelp;

  /// No description provided for @watchTimeTitle.
  ///
  /// In tr, this message translates to:
  /// **'İzlenme Süresi'**
  String get watchTimeTitle;

  /// No description provided for @watchTimeHelp.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen dönemde sunucu tarafından doğrulanmış toplam izleme süresi. Tekrar izlemeler bu etkileşim metriğine dahil olabilir.'**
  String get watchTimeHelp;

  /// No description provided for @completionRateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlama Oranı'**
  String get completionRateTitle;

  /// No description provided for @completionRateHelp.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen dönemde nitelikli oynatma oturumlarının ne kadarının %95 doğrulanmış izlemeye ulaştığını gösterir.'**
  String get completionRateHelp;

  /// No description provided for @partnerChangeWarning.
  ///
  /// In tr, this message translates to:
  /// **'Partner atamasını değiştirmek mevcut atamayı şimdi kapatır ve (yeni Partner seçildiyse) yeni atamayı şimdi başlatır. Geçmiş atama aralıkları ve tarihsel metrikler korunur; geriye dönük tarihleme yapılamaz.'**
  String get partnerChangeWarning;

  /// No description provided for @unassignWarning.
  ///
  /// In tr, this message translates to:
  /// **'Partner atamasını kaldırmak mevcut atamayı şimdi kapatır. Geçmiş atama aralıkları ve tarihsel metrikler korunur.'**
  String get unassignWarning;

  /// No description provided for @integrityUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Veri bütünlüğü: Kullanılamıyor. Metrikler güvenilir sonuç olarak gösterilmiyor.'**
  String get integrityUnavailable;

  /// No description provided for @integrityWarning.
  ///
  /// In tr, this message translates to:
  /// **'Veri bütünlüğü: {label}. Bu rapordaki sayılar şimdilik yetkili finansal sonuç olarak sunulmaz; Analitik Sağlık kontrolünü inceleyin.'**
  String integrityWarning(String label);

  /// No description provided for @presetTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get presetTotal;

  /// No description provided for @presetToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get presetToday;

  /// No description provided for @presetYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get presetYesterday;

  /// No description provided for @presetLast7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 Gün'**
  String get presetLast7Days;

  /// No description provided for @presetThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu Hafta'**
  String get presetThisWeek;

  /// No description provided for @presetPreviousWeek.
  ///
  /// In tr, this message translates to:
  /// **'Geçen Hafta'**
  String get presetPreviousWeek;

  /// No description provided for @presetLast30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 Gün'**
  String get presetLast30Days;

  /// No description provided for @presetThisMonth.
  ///
  /// In tr, this message translates to:
  /// **'Bu Ay'**
  String get presetThisMonth;

  /// No description provided for @presetPreviousMonth.
  ///
  /// In tr, this message translates to:
  /// **'Geçen Ay'**
  String get presetPreviousMonth;

  /// No description provided for @presetCustom.
  ///
  /// In tr, this message translates to:
  /// **'Özel Aralık'**
  String get presetCustom;

  /// No description provided for @integrityHealthy.
  ///
  /// In tr, this message translates to:
  /// **'Sağlıklı'**
  String get integrityHealthy;

  /// No description provided for @integrityWarningLabel.
  ///
  /// In tr, this message translates to:
  /// **'Uyarı'**
  String get integrityWarningLabel;

  /// No description provided for @integrityUnavailableLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kullanılamıyor'**
  String get integrityUnavailableLabel;

  /// No description provided for @reasonEventReward.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik Ödülü'**
  String get reasonEventReward;

  /// No description provided for @reasonCustomerSupport.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Desteği'**
  String get reasonCustomerSupport;

  /// No description provided for @reasonTechnicalIssue.
  ///
  /// In tr, this message translates to:
  /// **'Teknik Sorun'**
  String get reasonTechnicalIssue;

  /// No description provided for @reasonPromotional.
  ///
  /// In tr, this message translates to:
  /// **'Promosyon'**
  String get reasonPromotional;

  /// No description provided for @reasonPaymentResolution.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Çözümü'**
  String get reasonPaymentResolution;

  /// No description provided for @reasonTestCredit.
  ///
  /// In tr, this message translates to:
  /// **'Test Jetonu'**
  String get reasonTestCredit;

  /// No description provided for @reasonOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get reasonOther;

  /// No description provided for @reasonIncorrectCreditReversal.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış Jeton Yüklemesini Geri Alma'**
  String get reasonIncorrectCreditReversal;

  /// No description provided for @reasonRewardCorrection.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı Ödül Düzeltmesi'**
  String get reasonRewardCorrection;

  /// No description provided for @reasonAbuseCorrection.
  ///
  /// In tr, this message translates to:
  /// **'Kötüye Kullanım Düzeltmesi'**
  String get reasonAbuseCorrection;

  /// No description provided for @reasonPaymentIssueResolution.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Sorunu Çözümü'**
  String get reasonPaymentIssueResolution;

  /// No description provided for @reasonTestDebit.
  ///
  /// In tr, this message translates to:
  /// **'Test Jetonu Eksiltme'**
  String get reasonTestDebit;

  /// No description provided for @txnEpisodeUnlock.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Açma'**
  String get txnEpisodeUnlock;

  /// No description provided for @txnRewardedAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam Ödülü'**
  String get txnRewardedAd;

  /// No description provided for @txnAdminCoinCredit.
  ///
  /// In tr, this message translates to:
  /// **'Admin Jeton Yükleme'**
  String get txnAdminCoinCredit;

  /// No description provided for @txnAdminCoinDebit.
  ///
  /// In tr, this message translates to:
  /// **'Admin Jeton Eksiltme'**
  String get txnAdminCoinDebit;

  /// No description provided for @txnAdminTestCredit.
  ///
  /// In tr, this message translates to:
  /// **'Eski Test Kredisi'**
  String get txnAdminTestCredit;

  /// No description provided for @systemActor.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get systemActor;

  /// No description provided for @anonymousUser.
  ///
  /// In tr, this message translates to:
  /// **'Anonim Kullanıcı'**
  String get anonymousUser;

  /// No description provided for @unconfirmed.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanmamış'**
  String get unconfirmed;

  /// No description provided for @banned.
  ///
  /// In tr, this message translates to:
  /// **'Yasaklı'**
  String get banned;

  /// No description provided for @disabled.
  ///
  /// In tr, this message translates to:
  /// **'Devre Dışı'**
  String get disabled;

  /// No description provided for @filterWalletDebitExact.
  ///
  /// In tr, this message translates to:
  /// **'Jeton Eksiltme'**
  String get filterWalletDebitExact;

  /// No description provided for @memberCountAssignment.
  ///
  /// In tr, this message translates to:
  /// **'Üye {count} · Atama'**
  String memberCountAssignment(int count);

  /// No description provided for @restoreEpisodeConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm arşivden geri yüklensin mi?'**
  String get restoreEpisodeConfirm;

  /// No description provided for @ageNotSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmedi'**
  String get ageNotSpecified;

  /// No description provided for @descriptorViolence.
  ///
  /// In tr, this message translates to:
  /// **'Şiddet'**
  String get descriptorViolence;

  /// No description provided for @descriptorStrongViolence.
  ///
  /// In tr, this message translates to:
  /// **'Yoğun Şiddet'**
  String get descriptorStrongViolence;

  /// No description provided for @descriptorProfanity.
  ///
  /// In tr, this message translates to:
  /// **'Kaba Dil'**
  String get descriptorProfanity;

  /// No description provided for @descriptorMatureThemes.
  ///
  /// In tr, this message translates to:
  /// **'Olgun Temalar'**
  String get descriptorMatureThemes;

  /// No description provided for @descriptorSexualContent.
  ///
  /// In tr, this message translates to:
  /// **'Cinsel İçerik'**
  String get descriptorSexualContent;

  /// No description provided for @descriptorSubstance.
  ///
  /// In tr, this message translates to:
  /// **'Alkol / Tütün / Uyuşturucu Referansları'**
  String get descriptorSubstance;

  /// No description provided for @descriptorFearHorror.
  ///
  /// In tr, this message translates to:
  /// **'Korku / Gerilim'**
  String get descriptorFearHorror;

  /// No description provided for @auditSeriesCreated.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Oluşturuldu'**
  String get auditSeriesCreated;

  /// No description provided for @auditSeriesUnpublished.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Yayından Kaldırıldı'**
  String get auditSeriesUnpublished;

  /// No description provided for @auditSeriesRestored.
  ///
  /// In tr, this message translates to:
  /// **'Dizi Geri Yüklendi'**
  String get auditSeriesRestored;

  /// No description provided for @auditEpisodesReordered.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Sıralaması Değiştirildi'**
  String get auditEpisodesReordered;

  /// No description provided for @auditEpisodeCreated.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Oluşturuldu'**
  String get auditEpisodeCreated;

  /// No description provided for @auditEpisodePublished.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Yayınlandı'**
  String get auditEpisodePublished;

  /// No description provided for @auditEpisodeUnpublished.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Yayından Kaldırıldı'**
  String get auditEpisodeUnpublished;

  /// No description provided for @auditEpisodeArchived.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Arşivlendi'**
  String get auditEpisodeArchived;

  /// No description provided for @auditEpisodeRestored.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Geri Yüklendi'**
  String get auditEpisodeRestored;

  /// No description provided for @auditVideoAttached.
  ///
  /// In tr, this message translates to:
  /// **'Video Bağlandı'**
  String get auditVideoAttached;

  /// No description provided for @auditVideoReplacementRequested.
  ///
  /// In tr, this message translates to:
  /// **'Video Değişimi İstendi'**
  String get auditVideoReplacementRequested;

  /// No description provided for @auditVideoPromoted.
  ///
  /// In tr, this message translates to:
  /// **'Video Aktif Edildi'**
  String get auditVideoPromoted;

  /// No description provided for @analyticsHealthFetchFailed.
  ///
  /// In tr, this message translates to:
  /// **'Analitik sağlık durumu alınamadı: {message}'**
  String analyticsHealthFetchFailed(String message);

  /// No description provided for @analyticsHealthTitle.
  ///
  /// In tr, this message translates to:
  /// **'Analitik Sağlık: {label}'**
  String analyticsHealthTitle(String label);

  /// No description provided for @analyticsIntegrityUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Analitik bütünlük doğrulaması şu anda kullanılamıyor.'**
  String get analyticsIntegrityUnavailable;

  /// No description provided for @memberStatusConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} durumu “{status}” olarak ayarlansın mı?'**
  String memberStatusConfirm(String name, String status);

  /// No description provided for @noResultsPeriod.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı.'**
  String get noResultsPeriod;

  /// No description provided for @ready.
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get ready;

  /// No description provided for @publishBlockedSeriesArchived.
  ///
  /// In tr, this message translates to:
  /// **'Arşivlenmiş bir dizinin bölümü yayınlanamaz.'**
  String get publishBlockedSeriesArchived;

  /// No description provided for @publishBlockedEpisodeArchived.
  ///
  /// In tr, this message translates to:
  /// **'Arşivlenmiş bölüm yayınlanamaz.'**
  String get publishBlockedEpisodeArchived;

  /// No description provided for @publishBlockedNeedsVideo.
  ///
  /// In tr, this message translates to:
  /// **'Yayınlamak için aktif video gerekir.'**
  String get publishBlockedNeedsVideo;

  /// No description provided for @publishBlockedVideoProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Video işleniyor.'**
  String get publishBlockedVideoProcessing;

  /// No description provided for @publishBlockedVideoError.
  ///
  /// In tr, this message translates to:
  /// **'Video hatası giderilmelidir.'**
  String get publishBlockedVideoError;

  /// No description provided for @publishBlockedVideoNotReady.
  ///
  /// In tr, this message translates to:
  /// **'Video henüz hazır değil.'**
  String get publishBlockedVideoNotReady;

  /// No description provided for @publishBlockedPaidCoinPrice.
  ///
  /// In tr, this message translates to:
  /// **'Ücretli bölümde coin fiyatı 0\'dan büyük olmalıdır.'**
  String get publishBlockedPaidCoinPrice;

  /// No description provided for @continueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueAction;

  /// No description provided for @stay.
  ///
  /// In tr, this message translates to:
  /// **'Kal'**
  String get stay;

  /// No description provided for @clearDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarihi Temizle'**
  String get clearDate;

  /// No description provided for @coinPriceHelper.
  ///
  /// In tr, this message translates to:
  /// **'En fazla {max} jeton'**
  String coinPriceHelper(int max);

  /// No description provided for @qualified.
  ///
  /// In tr, this message translates to:
  /// **'Nitelikli'**
  String get qualified;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get pending;

  /// No description provided for @originalAudioSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Orijinal ses dili kaydedilemedi.'**
  String get originalAudioSaveFailed;

  /// No description provided for @maxFileSize200Mb.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum dosya boyutu: 200 MB'**
  String get maxFileSize200Mb;

  /// No description provided for @supportedFormatMp4.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenen format: MP4 (video/mp4)'**
  String get supportedFormatMp4;

  /// No description provided for @currentVideoStatus.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut video durumu: {status}'**
  String currentVideoStatus(String status);

  /// No description provided for @noPendingVideo.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen video bulunmuyor.'**
  String get noPendingVideo;

  /// No description provided for @durationMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Süre bölümle uyuşmuyor; yayınlamadan önce senkronizasyonu doğrulayın.'**
  String get durationMismatch;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @amount.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get amount;

  /// No description provided for @reason.
  ///
  /// In tr, this message translates to:
  /// **'Neden'**
  String get reason;

  /// No description provided for @reasonAlt.
  ///
  /// In tr, this message translates to:
  /// **'Sebep'**
  String get reasonAlt;

  /// No description provided for @reference.
  ///
  /// In tr, this message translates to:
  /// **'Referans'**
  String get reference;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki'**
  String get next;

  /// No description provided for @accountStatus.
  ///
  /// In tr, this message translates to:
  /// **'Hesap durumu'**
  String get accountStatus;

  /// No description provided for @currentBalance.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut bakiye'**
  String get currentBalance;

  /// No description provided for @currentBalancePrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut bakiye: {value}'**
  String currentBalancePrefixed(String value);

  /// No description provided for @newBalance.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bakiye'**
  String get newBalance;

  /// No description provided for @estimatedNewBalance.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini yeni bakiye: {value}'**
  String estimatedNewBalance(String value);

  /// No description provided for @toDebit.
  ///
  /// In tr, this message translates to:
  /// **'Eksiltilecek'**
  String get toDebit;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @continueShort.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueShort;

  /// No description provided for @legalName.
  ///
  /// In tr, this message translates to:
  /// **'Yasal Ad'**
  String get legalName;

  /// No description provided for @ongoingAssignment.
  ///
  /// In tr, this message translates to:
  /// **'devam ediyor'**
  String get ongoingAssignment;

  /// No description provided for @errorPrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {message}'**
  String errorPrefixed(String message);

  /// No description provided for @currentRolePrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut rol: {role}'**
  String currentRolePrefixed(String role);

  /// No description provided for @actionsColumn.
  ///
  /// In tr, this message translates to:
  /// **'Aksiyonlar'**
  String get actionsColumn;

  /// No description provided for @confirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Onay'**
  String get confirmTitle;

  /// No description provided for @roleToGrantPrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Verilecek rol: {role}'**
  String roleToGrantPrefixed(String role);

  /// No description provided for @amountPrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Miktar: {value}'**
  String amountPrefixed(String value);

  /// No description provided for @nextBalancePrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki bakiye: {value}'**
  String nextBalancePrefixed(String value);

  /// No description provided for @reasonPrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Sebep: {value}'**
  String reasonPrefixed(String value);

  /// No description provided for @datePrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Tarih: {value}'**
  String datePrefixed(String value);

  /// No description provided for @referencePrefixed.
  ///
  /// In tr, this message translates to:
  /// **'Referans: {value}'**
  String referencePrefixed(String value);

  /// No description provided for @noEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta yok'**
  String get noEmail;

  /// No description provided for @unknownStatus.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknownStatus;

  /// No description provided for @pushSending.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor'**
  String get pushSending;

  /// No description provided for @pushCancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get pushCancelled;

  /// No description provided for @coinsDebited.
  ///
  /// In tr, this message translates to:
  /// **'{amount} jeton eksiltildi. Yeni bakiye: {balance}'**
  String coinsDebited(String amount, String balance);

  /// No description provided for @balanceArrow.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye: {before} → {after}'**
  String balanceArrow(String before, String after);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
