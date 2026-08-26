/// Turkish metric help copy for Partner analytics (no payment implication).
abstract final class PartnerMetricCopy {
  static const qualifiedViewsTitle = 'Nitelikli İzlenme';
  static const uniqueViewersTitle = 'Tekil İzleyici';
  static const watchTimeTitle = 'İzlenme Süresi';
  static const completionRateTitle = 'Tamamlama Oranı';

  static const qualifiedViewsHelp =
      'Bir kullanıcının bir bölümü ilk kez doğrulanmış izleme süresinde '
      'gerekli eşiğe ulaştırmasıyla oluşur. Aynı kullanıcının aynı bölümü '
      'tekrar izlemesi sayıyı artırmaz. Geçersiz veya manipülatif trafik '
      'hariç tutulur.';

  static const uniqueViewersHelp =
      'Seçilen dönemde ilgili içerikte en az bir doğrulanmış nitelikli '
      'izleme oluşturan farklı izleyici sayısı.';

  static const watchTimeHelp =
      'Seçilen dönemde sunucu tarafından doğrulanan toplam izleme süresi. '
      'Tekrar izlemeler bu etkileşim metriğine dahil olabilir.';

  static const completionRateHelp =
      'Seçilen dönemde nitelikli oynatma oturumlarının ne kadarının '
      '%95 doğrulanmış izlemeye ulaştığını gösterir.';

  static const partnerChangeWarning =
      'Partner atamasını değiştirmek mevcut atamayı şimdi kapatır ve '
      '(yeni Partner seçildiyse) yeni atamayı şimdi başlatır. '
      'Geçmiş atama aralıkları ve tarihsel metrikler korunur; '
      'geriye dönük tarihleme yapılamaz.';

  static const unassignWarning =
      'Partner atamasını kaldırmak mevcut atamayı şimdi kapatır. '
      'Geçmiş atama aralıkları ve tarihsel metrikler korunur.';

  static String formatCompletionRate(double? rate) {
    if (rate == null) {
      return '—';
    }
    final pct = (rate * 100).toStringAsFixed(1);
    return '%$pct';
  }

  static String formatWatchSeconds(int seconds) {
    if (seconds < 60) {
      return '$seconds sn';
    }
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remSeconds = seconds % 60;
    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    }
    if (remSeconds == 0) {
      return '${minutes}dk';
    }
    return '${minutes}dk ${remSeconds}sn';
  }
}
