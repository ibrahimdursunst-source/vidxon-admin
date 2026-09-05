// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Vidxon Admin';

  @override
  String get appBrand => 'VIDXON';

  @override
  String get appBrandAdmin => 'VIDXON ADMIN';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get missingSupabaseConfig =>
      'Supabase bağlantı bilgileri eksik.\n\nUygulamayı SUPABASE_URL ve SUPABASE_PUBLISHABLE_KEY değerleriyle çalıştır.';

  @override
  String get loginUnexpectedError =>
      'Giriş sırasında beklenmeyen bir hata oluştu.';

  @override
  String get email => 'E-posta';

  @override
  String get emailRequired => 'E-posta adresini gir.';

  @override
  String get emailInvalid => 'Geçerli bir e-posta adresi gir.';

  @override
  String get password => 'Şifre';

  @override
  String get passwordRequired => 'Şifreni gir.';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get authorizationFailed => 'Yetki kontrolü başarısız';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get accessDenied => 'Erişim reddedildi';

  @override
  String get accessDeniedMessage =>
      'Bu hesap Vidxon admin kullanıcıları arasında bulunmuyor.';

  @override
  String get adminContextLoadFailed => 'Admin oturum bilgisi yüklenemedi.';

  @override
  String get navOverview => 'Genel Bakış';

  @override
  String get navSeries => 'Diziler';

  @override
  String get navUsers => 'Kullanıcılar';

  @override
  String get navAudit => 'İşlem Kayıtları';

  @override
  String get navPartners => 'Partnerler';

  @override
  String get navCampaigns => 'Kampanyalar';

  @override
  String get navAdmins => 'Yöneticiler';

  @override
  String get navEpisodes => 'Bölümler';

  @override
  String get navCategories => 'Kategoriler';

  @override
  String get navMedia => 'Medya';

  @override
  String get refresh => 'Yenile';

  @override
  String get comingSoonSection => 'Bu bölüm yakında eklenecek.';

  @override
  String get dataLoadFailed => 'Veriler yüklenemedi';

  @override
  String get overviewSubtitle => 'İçerik istatistiklerinin özeti';

  @override
  String get cancel => 'İptal';

  @override
  String get dismiss => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get create => 'Oluştur';

  @override
  String get update => 'Güncelle';

  @override
  String get edit => 'Düzenle';

  @override
  String get delete => 'Sil';

  @override
  String get close => 'Kapat';

  @override
  String get search => 'Ara';

  @override
  String get clear => 'Temizle';

  @override
  String get add => 'Ekle';

  @override
  String get remove => 'Kaldır';

  @override
  String get confirm => 'Onayla';

  @override
  String get loadMore => 'Daha Fazla Yükle';

  @override
  String get published => 'Yayında';

  @override
  String get notPublished => 'Yayında Değil';

  @override
  String get draft => 'Taslak';

  @override
  String get archived => 'Arşivlenmiş';

  @override
  String get archive => 'Arşiv';

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Pasif';

  @override
  String get scheduled => 'Planlanmış';

  @override
  String get expired => 'Süresi Dolmuş';

  @override
  String get statusOngoing => 'Devam Ediyor';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get statusComingSoon => 'Yakında';

  @override
  String get all => 'Tümü';

  @override
  String get allStatuses => 'Tüm Durumlar';

  @override
  String get free => 'Ücretsiz';

  @override
  String get destinationType => 'Hedef Türü';

  @override
  String get destinationNone => 'Bilgilendirme';

  @override
  String get destinationSeries => 'Dizi';

  @override
  String get destinationEpisode => 'Bölüm';

  @override
  String get destinationCoinPurchase => 'Jeton Satın Al';

  @override
  String get destinationMembership => 'Üyelik';

  @override
  String get priority => 'Öncelik';

  @override
  String get priorityHelper =>
      'Aynı anda birden fazla uygun kampanya varsa, daha yüksek öncelikli kampanya önce gösterilir. Eşit öncelikte daha yeni başlangıç tarihi kazanır. Varsayılan: 0.';

  @override
  String get changeSeries => 'Dizi Değiştir';

  @override
  String get changeEpisode => 'Bölüm Değiştir';

  @override
  String get searchSeries => 'Dizi ara';

  @override
  String get titleOrSlug => 'Başlık veya slug';

  @override
  String get noMatchingSeries => 'Eşleşen dizi yok';

  @override
  String get seriesUnavailableBanner =>
      'Kayıtlı dizi artık kullanılamıyor. Mevcut hedef korunur; yeni bir dizi seçmezseniz önceki hedef değişmez.';

  @override
  String get episodeUnavailableBanner =>
      'Kayıtlı bölüm artık kullanılamıyor. Mevcut hedef korunur; yeni bir bölüm seçmezseniz önceki hedef değişmez.';

  @override
  String get selectSeriesFirst => 'Önce bir dizi seçin.';

  @override
  String get episodesLoading => 'Bölümler yükleniyor...';

  @override
  String get episodesLoadFailed => 'Bölümler yüklenemedi.';

  @override
  String get episodesEmptyForSeries => 'Bu dizide henüz bölüm bulunmuyor.';

  @override
  String get selectEpisode => 'Bölüm seçin';

  @override
  String episodePickerLabel(int number, String title) {
    return 'Bölüm $number · $title';
  }

  @override
  String episodePickerNumberOnly(int number) {
    return 'Bölüm $number';
  }

  @override
  String get selectSeries => 'Dizi seçin';

  @override
  String get campaigns => 'Kampanyalar';

  @override
  String get popupTab => 'Pop-up\'lar';

  @override
  String get pushTab => 'Push Bildirimleri';

  @override
  String get editPopup => 'Pop-up Düzenle';

  @override
  String get createPopup => 'Pop-up Oluştur';

  @override
  String get newPopup => 'Yeni Pop-up';

  @override
  String get newPush => 'Yeni Push Bildirimi';

  @override
  String get schedule => 'Zamanlama';

  @override
  String messageForLocaleRequired(String locale) {
    return 'Mesaj ($locale) *';
  }

  @override
  String get messageRequired => 'Mesaj zorunlu';

  @override
  String get ctaRequired => 'CTA zorunlu';

  @override
  String ctaButtonForLocale(String locale) {
    return 'CTA Butonu ($locale)';
  }

  @override
  String ctaButtonForLocaleRequired(String locale) {
    return 'CTA Butonu ($locale) *';
  }

  @override
  String get image => 'Görsel';

  @override
  String get targetLanguages => 'Hedef Diller';

  @override
  String get startsAt => 'Başlangıç';

  @override
  String get endsAtOptional => 'Bitiş (opsiyonel)';

  @override
  String get endsAt => 'Bitiş';

  @override
  String get imageUploadingWait => 'Görsel yükleniyor, lütfen bekleyin.';

  @override
  String get imageUploadMustFinish =>
      'Görsel yüklemesi tamamlanmadan kaydedilemez.';

  @override
  String get imageFileUnreadable => 'Görsel dosyası okunamadı.';

  @override
  String get imageUploadFailed => 'Görsel yüklenemedi.';

  @override
  String get imageUploaded => 'Görsel yüklendi';

  @override
  String get imageNotSelectedOptional => 'Görsel seçilmedi (opsiyonel)';

  @override
  String get changeImage => 'Görseli Değiştir';

  @override
  String get uploadImage => 'Görsel Yükle';

  @override
  String get removeImage => 'Görseli Kaldır';

  @override
  String get noPopupCampaigns => 'Henüz pop-up kampanyası oluşturulmadı.';

  @override
  String get title => 'Başlık';

  @override
  String get titleRequiredStar => 'Başlık *';

  @override
  String get titleRequired => 'Başlık zorunludur.';

  @override
  String get titleRequiredShort => 'Başlık zorunlu';

  @override
  String titleForLocaleRequired(String locale) {
    return 'Başlık ($locale) *';
  }

  @override
  String descriptionForLocale(String locale) {
    return 'Açıklama ($locale)';
  }

  @override
  String get description => 'Açıklama';

  @override
  String get languages => 'Diller';

  @override
  String get target => 'Hedef';

  @override
  String get editPush => 'Push Düzenle';

  @override
  String get createPush => 'Push Oluştur';

  @override
  String get delivery => 'Gönderim';

  @override
  String get chooseSchedule => 'Zamanlama Seç';

  @override
  String get saveDraft => 'Taslak Kaydet';

  @override
  String get sendPush => 'Push Gönder';

  @override
  String sendPushConfirm(String title) {
    return '\"$title\" kampanyasını şimdi göndermek istiyor musunuz?';
  }

  @override
  String get send => 'Gönder';

  @override
  String get pushSendStarted => 'Push gönderimi başlatıldı.';

  @override
  String get noPushCampaigns => 'Henüz push bildirimi oluşturulmadı.';

  @override
  String get planOrDelivery => 'Plan/Gönderim';

  @override
  String get sent => 'Gönderildi';

  @override
  String get failed => 'Başarısız';

  @override
  String get sendNow => 'Şimdi Gönder';

  @override
  String get cancelAction => 'İptal Et';

  @override
  String get contentRating => 'İçerik Derecelendirmesi';

  @override
  String get contentRatingDisclaimer =>
      'Bunlar Vidxon uygulama içi uygunluk etiketleridir; App Store / Google Play derecelendirmelerinin yerine geçmez.';

  @override
  String get ageRating => 'Yaş Derecesi';

  @override
  String get contentDescriptors => 'İçerik Tanımlayıcıları';

  @override
  String get validCoinPrice => 'Geçerli bir coin fiyatı girin.';

  @override
  String get validEpisodeNumber => 'Geçerli bir bölüm numarası girin.';

  @override
  String get episodeUpdated => 'Bölüm başarıyla güncellendi.';

  @override
  String get episodeCreated => 'Bölüm başarıyla oluşturuldu.';

  @override
  String get unexpectedRetry =>
      'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get editEpisode => 'Bölümü Düzenle';

  @override
  String get newEpisode => 'Yeni Bölüm';

  @override
  String get episodeNumberStar => 'Bölüm Numarası *';

  @override
  String get episodeNumberReorderHint =>
      'Bölüm numarası sıralama ekranından değiştirilir.';

  @override
  String get episodeNumberMustBePositive =>
      'Bölüm numarası 0\'dan büyük olmalıdır.';

  @override
  String get useDifferentRatingForEpisode =>
      'Bu bölüm için farklı derecelendirme kullan';

  @override
  String get episodeSpecificRating => 'Bölüme özel derecelendirme';

  @override
  String get useSeriesRating => 'Dizi derecelendirmesini kullan';

  @override
  String get inheritDescriptorsFromSeries => 'Tanımlayıcıları diziden miras al';

  @override
  String get seriesDescriptorsUsed => 'Dizi tanımlayıcıları kullanılır';

  @override
  String get episodeNoDescriptors =>
      'Bu bölümde tanımlayıcı yok (açık boş liste)';

  @override
  String get episodeSpecificDescriptors => 'Bölüme özel tanımlayıcı listesi';

  @override
  String get freeEpisode => 'Ücretsiz Bölüm';

  @override
  String get coinPrice => 'Coin Fiyatı';

  @override
  String get coinPriceNotNegative => 'Coin fiyatı negatif olamaz.';

  @override
  String coinPriceMax(int max) {
    return 'Coin fiyatı en fazla $max olabilir.';
  }

  @override
  String get freeEpisodeCoinMustBeZero =>
      'Ücretsiz bölümlerde coin fiyatı 0 olmalıdır.';

  @override
  String get releaseDate => 'Yayın Tarihi';

  @override
  String get notSelected => 'Seçilmedi';

  @override
  String get publishStatus => 'Yayın Durumu';

  @override
  String get status => 'Durum';

  @override
  String get video => 'Video';

  @override
  String get pendingVideo => 'Bekleyen Video';

  @override
  String get qualifiedViews => 'Nitelikli İzlenme';

  @override
  String get legacyCounterSeed => 'Eski Sayaç (seed)';

  @override
  String get mediaTracksLoadFailed =>
      'Medya parçaları yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get invalidLocaleExample =>
      'Geçersiz dil kodu. Örnek: tr, en, pt_BR, zh_Hans.';

  @override
  String get originalAudioUpdated => 'Orijinal ses dili güncellendi.';

  @override
  String get audioUploadAccepted => 'Ses parçası yükleme isteği alındı.';

  @override
  String get audioReplaceAccepted => 'Ses parçası değiştirme isteği alındı.';

  @override
  String get subtitleUploaded => 'Altyazı yüklendi.';

  @override
  String get subtitleReplaced => 'Altyazı değiştirildi.';

  @override
  String get removeAudioTrack => 'Ses parçasını kaldır';

  @override
  String removeAudioTrackConfirm(String locale) {
    return '$locale dilindeki dublaj kaldırılsın mı?';
  }

  @override
  String get audioTrackRemoved => 'Ses parçası kaldırıldı.';

  @override
  String get audioTrackRemoveFailed => 'Ses parçası kaldırılamadı.';

  @override
  String get removeSubtitle => 'Altyazıyı kaldır';

  @override
  String removeSubtitleConfirm(String locale) {
    return '$locale dilindeki altyazı kaldırılsın mı?';
  }

  @override
  String get subtitleRemoved => 'Altyazı kaldırıldı.';

  @override
  String get subtitleRemoveFailed => 'Altyazı kaldırılamadı.';

  @override
  String get statusUpdateFailed => 'Durum güncellenemedi.';

  @override
  String get audioSubtitles => 'Ses / Altyazı';

  @override
  String get originalAudioHelp =>
      'Videonun gömülü program sesinin dili. Dublaj dilleri bu değerden farklı olmalıdır.';

  @override
  String get noDubsYet => 'Henüz dublaj yok.';

  @override
  String get subtitles => 'Altyazılar';

  @override
  String get noSubtitlesYet => 'Henüz altyazı yok.';

  @override
  String episodeDurationSeconds(int seconds) {
    return 'Bölüm süresi: ${seconds}s';
  }

  @override
  String get localeCode => 'Dil kodu';

  @override
  String get updateStatus => 'Durumu Güncelle';

  @override
  String get replace => 'Değiştir';

  @override
  String get dubCannotMatchOriginal =>
      'Dublaj dili orijinal ses diliyle aynı olamaz.';

  @override
  String get severeDurationNeedsConfirm =>
      'Ciddi süre farkı için onay kutusu işaretlenmeden yükleme yapılamaz.';

  @override
  String get uploadFailedRetry =>
      'Yükleme başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get replaceAudioTrack => 'Ses parçasını değiştir';

  @override
  String get addAudioTrack => 'Ses parçası ekle';

  @override
  String get audioDurationSeconds => 'Ses süresi (saniye)';

  @override
  String get audioDurationHint => 'Bölüm süresiyle karşılaştırmak için girin';

  @override
  String get severeDurationConfirm =>
      'Süre farkının ciddi olduğunu ve yine de yüklemek istediğimi onaylıyorum.';

  @override
  String get selectAudioFile => 'Ses dosyası seç (MP3 / M4A / AAC)';

  @override
  String get upload => 'Yükle';

  @override
  String get replaceSubtitle => 'Altyazıyı değiştir';

  @override
  String get addSubtitle => 'Altyazı ekle';

  @override
  String get selectWebvtt => 'WebVTT (.vtt) seç';

  @override
  String get previewLoadFailed => 'Önizleme yüklenemedi.';

  @override
  String get pendingVideoPreview => 'Bekleyen Video Önizleme';

  @override
  String get activeVideoPreview => 'Aktif Video Önizleme';

  @override
  String get noActiveVideo => 'Aktif video bulunmuyor.';

  @override
  String get activeVideoNotReady => 'Aktif video henüz önizlemeye hazır değil.';

  @override
  String get pendingVideoNotReady =>
      'Bekleyen video henüz önizlemeye hazır değil.';

  @override
  String get previewWebOnly =>
      'Video önizleme yalnızca web ortamında desteklenir.';

  @override
  String get reorderSaveFailed => 'Sıralama kaydedilemedi.';

  @override
  String get reorderLoadFailed =>
      'Güncel sıralama yüklenemedi. Lütfen sayfayı kapatıp tekrar deneyin.';

  @override
  String get unsavedReorder => 'Kaydedilmemiş sıralama';

  @override
  String get unsavedReorderMessage =>
      'Sıralama değişiklikleri kaydedilmedi. Çıkmak istiyor musunuz?';

  @override
  String get leave => 'Çık';

  @override
  String get episodeOrder => 'Bölüm Sıralaması';

  @override
  String get saveOrder => 'Sıralamayı Kaydet';

  @override
  String get manageSeriesEpisodes => 'Seçili dizinin bölümlerini yönetin';

  @override
  String get editOrder => 'Sıralamayı Düzenle';

  @override
  String get access => 'Erişim';

  @override
  String get publish => 'Yayın';

  @override
  String get actions => 'İşlemler';

  @override
  String releaseAtLabel(String value) {
    return 'Yayın: $value';
  }

  @override
  String get noEpisodesYet => 'Henüz bölüm yok';

  @override
  String get createFirstEpisode =>
      'Bu dizi için ilk bölümü oluşturabilirsiniz.';

  @override
  String get episodesLoadFailedTitle => 'Bölümler yüklenemedi';

  @override
  String get validatingForm => 'Form doğrulanıyor';

  @override
  String get preparingUploadLink => 'Yükleme bağlantısı hazırlanıyor';

  @override
  String get uploadingPoster => 'Poster yükleniyor';

  @override
  String get savingSeries => 'Dizi kaydediliyor';

  @override
  String get posterUnreadable => 'Poster dosyası okunamadı.';

  @override
  String get posterRequired => 'Poster seçimi zorunludur.';

  @override
  String get posterPathFailed => 'Poster yolu oluşturulamadı.';

  @override
  String get seriesCreated => 'Dizi başarıyla oluşturuldu.';

  @override
  String get posterAlreadyUploadedRetry =>
      'Poster zaten yüklendi. Bilgileri düzenleyip tekrar deneyebilirsiniz.';

  @override
  String seriesCreatedPartnerFailed(String message) {
    return 'Dizi oluşturuldu ancak Partner ataması başarısız: $message';
  }

  @override
  String get seriesCreatedRetryPartner =>
      'Dizi kaydı oluştu. Partner atamasını dizi detayından yeniden deneyin.';

  @override
  String get posterAlreadyUploaded =>
      'Poster zaten yüklendi. Tekrar deneyebilirsiniz.';

  @override
  String get newSeries => 'Yeni Dizi';

  @override
  String get slugHint => 'Küçük harf, rakam ve tire';

  @override
  String get validSlug => 'Geçerli bir slug girin.';

  @override
  String get selectDate => 'Tarih Seç';

  @override
  String get selectPoster => 'Poster Seç';

  @override
  String get publishSettings => 'Yayın Ayarları';

  @override
  String get featured => 'Öne Çıkan';

  @override
  String get collaborationPartner => 'İş Birliği Ortağı';

  @override
  String get categories => 'Kategoriler';

  @override
  String get categoriesLoadFailed => 'Kategoriler yüklenemedi.';

  @override
  String get noCategoriesYet => 'Henüz kategori bulunmuyor.';

  @override
  String get createSeries => 'Diziyi Oluştur';

  @override
  String get seriesLoadFailed => 'Dizi yüklenemedi.';

  @override
  String get assignmentHistoryLoadFailed => 'Atama geçmişi yüklenemedi.';

  @override
  String get removePartnerAssignment => 'Partner atamasını kaldır';

  @override
  String get changePartnerAssignment => 'Partner atamasını değiştir';

  @override
  String get removeAssignment => 'Atamayı Kaldır';

  @override
  String get changeAssignment => 'Atamayı Değiştir';

  @override
  String get seriesUpdated => 'Dizi güncellendi.';

  @override
  String get seriesUpdateFailed => 'Dizi güncellenemedi.';

  @override
  String get posterUpdated => 'Poster güncellendi.';

  @override
  String get posterUpdateFailed => 'Poster güncellenemedi.';

  @override
  String get actionIncomplete => 'İşlem tamamlanamadı.';

  @override
  String get publishSeries => 'Yayınla';

  @override
  String get publishSeriesConfirm => 'Bu dizi yayına alınsın mı?';

  @override
  String get seriesPublished => 'Dizi yayınlandı.';

  @override
  String get unpublish => 'Yayından Kaldır';

  @override
  String get unpublishSeriesConfirm => 'Bu dizi yayından kaldırılsın mı?';

  @override
  String get seriesUnpublished => 'Dizi yayından kaldırıldı.';

  @override
  String get archiveAction => 'Arşivle';

  @override
  String get archiveSeriesConfirm =>
      'Bu dizi arşivlenecek. Arşivlenmiş içerik yayından kaldırılır ve düzenleme kısıtlanabilir.';

  @override
  String get seriesArchived => 'Dizi arşivlendi.';

  @override
  String get restore => 'Geri Yükle';

  @override
  String get restoreSeriesConfirm => 'Bu dizi arşivden geri yüklensin mi?';

  @override
  String get seriesRestored => 'Dizi geri yüklendi.';

  @override
  String get seriesDetail => 'Dizi Detayı';

  @override
  String get seriesNotFound => 'Dizi bulunamadı.';

  @override
  String get saveChanges => 'Değişiklikleri Kaydet';

  @override
  String get partnerChangeClosesAssignment =>
      'Değişiklik mevcut atamayı şimdi kapatır; geçmiş korunur.';

  @override
  String episodeCountLabel(int count) {
    return '$count bölüm';
  }

  @override
  String get selectNewPoster => 'Yeni Poster Seç';

  @override
  String get changePoster => 'Posteri Değiştir';

  @override
  String get seriesInfo => 'Dizi Bilgileri';

  @override
  String get publishAndArchive => 'Yayın ve Arşiv';

  @override
  String get noSeriesYet => 'Henüz dizi yok';

  @override
  String get noResults => 'Sonuç bulunamadı';

  @override
  String get noSeriesMatchFilters =>
      'Arama veya filtre kriterlerinize uygun dizi bulunamadı.';

  @override
  String get seriesCatalogSubtitle =>
      'Vidxon içerik kataloğundaki dizileri yönetin';

  @override
  String get searchSeriesNameOrSlug => 'Dizi adı veya slug ara...';

  @override
  String get seriesName => 'Dizi Adı';

  @override
  String get category => 'Kategori';

  @override
  String get lastUpdate => 'Son Güncelleme';

  @override
  String get editOrDetail => 'Düzenle / Detay';

  @override
  String updatedAtLabel(String value) {
    return 'Güncelleme: $value';
  }

  @override
  String get seriesLoadFailedTitle => 'Diziler yüklenemedi';

  @override
  String get seriesCatalogLoadFailed =>
      'Diziler yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get noSeriesInCatalog => 'Katalogda listelenecek dizi bulunmuyor.';

  @override
  String get newSeriesSubtitle => 'Kataloga yeni bir dizi ekleyin';

  @override
  String get basicInfo => 'Temel Bilgiler';

  @override
  String get slugRequiredStar => 'Slug *';

  @override
  String get poster => 'Poster';

  @override
  String get posterRequiredStar => 'Poster *';

  @override
  String get posterFormatsHint => 'JPG, PNG veya WEBP · En fazla 10 MiB';

  @override
  String get premium => 'Premium';

  @override
  String get detail => 'Detay';

  @override
  String qualifiedViewsCount(int count) {
    return 'Nitelikli: $count';
  }

  @override
  String get users => 'Kullanıcılar';

  @override
  String get usersSubtitle =>
      'Kullanıcıları arayın, detaylarını görüntüleyin ve jeton yükleyin';

  @override
  String get searchUsersHint => 'Kullanıcı ID, e-posta veya görünen ad ile ara';

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String get displayName => 'Görünen Ad';

  @override
  String get userId => 'Kullanıcı ID';

  @override
  String get coins => 'Jeton';

  @override
  String get registration => 'Kayıt';

  @override
  String get copyUserId => 'Kullanıcı ID kopyala';

  @override
  String get userIdCopied => 'Kullanıcı ID kopyalandı.';

  @override
  String registeredAt(String value) {
    return 'Kayıt: $value';
  }

  @override
  String get userNotFound => 'Kullanıcı bulunamadı';

  @override
  String get noUsersMatch => 'Arama kriterlerinize uygun kullanıcı yok.';

  @override
  String get usersLoadFailed => 'Kullanıcılar yüklenemedi';

  @override
  String get userDetail => 'Kullanıcı Detayı';

  @override
  String get creditCoins => 'Jeton Yükle';

  @override
  String get debitCoins => 'Jeton Eksilt';

  @override
  String get coinLedger => 'Jeton Hareket Geçmişi';

  @override
  String get registeredDate => 'Kayıt tarihi';

  @override
  String get lastSignIn => 'Son giriş';

  @override
  String get currentCoinBalance => 'Güncel jeton bakiyesi';

  @override
  String get walletLastUpdate => 'Wallet son güncelleme';

  @override
  String get totalLedgerRecords => 'Toplam ledger kaydı';

  @override
  String get adminCreditTotal => 'Admin yüklemesi toplamı';

  @override
  String coinsAmount(int count) {
    return '$count jeton';
  }

  @override
  String get type => 'Tür';

  @override
  String get previous => 'Önceki';

  @override
  String get admin => 'Admin';

  @override
  String get noCoinMovements => 'Henüz jeton hareketi yok.';

  @override
  String get userDetailLoadFailed => 'Kullanıcı detayı yüklenemedi';

  @override
  String get adminAccountsNoManualCoins =>
      'Admin hesaplarında manuel jeton işlemleri yapılamaz.';

  @override
  String get coinsSuperAdminOnly =>
      'Jeton işlemleri yalnızca Super Admin tarafından yapılabilir.';

  @override
  String get confirmTransaction => 'İşlemi Onayla';

  @override
  String get coinAmount => 'Jeton miktarı';

  @override
  String get supportReferenceOptional => 'Destek / işlem referansı (opsiyonel)';

  @override
  String get user => 'Kullanıcı';

  @override
  String get toCredit => 'Yüklenecek';

  @override
  String get thisChangesBalance =>
      'Bu işlem kullanıcı bakiyesini değiştirecek.';

  @override
  String creditCoinsAmount(int amount) {
    return '$amount Jeton Yükle';
  }

  @override
  String get coinsCredited => 'Jetonlar başarıyla yüklendi.';

  @override
  String get idempotentCredit =>
      'Bu işlem daha önce tamamlanmıştı. Güncel bakiye yenilendi.';

  @override
  String get insufficientBalance =>
      'Kullanıcının bakiyesi bu işlem için yetersiz.';

  @override
  String idempotentDebit(String balance) {
    return 'İşlem daha önce tamamlanmıştı. Güncel bakiye: $balance';
  }

  @override
  String get caseReferenceOptional => 'Vaka / Referans (isteğe bağlı)';

  @override
  String get debitDoesNotDeleteLedger =>
      'Bu işlem mevcut ledger kayıtlarını silmez. Kullanıcının bakiyesine yeni bir negatif işlem kaydı eklenir.';

  @override
  String get auditTitle => 'İşlem Kayıtları';

  @override
  String get auditSubtitle => 'Admin paneli işlem geçmişi';

  @override
  String get actionType => 'İşlem türü';

  @override
  String get targetUserId => 'Hedef kullanıcı ID';

  @override
  String get action => 'İşlem';

  @override
  String get noAuditRecords => 'İşlem kaydı bulunamadı.';

  @override
  String get filterWalletCredit => 'Jeton Yükleme';

  @override
  String get filterWalletDebit => 'Jeton Eksiltme';

  @override
  String get filterSeriesUpdated => 'Dizi Güncellendi';

  @override
  String get filterPosterReplaced => 'Poster Değiştirildi';

  @override
  String get filterSeriesPublished => 'Dizi Yayınlandı';

  @override
  String get filterSeriesArchived => 'Dizi Arşivlendi';

  @override
  String get filterEpisodeUpdated => 'Bölüm Güncellendi';

  @override
  String get filterEpisodeReorder => 'Bölüm Sıralaması';

  @override
  String get filterVideoReplacement => 'Video Değişimi';

  @override
  String get filterAdminRoleChange => 'Admin Rolü Değişikliği';

  @override
  String get filterAdminAccessRevoke => 'Admin Erişimi Kaldırma';

  @override
  String get adminsTitle => 'Yöneticiler';

  @override
  String get adminsSubtitle => 'Admin paneli erişimi olan hesaplar';

  @override
  String get addAdmin => 'Yönetici Ekle';

  @override
  String get selectRole => 'Rol Seç';

  @override
  String get searchByIdEmailName =>
      'Kullanıcı ID, e-posta veya görünen ad ile arayın.';

  @override
  String get searchQuery => 'Arama sorgusu';

  @override
  String get makeAdmin => 'Yönetici Yap';

  @override
  String get adminRole => 'Admin';

  @override
  String get superAdminRole => 'Super Admin';

  @override
  String get thisGrantsAdminAccess =>
      'Bu işlem kullanıcının mevcut hesabını, profilini, cüzdanını veya geçmişini değiştirmez. Kullanıcıya admin paneli erişimi verir.';

  @override
  String get confirmRoleChange => 'Rol Değişikliğini Onayla';

  @override
  String newRole(String role) {
    return 'Yeni rol: $role';
  }

  @override
  String get roleChangeAffectsPermissions =>
      'Bu işlem kullanıcının admin paneli yetkilerini değiştirir.';

  @override
  String get roleUpdated => 'Rol güncellendi.';

  @override
  String get revokeAdminAccess => 'Admin Erişimini Kaldır';

  @override
  String get revokeAccessDoesNotDelete =>
      'Bu işlem kullanıcının giriş hesabını, profilini, cüzdanını veya geçmişini silmez. Yalnızca admin paneli erişimini kaldırır.';

  @override
  String get revokeAccess => 'Erişimi Kaldır';

  @override
  String get adminAccessRevoked => 'Admin erişimi kaldırıldı.';

  @override
  String get superAdminRequired =>
      'Bu sayfaya erişim için Super Admin yetkisi gerekiyor.';

  @override
  String get manager => 'Yönetici';

  @override
  String get role => 'Rol';

  @override
  String get becameAdmin => 'Yönetici olma';

  @override
  String get accountCreated => 'Hesap oluşturma';

  @override
  String get yourAccount => 'Kendi hesabınız';

  @override
  String get makeAdminAction => 'Admin Yap';

  @override
  String get makeSuperAdmin => 'Super Admin Yap';

  @override
  String get noAdminsFound => 'Kayıtlı yönetici bulunamadı.';

  @override
  String get partners => 'Partnerler';

  @override
  String get partnersSubtitle =>
      'İş birliği ortakları, üyeler ve analitikleri yönetin';

  @override
  String get createPartner => 'Partner Oluştur';

  @override
  String get editPartner => 'Partner Düzenle';

  @override
  String get partnerListLoadFailed => 'Partner listesi yüklenemedi.';

  @override
  String get analyticsHealthLoadFailed => 'Analitik sağlık durumu yüklenemedi.';

  @override
  String get partnerCreated => 'Partner oluşturuldu.';

  @override
  String get noPartnersYet => 'Henüz Partner yok.';

  @override
  String get members => 'Üyeler';

  @override
  String get activeAssignment => 'Aktif Atama';

  @override
  String get createdAt => 'Oluşturulma';

  @override
  String get unassigned => 'Atanmamış';

  @override
  String partnerNamed(String name) {
    return 'Partner ($name)';
  }

  @override
  String get displayNameStar => 'Görünen Ad *';

  @override
  String get displayNameRequired => 'Görünen ad zorunludur.';

  @override
  String get actionFailed => 'İşlem başarısız oldu.';

  @override
  String get partnerDetailLoadFailed => 'Partner detayı yüklenemedi.';

  @override
  String get partnerUpdated => 'Partner güncellendi.';

  @override
  String get memberAdded => 'Üye eklendi.';

  @override
  String get changeMemberStatus => 'Üye durumunu değiştir';

  @override
  String get memberStatusUpdated => 'Üye durumu güncellendi.';

  @override
  String get partner => 'Partner';

  @override
  String get analyticsNeedsAssignment =>
      'Analitik için önce bir dizi ataması gerekir.';

  @override
  String get addMember => 'Üye Ekle';

  @override
  String get noMembersYet => 'Henüz üye yok.';

  @override
  String get analyticsSeries => 'Analitik Dizisi';

  @override
  String get emailRequiredShort => 'E-posta zorunludur.';

  @override
  String get userSearchFailed => 'Kullanıcı aranamadı.';

  @override
  String get memberAddFailed => 'Üye eklenemedi.';

  @override
  String get findExistingAccount =>
      'Mevcut bir Vidxon hesabını tam e-posta ile bulun.';

  @override
  String get findUser => 'Kullanıcıyı Bul';

  @override
  String get addAsMember => 'Üye Olarak Ekle';

  @override
  String get assignmentHistory => 'Partner Atama Geçmişi';

  @override
  String get assignmentHistoryHint =>
      'Geçmiş aralıklar değiştirilemez. Atamalar [başlangıç, bitiş) ile kaydedilir.';

  @override
  String get noPartnerAssignments => 'Henüz Partner ataması yok.';

  @override
  String get analyticsReportLoadFailed => 'Analitik raporu yüklenemedi.';

  @override
  String get pageSnapshotMismatch =>
      'Sayfa anlık görüntüsü uyuşmuyor. Yenileyin.';

  @override
  String get episodePageLoadFailed => 'Bölüm sayfası yüklenemedi.';

  @override
  String get startDateUtc => 'Başlangıç tarihi (UTC günü)';

  @override
  String get endDateExclusiveUtc => 'Bitiş tarihi (hariç, UTC)';

  @override
  String get seriesAnalytics => 'Dizi Analitiği';

  @override
  String get analyticsReadonlyHint =>
      'Salt okunur · UTC dönem · Kazanç/ödeme yok';

  @override
  String get reportUnavailable => 'Rapor kullanılamıyor';

  @override
  String get errorNotShownAsZero =>
      'Hata durumu sıfır aktivite olarak gösterilmez.';

  @override
  String get reportNotReliable =>
      'Rapor şu an güvenilir sayısal sonuç üretmiyor.';

  @override
  String get episodeDistribution => 'Bölüm Dağılımı';

  @override
  String get episodeDistributionHidden =>
      'Bölüm dağılımı, bütünlük uyarısı nedeniyle yetkili sonuç olarak gösterilmiyor.';

  @override
  String get noEpisodeRecordsInPeriod => 'Bu dönemde bölüme ait kayıt yok.';

  @override
  String get loadMoreEpisodes => 'Daha fazla bölüm yükle';

  @override
  String get statusSuspended => 'Askıda';

  @override
  String get statusEnded => 'Sonlandırılmış';

  @override
  String get contentConflictReloaded =>
      'Bu içerik başka bir yönetici tarafından değiştirildi. Güncel veriler yeniden yüklendi; lütfen değişikliğinizi tekrar kontrol edin.';

  @override
  String get reorderConflictReloaded =>
      'İçerik düzenleme sırasında değişti. En güncel sıralama yüklendi.';

  @override
  String get videoReplacementUploaded =>
      'Yeni video yüklendi. Mevcut video yayında kalmaya devam eder; hazır olduğunda otomatik devreye alınır.';

  @override
  String get videoAttachedProcessing =>
      'Video yüklendi ve bölüme bağlandı. Cloudflare Stream videoyu işlemeye devam ediyor.';

  @override
  String get replaceVideo => 'Videoyu Değiştir';

  @override
  String get replaceVideoConfirm =>
      'Yeni video hazır olana kadar mevcut video yayında kalmaya devam eder.';

  @override
  String get publishEpisodeConfirm => 'Bu bölüm yayına alınsın mı?';

  @override
  String get episodePublished => 'Bölüm yayınlandı.';

  @override
  String get unpublishEpisodeTitle => 'Bölümü Yayından Kaldır?';

  @override
  String get unpublishEpisodeConfirm =>
      'Bu bölüm kullanıcılar tarafından erişilemez hâle gelecektir. Daha sonra tekrar yayınlayabilirsiniz.';

  @override
  String get episodeUnpublished => 'Bölüm yayından kaldırıldı.';

  @override
  String get archiveEpisodeConfirm => 'Bu bölüm arşivlenecek.';

  @override
  String get episodeArchived => 'Bölüm arşivlendi.';

  @override
  String get episodeRestored => 'Bölüm geri yüklendi.';

  @override
  String get archivedEpisodes => 'Arşivlenmiş Bölümler';

  @override
  String get uploadVideo => 'Video Yükle';

  @override
  String get previewActiveVideo => 'Aktif Videoyu Önizle';

  @override
  String get previewPendingVideo => 'Bekleyen Videoyu Önizle';

  @override
  String get videoNone => 'Video Yok';

  @override
  String get videoProcessing => 'İşleniyor';

  @override
  String get videoReady => 'Video Hazır';

  @override
  String get videoError => 'Video Hatası';

  @override
  String get pendingProcessing => 'Değişim: İşleniyor';

  @override
  String get pendingReady => 'Değişim: Hazır';

  @override
  String get pendingError => 'Değişim: Hata';

  @override
  String get pendingWaiting => 'Değişim: Bekliyor';

  @override
  String get originalAudioLanguage => 'Orijinal ses dili';

  @override
  String get dubs => 'Dublajlar';

  @override
  String get videoNotSelected => 'Video seçilmedi';

  @override
  String get uploadingVideo => 'Video Cloudflare\'a yükleniyor';

  @override
  String get attachingVideo => 'Video bölüme bağlanıyor';

  @override
  String get uploadCompleted => 'Yükleme tamamlandı';

  @override
  String get uploadFailedShort => 'Yükleme başarısız';

  @override
  String get videoUploadedAttachFailed =>
      'Video yüklendi fakat bölüme bağlanamadı. Videoyu yeniden yüklemeyin; bağlama işlemini tekrar deneyin.';

  @override
  String get uploadInProgress => 'Yükleme devam ediyor';

  @override
  String get uploadInProgressLeave =>
      'Video yüklemesi sürerken sayfadan ayrılırsanız işlem yarıda kalabilir. Yine de çıkmak istiyor musunuz?';

  @override
  String get videoFile => 'Video Dosyası';

  @override
  String get selectMp4 => 'MP4 Seç';

  @override
  String get noVideoSelectedYet => 'Henüz video seçilmedi.';

  @override
  String get retryAttach => 'Bağlamayı Tekrar Dene';

  @override
  String get videoProcessingContinues =>
      'Video Cloudflare Stream tarafından işlenmeye devam edecek. İşlem tamamlandığında bölüm listesinde durum güncellenecektir.';

  @override
  String get networkDisconnected =>
      'Ağ bağlantısı kesildi. Lütfen tekrar deneyin.';

  @override
  String get adminRoleDescription =>
      'Admin; kullanıcıları ve cüzdan işlemlerini yönetebilir, işlem kayıtlarını görüntüleyebilir.';

  @override
  String get superAdminRoleDescription =>
      'Super Admin; yönetici rollerini değiştirebilir, admin erişimini kaldırabilir ve tüm işlem kayıtlarını görüntüleyebilir.';

  @override
  String addedAsAdmin(String name) {
    return '$name Admin olarak eklendi.';
  }

  @override
  String addedAsSuperAdmin(String name) {
    return '$name Super Admin olarak eklendi.';
  }

  @override
  String userNamed(String name) {
    return 'Kullanıcı: $name';
  }

  @override
  String emailNamed(String email) {
    return 'E-posta: $email';
  }

  @override
  String userIdNamed(String id) {
    return 'Kullanıcı ID: $id';
  }

  @override
  String targetNamed(String name) {
    return 'Hedef: $name';
  }

  @override
  String becameAdminAt(String value) {
    return 'Yönetici olma: $value';
  }

  @override
  String lastSignInAt(String value) {
    return 'Son giriş: $value';
  }

  @override
  String previousBalance(String value) {
    return 'Önceki bakiye: $value';
  }

  @override
  String createdAtPrefixed(String value) {
    return 'Oluşturulma $value';
  }

  @override
  String get qualifiedViewsHelp =>
      'Bir kullanıcının bir bölümü ilk kez doğrulanmış izleme süresinde gerekli eşiğe ulaştırmasıyla oluşur. Aynı kullanıcının aynı bölümü tekrar izlemesi sayıyı artırmaz. Geçersiz veya manipülatif trafik hariç tutulur.';

  @override
  String get uniqueViewersTitle => 'Tekil İzleyici';

  @override
  String get uniqueViewersHelp =>
      'Seçilen dönemde ilgili içerikte en az bir doğrulanmış nitelikli izleme oluşturan farklı izleyici sayısı.';

  @override
  String get watchTimeTitle => 'İzlenme Süresi';

  @override
  String get watchTimeHelp =>
      'Seçilen dönemde sunucu tarafından doğrulanmış toplam izleme süresi. Tekrar izlemeler bu etkileşim metriğine dahil olabilir.';

  @override
  String get completionRateTitle => 'Tamamlama Oranı';

  @override
  String get completionRateHelp =>
      'Seçilen dönemde nitelikli oynatma oturumlarının ne kadarının %95 doğrulanmış izlemeye ulaştığını gösterir.';

  @override
  String get partnerChangeWarning =>
      'Partner atamasını değiştirmek mevcut atamayı şimdi kapatır ve (yeni Partner seçildiyse) yeni atamayı şimdi başlatır. Geçmiş atama aralıkları ve tarihsel metrikler korunur; geriye dönük tarihleme yapılamaz.';

  @override
  String get unassignWarning =>
      'Partner atamasını kaldırmak mevcut atamayı şimdi kapatır. Geçmiş atama aralıkları ve tarihsel metrikler korunur.';

  @override
  String get integrityUnavailable =>
      'Veri bütünlüğü: Kullanılamıyor. Metrikler güvenilir sonuç olarak gösterilmiyor.';

  @override
  String integrityWarning(String label) {
    return 'Veri bütünlüğü: $label. Bu rapordaki sayılar şimdilik yetkili finansal sonuç olarak sunulmaz; Analitik Sağlık kontrolünü inceleyin.';
  }

  @override
  String get presetTotal => 'Toplam';

  @override
  String get presetToday => 'Bugün';

  @override
  String get presetYesterday => 'Dün';

  @override
  String get presetLast7Days => 'Son 7 Gün';

  @override
  String get presetThisWeek => 'Bu Hafta';

  @override
  String get presetPreviousWeek => 'Geçen Hafta';

  @override
  String get presetLast30Days => 'Son 30 Gün';

  @override
  String get presetThisMonth => 'Bu Ay';

  @override
  String get presetPreviousMonth => 'Geçen Ay';

  @override
  String get presetCustom => 'Özel Aralık';

  @override
  String get integrityHealthy => 'Sağlıklı';

  @override
  String get integrityWarningLabel => 'Uyarı';

  @override
  String get integrityUnavailableLabel => 'Kullanılamıyor';

  @override
  String get reasonEventReward => 'Etkinlik Ödülü';

  @override
  String get reasonCustomerSupport => 'Müşteri Desteği';

  @override
  String get reasonTechnicalIssue => 'Teknik Sorun';

  @override
  String get reasonPromotional => 'Promosyon';

  @override
  String get reasonPaymentResolution => 'Ödeme Çözümü';

  @override
  String get reasonTestCredit => 'Test Jetonu';

  @override
  String get reasonOther => 'Diğer';

  @override
  String get reasonIncorrectCreditReversal =>
      'Yanlış Jeton Yüklemesini Geri Alma';

  @override
  String get reasonRewardCorrection => 'Hatalı Ödül Düzeltmesi';

  @override
  String get reasonAbuseCorrection => 'Kötüye Kullanım Düzeltmesi';

  @override
  String get reasonPaymentIssueResolution => 'Ödeme Sorunu Çözümü';

  @override
  String get reasonTestDebit => 'Test Jetonu Eksiltme';

  @override
  String get txnEpisodeUnlock => 'Bölüm Açma';

  @override
  String get txnRewardedAd => 'Reklam Ödülü';

  @override
  String get txnAdminCoinCredit => 'Admin Jeton Yükleme';

  @override
  String get txnAdminCoinDebit => 'Admin Jeton Eksiltme';

  @override
  String get txnAdminTestCredit => 'Eski Test Kredisi';

  @override
  String get systemActor => 'Sistem';

  @override
  String get anonymousUser => 'Anonim Kullanıcı';

  @override
  String get unconfirmed => 'Onaylanmamış';

  @override
  String get banned => 'Yasaklı';

  @override
  String get disabled => 'Devre Dışı';

  @override
  String get filterWalletDebitExact => 'Jeton Eksiltme';

  @override
  String memberCountAssignment(int count) {
    return 'Üye $count · Atama';
  }

  @override
  String get restoreEpisodeConfirm => 'Bu bölüm arşivden geri yüklensin mi?';

  @override
  String get ageNotSpecified => 'Belirtilmedi';

  @override
  String get descriptorViolence => 'Şiddet';

  @override
  String get descriptorStrongViolence => 'Yoğun Şiddet';

  @override
  String get descriptorProfanity => 'Kaba Dil';

  @override
  String get descriptorMatureThemes => 'Olgun Temalar';

  @override
  String get descriptorSexualContent => 'Cinsel İçerik';

  @override
  String get descriptorSubstance => 'Alkol / Tütün / Uyuşturucu Referansları';

  @override
  String get descriptorFearHorror => 'Korku / Gerilim';

  @override
  String get auditSeriesCreated => 'Dizi Oluşturuldu';

  @override
  String get auditSeriesUnpublished => 'Dizi Yayından Kaldırıldı';

  @override
  String get auditSeriesRestored => 'Dizi Geri Yüklendi';

  @override
  String get auditEpisodesReordered => 'Bölüm Sıralaması Değiştirildi';

  @override
  String get auditEpisodeCreated => 'Bölüm Oluşturuldu';

  @override
  String get auditEpisodePublished => 'Bölüm Yayınlandı';

  @override
  String get auditEpisodeUnpublished => 'Bölüm Yayından Kaldırıldı';

  @override
  String get auditEpisodeArchived => 'Bölüm Arşivlendi';

  @override
  String get auditEpisodeRestored => 'Bölüm Geri Yüklendi';

  @override
  String get auditVideoAttached => 'Video Bağlandı';

  @override
  String get auditVideoReplacementRequested => 'Video Değişimi İstendi';

  @override
  String get auditVideoPromoted => 'Video Aktif Edildi';

  @override
  String analyticsHealthFetchFailed(String message) {
    return 'Analitik sağlık durumu alınamadı: $message';
  }

  @override
  String analyticsHealthTitle(String label) {
    return 'Analitik Sağlık: $label';
  }

  @override
  String get analyticsIntegrityUnavailable =>
      'Analitik bütünlük doğrulaması şu anda kullanılamıyor.';

  @override
  String memberStatusConfirm(String name, String status) {
    return '$name durumu “$status” olarak ayarlansın mı?';
  }

  @override
  String get noResultsPeriod => 'Sonuç bulunamadı.';

  @override
  String get ready => 'Hazır';

  @override
  String get publishBlockedSeriesArchived =>
      'Arşivlenmiş bir dizinin bölümü yayınlanamaz.';

  @override
  String get publishBlockedEpisodeArchived => 'Arşivlenmiş bölüm yayınlanamaz.';

  @override
  String get publishBlockedNeedsVideo => 'Yayınlamak için aktif video gerekir.';

  @override
  String get publishBlockedVideoProcessing => 'Video işleniyor.';

  @override
  String get publishBlockedVideoError => 'Video hatası giderilmelidir.';

  @override
  String get publishBlockedVideoNotReady => 'Video henüz hazır değil.';

  @override
  String get publishBlockedPaidCoinPrice =>
      'Ücretli bölümde coin fiyatı 0\'dan büyük olmalıdır.';

  @override
  String get continueAction => 'Devam Et';

  @override
  String get stay => 'Kal';

  @override
  String get clearDate => 'Tarihi Temizle';

  @override
  String coinPriceHelper(int max) {
    return 'En fazla $max jeton';
  }

  @override
  String get qualified => 'Nitelikli';

  @override
  String get pending => 'Bekleyen';

  @override
  String get originalAudioSaveFailed => 'Orijinal ses dili kaydedilemedi.';

  @override
  String get maxFileSize200Mb => 'Maksimum dosya boyutu: 200 MB';

  @override
  String get supportedFormatMp4 => 'Desteklenen format: MP4 (video/mp4)';

  @override
  String currentVideoStatus(String status) {
    return 'Mevcut video durumu: $status';
  }

  @override
  String get noPendingVideo => 'Bekleyen video bulunmuyor.';

  @override
  String get durationMismatch =>
      'Süre bölümle uyuşmuyor; yayınlamadan önce senkronizasyonu doğrulayın.';

  @override
  String get date => 'Tarih';

  @override
  String get amount => 'Miktar';

  @override
  String get reason => 'Neden';

  @override
  String get reasonAlt => 'Sebep';

  @override
  String get reference => 'Referans';

  @override
  String get next => 'Sonraki';

  @override
  String get accountStatus => 'Hesap durumu';

  @override
  String get currentBalance => 'Mevcut bakiye';

  @override
  String currentBalancePrefixed(String value) {
    return 'Mevcut bakiye: $value';
  }

  @override
  String get newBalance => 'Yeni bakiye';

  @override
  String estimatedNewBalance(String value) {
    return 'Tahmini yeni bakiye: $value';
  }

  @override
  String get toDebit => 'Eksiltilecek';

  @override
  String get back => 'Geri';

  @override
  String get continueShort => 'Devam';

  @override
  String get legalName => 'Yasal Ad';

  @override
  String get ongoingAssignment => 'devam ediyor';

  @override
  String errorPrefixed(String message) {
    return 'Hata: $message';
  }

  @override
  String currentRolePrefixed(String role) {
    return 'Mevcut rol: $role';
  }

  @override
  String get actionsColumn => 'Aksiyonlar';

  @override
  String get confirmTitle => 'Onay';

  @override
  String roleToGrantPrefixed(String role) {
    return 'Verilecek rol: $role';
  }

  @override
  String amountPrefixed(String value) {
    return 'Miktar: $value';
  }

  @override
  String nextBalancePrefixed(String value) {
    return 'Sonraki bakiye: $value';
  }

  @override
  String reasonPrefixed(String value) {
    return 'Sebep: $value';
  }

  @override
  String datePrefixed(String value) {
    return 'Tarih: $value';
  }

  @override
  String referencePrefixed(String value) {
    return 'Referans: $value';
  }

  @override
  String get noEmail => 'E-posta yok';

  @override
  String get unknownStatus => 'Bilinmiyor';

  @override
  String get pushSending => 'Gönderiliyor';

  @override
  String get pushCancelled => 'İptal Edildi';

  @override
  String coinsDebited(String amount, String balance) {
    return '$amount jeton eksiltildi. Yeni bakiye: $balance';
  }

  @override
  String balanceArrow(String before, String after) {
    return 'Bakiye: $before → $after';
  }
}
