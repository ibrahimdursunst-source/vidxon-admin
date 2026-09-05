// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
      'Supabase connection details are missing.\n\nRun the app with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.';

  @override
  String get loginUnexpectedError =>
      'An unexpected error occurred while signing in.';

  @override
  String get email => 'Email';

  @override
  String get emailRequired => 'Enter your email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get authorizationFailed => 'Authorization check failed';

  @override
  String get retry => 'Try Again';

  @override
  String get accessDenied => 'Access denied';

  @override
  String get accessDeniedMessage =>
      'This account is not among Vidxon admin users.';

  @override
  String get adminContextLoadFailed =>
      'Admin session information could not be loaded.';

  @override
  String get navOverview => 'Overview';

  @override
  String get navSeries => 'Series';

  @override
  String get navUsers => 'Users';

  @override
  String get navAudit => 'Activity Log';

  @override
  String get navPartners => 'Partners';

  @override
  String get navCampaigns => 'Campaigns';

  @override
  String get navAdmins => 'Admins';

  @override
  String get navEpisodes => 'Episodes';

  @override
  String get navCategories => 'Categories';

  @override
  String get navMedia => 'Media';

  @override
  String get refresh => 'Refresh';

  @override
  String get comingSoonSection => 'This section will be added soon.';

  @override
  String get dataLoadFailed => 'Data could not be loaded';

  @override
  String get overviewSubtitle => 'Summary of content statistics';

  @override
  String get cancel => 'Cancel';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get confirm => 'Confirm';

  @override
  String get loadMore => 'Load More';

  @override
  String get published => 'Published';

  @override
  String get notPublished => 'Unpublished';

  @override
  String get draft => 'Draft';

  @override
  String get archived => 'Archived';

  @override
  String get archive => 'Archive';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get expired => 'Expired';

  @override
  String get statusOngoing => 'Ongoing';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusComingSoon => 'Coming Soon';

  @override
  String get all => 'All';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get free => 'Free';

  @override
  String get destinationType => 'Destination Type';

  @override
  String get destinationNone => 'Information';

  @override
  String get destinationSeries => 'Series';

  @override
  String get destinationEpisode => 'Episode';

  @override
  String get destinationCoinPurchase => 'Buy Coins';

  @override
  String get destinationMembership => 'Membership';

  @override
  String get priority => 'Priority';

  @override
  String get priorityHelper =>
      'If more than one eligible campaign is active at the same time, the higher-priority campaign is shown first. When priority is equal, the newer start date wins. Default: 0.';

  @override
  String get changeSeries => 'Change Series';

  @override
  String get changeEpisode => 'Change Episode';

  @override
  String get searchSeries => 'Search series';

  @override
  String get titleOrSlug => 'Title or slug';

  @override
  String get noMatchingSeries => 'No matching series';

  @override
  String get seriesUnavailableBanner =>
      'The saved series is no longer available. The current destination is kept; the previous destination will not change unless you select a new series.';

  @override
  String get episodeUnavailableBanner =>
      'The saved episode is no longer available. The current destination is kept; the previous destination will not change unless you select a new episode.';

  @override
  String get selectSeriesFirst => 'Select a series first.';

  @override
  String get episodesLoading => 'Loading episodes...';

  @override
  String get episodesLoadFailed => 'Episodes could not be loaded.';

  @override
  String get episodesEmptyForSeries => 'This series has no episodes yet.';

  @override
  String get selectEpisode => 'Select episode';

  @override
  String episodePickerLabel(int number, String title) {
    return 'Episode $number · $title';
  }

  @override
  String episodePickerNumberOnly(int number) {
    return 'Episode $number';
  }

  @override
  String get selectSeries => 'Select a series';

  @override
  String get campaigns => 'Campaigns';

  @override
  String get popupTab => 'Pop-ups';

  @override
  String get pushTab => 'Push Notifications';

  @override
  String get editPopup => 'Edit Pop-up';

  @override
  String get createPopup => 'Create Pop-up';

  @override
  String get newPopup => 'New Pop-up';

  @override
  String get newPush => 'New Push Notification';

  @override
  String get schedule => 'Schedule';

  @override
  String messageForLocaleRequired(String locale) {
    return 'Message ($locale) *';
  }

  @override
  String get messageRequired => 'Message is required';

  @override
  String get ctaRequired => 'CTA is required';

  @override
  String ctaButtonForLocale(String locale) {
    return 'CTA Button ($locale)';
  }

  @override
  String ctaButtonForLocaleRequired(String locale) {
    return 'CTA Button ($locale) *';
  }

  @override
  String get image => 'Image';

  @override
  String get targetLanguages => 'Target Languages';

  @override
  String get startsAt => 'Start';

  @override
  String get endsAtOptional => 'End (optional)';

  @override
  String get endsAt => 'End';

  @override
  String get imageUploadingWait => 'Image is uploading, please wait.';

  @override
  String get imageUploadMustFinish =>
      'Cannot save until the image upload finishes.';

  @override
  String get imageFileUnreadable => 'The image file could not be read.';

  @override
  String get imageUploadFailed => 'The image could not be uploaded.';

  @override
  String get imageUploaded => 'Image uploaded';

  @override
  String get imageNotSelectedOptional => 'No image selected (optional)';

  @override
  String get changeImage => 'Change Image';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get noPopupCampaigns => 'No pop-up campaign has been created yet.';

  @override
  String get title => 'Title';

  @override
  String get titleRequiredStar => 'Title *';

  @override
  String get titleRequired => 'Title is required.';

  @override
  String get titleRequiredShort => 'Title is required';

  @override
  String titleForLocaleRequired(String locale) {
    return 'Title ($locale) *';
  }

  @override
  String descriptionForLocale(String locale) {
    return 'Description ($locale)';
  }

  @override
  String get description => 'Description';

  @override
  String get languages => 'Languages';

  @override
  String get target => 'Destination';

  @override
  String get editPush => 'Edit Push';

  @override
  String get createPush => 'Create Push';

  @override
  String get delivery => 'Delivery';

  @override
  String get chooseSchedule => 'Choose Schedule';

  @override
  String get saveDraft => 'Save Draft';

  @override
  String get sendPush => 'Send Push';

  @override
  String sendPushConfirm(String title) {
    return 'Do you want to send the \"$title\" campaign now?';
  }

  @override
  String get send => 'Send';

  @override
  String get pushSendStarted => 'Push delivery has started.';

  @override
  String get noPushCampaigns => 'No push notification has been created yet.';

  @override
  String get planOrDelivery => 'Schedule/Delivery';

  @override
  String get sent => 'Sent';

  @override
  String get failed => 'Failed';

  @override
  String get sendNow => 'Send Now';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get contentRating => 'Content Rating';

  @override
  String get contentRatingDisclaimer =>
      'These are in-app Vidxon suitability labels; they do not replace App Store / Google Play ratings.';

  @override
  String get ageRating => 'Age Rating';

  @override
  String get contentDescriptors => 'Content Descriptors';

  @override
  String get validCoinPrice => 'Enter a valid coin price.';

  @override
  String get validEpisodeNumber => 'Enter a valid episode number.';

  @override
  String get episodeUpdated => 'Episode updated successfully.';

  @override
  String get episodeCreated => 'Episode created successfully.';

  @override
  String get unexpectedRetry =>
      'An unexpected error occurred. Please try again.';

  @override
  String get editEpisode => 'Edit Episode';

  @override
  String get newEpisode => 'New Episode';

  @override
  String get episodeNumberStar => 'Episode Number *';

  @override
  String get episodeNumberReorderHint =>
      'Episode number is changed from the reorder screen.';

  @override
  String get episodeNumberMustBePositive =>
      'Episode number must be greater than 0.';

  @override
  String get useDifferentRatingForEpisode =>
      'Use a different rating for this episode';

  @override
  String get episodeSpecificRating => 'Episode-specific rating';

  @override
  String get useSeriesRating => 'Use series rating';

  @override
  String get inheritDescriptorsFromSeries =>
      'Inherit descriptors from the series';

  @override
  String get seriesDescriptorsUsed => 'Series descriptors are used';

  @override
  String get episodeNoDescriptors =>
      'This episode has no descriptors (explicit empty list)';

  @override
  String get episodeSpecificDescriptors => 'Episode-specific descriptor list';

  @override
  String get freeEpisode => 'Free Episode';

  @override
  String get coinPrice => 'Coin Price';

  @override
  String get coinPriceNotNegative => 'Coin price cannot be negative.';

  @override
  String coinPriceMax(int max) {
    return 'Coin price can be at most $max.';
  }

  @override
  String get freeEpisodeCoinMustBeZero =>
      'Free episodes must have a coin price of 0.';

  @override
  String get releaseDate => 'Release Date';

  @override
  String get notSelected => 'Not selected';

  @override
  String get publishStatus => 'Publish Status';

  @override
  String get status => 'Status';

  @override
  String get video => 'Video';

  @override
  String get pendingVideo => 'Pending Video';

  @override
  String get qualifiedViews => 'Qualified Views';

  @override
  String get legacyCounterSeed => 'Legacy Counter (seed)';

  @override
  String get mediaTracksLoadFailed =>
      'Media tracks could not be loaded. Please try again.';

  @override
  String get invalidLocaleExample =>
      'Invalid locale code. Example: tr, en, pt_BR, zh_Hans.';

  @override
  String get originalAudioUpdated => 'Original audio language updated.';

  @override
  String get audioUploadAccepted => 'Audio track upload request received.';

  @override
  String get audioReplaceAccepted =>
      'Audio track replacement request received.';

  @override
  String get subtitleUploaded => 'Subtitle uploaded.';

  @override
  String get subtitleReplaced => 'Subtitle replaced.';

  @override
  String get removeAudioTrack => 'Remove audio track';

  @override
  String removeAudioTrackConfirm(String locale) {
    return 'Remove the dub in $locale?';
  }

  @override
  String get audioTrackRemoved => 'Audio track removed.';

  @override
  String get audioTrackRemoveFailed => 'The audio track could not be removed.';

  @override
  String get removeSubtitle => 'Remove subtitle';

  @override
  String removeSubtitleConfirm(String locale) {
    return 'Remove the subtitle in $locale?';
  }

  @override
  String get subtitleRemoved => 'Subtitle removed.';

  @override
  String get subtitleRemoveFailed => 'The subtitle could not be removed.';

  @override
  String get statusUpdateFailed => 'Status could not be updated.';

  @override
  String get audioSubtitles => 'Audio / Subtitles';

  @override
  String get originalAudioHelp =>
      'Language of the video\'s embedded program audio. Dub languages must be different from this value.';

  @override
  String get noDubsYet => 'No dubs yet.';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get noSubtitlesYet => 'No subtitles yet.';

  @override
  String episodeDurationSeconds(int seconds) {
    return 'Episode duration: ${seconds}s';
  }

  @override
  String get localeCode => 'Locale code';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get replace => 'Replace';

  @override
  String get dubCannotMatchOriginal =>
      'Dub language cannot match the original audio language.';

  @override
  String get severeDurationNeedsConfirm =>
      'Upload is not allowed until the severe duration-difference checkbox is checked.';

  @override
  String get uploadFailedRetry => 'Upload failed. Please try again.';

  @override
  String get replaceAudioTrack => 'Replace audio track';

  @override
  String get addAudioTrack => 'Add audio track';

  @override
  String get audioDurationSeconds => 'Audio duration (seconds)';

  @override
  String get audioDurationHint => 'Enter to compare with the episode duration';

  @override
  String get severeDurationConfirm =>
      'I confirm the duration difference is severe and I still want to upload.';

  @override
  String get selectAudioFile => 'Select audio file (MP3 / M4A / AAC)';

  @override
  String get upload => 'Upload';

  @override
  String get replaceSubtitle => 'Replace subtitle';

  @override
  String get addSubtitle => 'Add subtitle';

  @override
  String get selectWebvtt => 'Select WebVTT (.vtt)';

  @override
  String get previewLoadFailed => 'Preview could not be loaded.';

  @override
  String get pendingVideoPreview => 'Pending Video Preview';

  @override
  String get activeVideoPreview => 'Active Video Preview';

  @override
  String get noActiveVideo => 'No active video.';

  @override
  String get activeVideoNotReady =>
      'The active video is not ready for preview yet.';

  @override
  String get pendingVideoNotReady =>
      'The pending video is not ready for preview yet.';

  @override
  String get previewWebOnly =>
      'Video preview is supported only in the web environment.';

  @override
  String get reorderSaveFailed => 'Order could not be saved.';

  @override
  String get reorderLoadFailed =>
      'The current order could not be loaded. Please close the page and try again.';

  @override
  String get unsavedReorder => 'Unsaved order';

  @override
  String get unsavedReorderMessage =>
      'Order changes were not saved. Do you want to leave?';

  @override
  String get leave => 'Leave';

  @override
  String get episodeOrder => 'Episode Order';

  @override
  String get saveOrder => 'Save Order';

  @override
  String get manageSeriesEpisodes => 'Manage episodes of the selected series';

  @override
  String get editOrder => 'Edit Order';

  @override
  String get access => 'Access';

  @override
  String get publish => 'Publish';

  @override
  String get actions => 'Actions';

  @override
  String releaseAtLabel(String value) {
    return 'Release: $value';
  }

  @override
  String get noEpisodesYet => 'No episodes yet';

  @override
  String get createFirstEpisode =>
      'You can create the first episode for this series.';

  @override
  String get episodesLoadFailedTitle => 'Episodes could not be loaded';

  @override
  String get validatingForm => 'Validating form';

  @override
  String get preparingUploadLink => 'Preparing upload link';

  @override
  String get uploadingPoster => 'Uploading poster';

  @override
  String get savingSeries => 'Saving series';

  @override
  String get posterUnreadable => 'The poster file could not be read.';

  @override
  String get posterRequired => 'A poster is required.';

  @override
  String get posterPathFailed => 'The poster path could not be created.';

  @override
  String get seriesCreated => 'Series created successfully.';

  @override
  String get posterAlreadyUploadedRetry =>
      'The poster is already uploaded. You can edit the details and try again.';

  @override
  String seriesCreatedPartnerFailed(String message) {
    return 'Series created but the partner assignment failed: $message';
  }

  @override
  String get seriesCreatedRetryPartner =>
      'The series was created. Retry the partner assignment from series details.';

  @override
  String get posterAlreadyUploaded =>
      'The poster is already uploaded. You can try again.';

  @override
  String get newSeries => 'New Series';

  @override
  String get slugHint => 'Lowercase letters, numbers, and hyphens';

  @override
  String get validSlug => 'Enter a valid slug.';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectPoster => 'Select Poster';

  @override
  String get publishSettings => 'Publish Settings';

  @override
  String get featured => 'Featured';

  @override
  String get collaborationPartner => 'Collaboration Partner';

  @override
  String get categories => 'Categories';

  @override
  String get categoriesLoadFailed => 'Categories could not be loaded.';

  @override
  String get noCategoriesYet => 'No categories yet.';

  @override
  String get createSeries => 'Create Series';

  @override
  String get seriesLoadFailed => 'Series could not be loaded.';

  @override
  String get assignmentHistoryLoadFailed =>
      'Assignment history could not be loaded.';

  @override
  String get removePartnerAssignment => 'Remove partner assignment';

  @override
  String get changePartnerAssignment => 'Change partner assignment';

  @override
  String get removeAssignment => 'Remove Assignment';

  @override
  String get changeAssignment => 'Change Assignment';

  @override
  String get seriesUpdated => 'Series updated.';

  @override
  String get seriesUpdateFailed => 'Series could not be updated.';

  @override
  String get posterUpdated => 'Poster updated.';

  @override
  String get posterUpdateFailed => 'Poster could not be updated.';

  @override
  String get actionIncomplete => 'The action could not be completed.';

  @override
  String get publishSeries => 'Publish';

  @override
  String get publishSeriesConfirm => 'Publish this series?';

  @override
  String get seriesPublished => 'Series published.';

  @override
  String get unpublish => 'Unpublish';

  @override
  String get unpublishSeriesConfirm => 'Unpublish this series?';

  @override
  String get seriesUnpublished => 'Series unpublished.';

  @override
  String get archiveAction => 'Archive';

  @override
  String get archiveSeriesConfirm =>
      'This series will be archived. Archived content is unpublished and editing may be restricted.';

  @override
  String get seriesArchived => 'Series archived.';

  @override
  String get restore => 'Restore';

  @override
  String get restoreSeriesConfirm => 'Restore this series from the archive?';

  @override
  String get seriesRestored => 'Series restored.';

  @override
  String get seriesDetail => 'Series Detail';

  @override
  String get seriesNotFound => 'Series not found.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get partnerChangeClosesAssignment =>
      'The change closes the current assignment now; history is kept.';

  @override
  String episodeCountLabel(int count) {
    return '$count episodes';
  }

  @override
  String get selectNewPoster => 'Select New Poster';

  @override
  String get changePoster => 'Change Poster';

  @override
  String get seriesInfo => 'Series Information';

  @override
  String get publishAndArchive => 'Publish and Archive';

  @override
  String get noSeriesYet => 'No series yet';

  @override
  String get noResults => 'No results found';

  @override
  String get noSeriesMatchFilters =>
      'No series matched your search or filter criteria.';

  @override
  String get seriesCatalogSubtitle =>
      'Manage series in the Vidxon content catalog';

  @override
  String get searchSeriesNameOrSlug => 'Search series name or slug...';

  @override
  String get seriesName => 'Series Name';

  @override
  String get category => 'Category';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get editOrDetail => 'Edit / Detail';

  @override
  String updatedAtLabel(String value) {
    return 'Updated: $value';
  }

  @override
  String get seriesLoadFailedTitle => 'Series could not be loaded';

  @override
  String get seriesCatalogLoadFailed =>
      'Series could not be loaded. Please try again.';

  @override
  String get noSeriesInCatalog => 'There are no series in the catalog to list.';

  @override
  String get newSeriesSubtitle => 'Add a new series to the catalog';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get slugRequiredStar => 'Slug *';

  @override
  String get poster => 'Poster';

  @override
  String get posterRequiredStar => 'Poster *';

  @override
  String get posterFormatsHint => 'JPG, PNG, or WEBP · Maximum 10 MiB';

  @override
  String get premium => 'Premium';

  @override
  String get detail => 'Detail';

  @override
  String qualifiedViewsCount(int count) {
    return 'Qualified: $count';
  }

  @override
  String get users => 'Users';

  @override
  String get usersSubtitle => 'Search users, view details, and credit coins';

  @override
  String get searchUsersHint => 'Search by user ID, email, or display name';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get displayName => 'Display Name';

  @override
  String get userId => 'User ID';

  @override
  String get coins => 'Coins';

  @override
  String get registration => 'Registered';

  @override
  String get copyUserId => 'Copy user ID';

  @override
  String get userIdCopied => 'User ID copied.';

  @override
  String registeredAt(String value) {
    return 'Registered: $value';
  }

  @override
  String get userNotFound => 'User not found';

  @override
  String get noUsersMatch => 'No users matched your search criteria.';

  @override
  String get usersLoadFailed => 'Users could not be loaded';

  @override
  String get userDetail => 'User Detail';

  @override
  String get creditCoins => 'Credit Coins';

  @override
  String get debitCoins => 'Debit Coins';

  @override
  String get coinLedger => 'Coin Movement History';

  @override
  String get registeredDate => 'Registration date';

  @override
  String get lastSignIn => 'Last sign-in';

  @override
  String get currentCoinBalance => 'Current coin balance';

  @override
  String get walletLastUpdate => 'Wallet last updated';

  @override
  String get totalLedgerRecords => 'Total ledger records';

  @override
  String get adminCreditTotal => 'Admin credit total';

  @override
  String coinsAmount(int count) {
    return '$count coins';
  }

  @override
  String get type => 'Type';

  @override
  String get previous => 'Previous';

  @override
  String get admin => 'Admin';

  @override
  String get noCoinMovements => 'No coin movements yet.';

  @override
  String get userDetailLoadFailed => 'User detail could not be loaded';

  @override
  String get adminAccountsNoManualCoins =>
      'Manual coin operations cannot be performed on admin accounts.';

  @override
  String get coinsSuperAdminOnly =>
      'Coin operations can be performed only by a Super Admin.';

  @override
  String get confirmTransaction => 'Confirm Transaction';

  @override
  String get coinAmount => 'Coin amount';

  @override
  String get supportReferenceOptional =>
      'Support / transaction reference (optional)';

  @override
  String get user => 'User';

  @override
  String get toCredit => 'To credit';

  @override
  String get thisChangesBalance =>
      'This operation will change the user balance.';

  @override
  String creditCoinsAmount(int amount) {
    return 'Credit $amount Coins';
  }

  @override
  String get coinsCredited => 'Coins credited successfully.';

  @override
  String get idempotentCredit =>
      'This operation was already completed. The current balance was refreshed.';

  @override
  String get insufficientBalance =>
      'The user\'s balance is insufficient for this operation.';

  @override
  String idempotentDebit(String balance) {
    return 'The operation was already completed. Current balance: $balance';
  }

  @override
  String get caseReferenceOptional => 'Case / Reference (optional)';

  @override
  String get debitDoesNotDeleteLedger =>
      'This operation does not delete existing ledger records. A new negative transaction is added to the user\'s balance.';

  @override
  String get auditTitle => 'Activity Log';

  @override
  String get auditSubtitle => 'Admin panel activity history';

  @override
  String get actionType => 'Action type';

  @override
  String get targetUserId => 'Target user ID';

  @override
  String get action => 'Action';

  @override
  String get noAuditRecords => 'No activity records found.';

  @override
  String get filterWalletCredit => 'Coin Credit';

  @override
  String get filterWalletDebit => 'Coin Debit';

  @override
  String get filterSeriesUpdated => 'Series Updated';

  @override
  String get filterPosterReplaced => 'Poster Replaced';

  @override
  String get filterSeriesPublished => 'Series Published';

  @override
  String get filterSeriesArchived => 'Series Archived';

  @override
  String get filterEpisodeUpdated => 'Episode Updated';

  @override
  String get filterEpisodeReorder => 'Episode Order';

  @override
  String get filterVideoReplacement => 'Video Replacement';

  @override
  String get filterAdminRoleChange => 'Admin Role Change';

  @override
  String get filterAdminAccessRevoke => 'Admin Access Revoke';

  @override
  String get adminsTitle => 'Admins';

  @override
  String get adminsSubtitle => 'Accounts with admin panel access';

  @override
  String get addAdmin => 'Add Admin';

  @override
  String get selectRole => 'Select Role';

  @override
  String get searchByIdEmailName =>
      'Search by user ID, email, or display name.';

  @override
  String get searchQuery => 'Search query';

  @override
  String get makeAdmin => 'Make Admin';

  @override
  String get adminRole => 'Admin';

  @override
  String get superAdminRole => 'Super Admin';

  @override
  String get thisGrantsAdminAccess =>
      'This does not change the user\'s existing account, profile, wallet, or history. It grants admin panel access.';

  @override
  String get confirmRoleChange => 'Confirm Role Change';

  @override
  String newRole(String role) {
    return 'New role: $role';
  }

  @override
  String get roleChangeAffectsPermissions =>
      'This changes the user\'s admin panel permissions.';

  @override
  String get roleUpdated => 'Role updated.';

  @override
  String get revokeAdminAccess => 'Revoke Admin Access';

  @override
  String get revokeAccessDoesNotDelete =>
      'This does not delete the user\'s sign-in account, profile, wallet, or history. It only removes admin panel access.';

  @override
  String get revokeAccess => 'Revoke Access';

  @override
  String get adminAccessRevoked => 'Admin access revoked.';

  @override
  String get superAdminRequired =>
      'Super Admin permission is required to access this page.';

  @override
  String get manager => 'Admin';

  @override
  String get role => 'Role';

  @override
  String get becameAdmin => 'Became admin';

  @override
  String get accountCreated => 'Account created';

  @override
  String get yourAccount => 'Your account';

  @override
  String get makeAdminAction => 'Make Admin';

  @override
  String get makeSuperAdmin => 'Make Super Admin';

  @override
  String get noAdminsFound => 'No registered admins found.';

  @override
  String get partners => 'Partners';

  @override
  String get partnersSubtitle =>
      'Manage collaboration partners, members, and analytics';

  @override
  String get createPartner => 'Create Partner';

  @override
  String get editPartner => 'Edit Partner';

  @override
  String get partnerListLoadFailed => 'Partner list could not be loaded.';

  @override
  String get analyticsHealthLoadFailed =>
      'Analytics health status could not be loaded.';

  @override
  String get partnerCreated => 'Partner created.';

  @override
  String get noPartnersYet => 'No partners yet.';

  @override
  String get members => 'Members';

  @override
  String get activeAssignment => 'Active Assignment';

  @override
  String get createdAt => 'Created';

  @override
  String get unassigned => 'Unassigned';

  @override
  String partnerNamed(String name) {
    return 'Partner ($name)';
  }

  @override
  String get displayNameStar => 'Display Name *';

  @override
  String get displayNameRequired => 'Display name is required.';

  @override
  String get actionFailed => 'The operation failed.';

  @override
  String get partnerDetailLoadFailed => 'Partner detail could not be loaded.';

  @override
  String get partnerUpdated => 'Partner updated.';

  @override
  String get memberAdded => 'Member added.';

  @override
  String get changeMemberStatus => 'Change member status';

  @override
  String get memberStatusUpdated => 'Member status updated.';

  @override
  String get partner => 'Partner';

  @override
  String get analyticsNeedsAssignment =>
      'A series assignment is required before analytics.';

  @override
  String get addMember => 'Add Member';

  @override
  String get noMembersYet => 'No members yet.';

  @override
  String get analyticsSeries => 'Analytics Series';

  @override
  String get emailRequiredShort => 'Email is required.';

  @override
  String get userSearchFailed => 'The user could not be searched.';

  @override
  String get memberAddFailed => 'The member could not be added.';

  @override
  String get findExistingAccount =>
      'Find an existing Vidxon account by full email.';

  @override
  String get findUser => 'Find User';

  @override
  String get addAsMember => 'Add as Member';

  @override
  String get assignmentHistory => 'Partner Assignment History';

  @override
  String get assignmentHistoryHint =>
      'Past intervals cannot be changed. Assignments are stored as [start, end).';

  @override
  String get noPartnerAssignments => 'No partner assignments yet.';

  @override
  String get analyticsReportLoadFailed =>
      'Analytics report could not be loaded.';

  @override
  String get pageSnapshotMismatch => 'Page snapshot mismatch. Refresh.';

  @override
  String get episodePageLoadFailed => 'Episode page could not be loaded.';

  @override
  String get startDateUtc => 'Start date (UTC day)';

  @override
  String get endDateExclusiveUtc => 'End date (exclusive, UTC)';

  @override
  String get seriesAnalytics => 'Series Analytics';

  @override
  String get analyticsReadonlyHint =>
      'Read-only · UTC period · No earnings/payouts';

  @override
  String get reportUnavailable => 'Report unavailable';

  @override
  String get errorNotShownAsZero =>
      'An error state is not shown as zero activity.';

  @override
  String get reportNotReliable =>
      'The report is not producing reliable numeric results right now.';

  @override
  String get episodeDistribution => 'Episode Distribution';

  @override
  String get episodeDistributionHidden =>
      'Episode distribution is not shown as an authoritative result because of an integrity warning.';

  @override
  String get noEpisodeRecordsInPeriod => 'No episode records for this period.';

  @override
  String get loadMoreEpisodes => 'Load more episodes';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get statusEnded => 'Ended';

  @override
  String get contentConflictReloaded =>
      'This content was changed by another admin. The latest data was reloaded; please review your change again.';

  @override
  String get reorderConflictReloaded =>
      'The content changed while you were editing. The latest order was loaded.';

  @override
  String get videoReplacementUploaded =>
      'The new video was uploaded. The current video stays published and will go live automatically when ready.';

  @override
  String get videoAttachedProcessing =>
      'The video was uploaded and attached to the episode. Cloudflare Stream is still processing it.';

  @override
  String get replaceVideo => 'Replace Video';

  @override
  String get replaceVideoConfirm =>
      'The current video stays published until the new video is ready.';

  @override
  String get publishEpisodeConfirm => 'Publish this episode?';

  @override
  String get episodePublished => 'Episode published.';

  @override
  String get unpublishEpisodeTitle => 'Unpublish Episode?';

  @override
  String get unpublishEpisodeConfirm =>
      'This episode will become inaccessible to users. You can publish it again later.';

  @override
  String get episodeUnpublished => 'Episode unpublished.';

  @override
  String get archiveEpisodeConfirm => 'This episode will be archived.';

  @override
  String get episodeArchived => 'Episode archived.';

  @override
  String get episodeRestored => 'Episode restored.';

  @override
  String get archivedEpisodes => 'Archived Episodes';

  @override
  String get uploadVideo => 'Upload Video';

  @override
  String get previewActiveVideo => 'Preview Active Video';

  @override
  String get previewPendingVideo => 'Preview Pending Video';

  @override
  String get videoNone => 'No Video';

  @override
  String get videoProcessing => 'Processing';

  @override
  String get videoReady => 'Video Ready';

  @override
  String get videoError => 'Video Error';

  @override
  String get pendingProcessing => 'Replacement: Processing';

  @override
  String get pendingReady => 'Replacement: Ready';

  @override
  String get pendingError => 'Replacement: Error';

  @override
  String get pendingWaiting => 'Replacement: Waiting';

  @override
  String get originalAudioLanguage => 'Original audio language';

  @override
  String get dubs => 'Dubs';

  @override
  String get videoNotSelected => 'No video selected';

  @override
  String get uploadingVideo => 'Uploading video to Cloudflare';

  @override
  String get attachingVideo => 'Attaching video to the episode';

  @override
  String get uploadCompleted => 'Upload completed';

  @override
  String get uploadFailedShort => 'Upload failed';

  @override
  String get videoUploadedAttachFailed =>
      'The video was uploaded but could not be attached to the episode. Do not re-upload the video; retry the attach step.';

  @override
  String get uploadInProgress => 'Upload in progress';

  @override
  String get uploadInProgressLeave =>
      'If you leave this page while the video is uploading, the operation may be interrupted. Leave anyway?';

  @override
  String get videoFile => 'Video File';

  @override
  String get selectMp4 => 'Select MP4';

  @override
  String get noVideoSelectedYet => 'No video selected yet.';

  @override
  String get retryAttach => 'Retry Attach';

  @override
  String get videoProcessingContinues =>
      'Cloudflare Stream will keep processing the video. The status will update in the episode list when it finishes.';

  @override
  String get networkDisconnected =>
      'The network connection was lost. Please try again.';

  @override
  String get adminRoleDescription =>
      'Admin can manage users and wallet operations and view the activity log.';

  @override
  String get superAdminRoleDescription =>
      'Super Admin can change admin roles, revoke admin access, and view the full activity log.';

  @override
  String addedAsAdmin(String name) {
    return '$name was added as Admin.';
  }

  @override
  String addedAsSuperAdmin(String name) {
    return '$name was added as Super Admin.';
  }

  @override
  String userNamed(String name) {
    return 'User: $name';
  }

  @override
  String emailNamed(String email) {
    return 'Email: $email';
  }

  @override
  String userIdNamed(String id) {
    return 'User ID: $id';
  }

  @override
  String targetNamed(String name) {
    return 'Target: $name';
  }

  @override
  String becameAdminAt(String value) {
    return 'Became admin: $value';
  }

  @override
  String lastSignInAt(String value) {
    return 'Last sign-in: $value';
  }

  @override
  String previousBalance(String value) {
    return 'Previous balance: $value';
  }

  @override
  String createdAtPrefixed(String value) {
    return 'Created $value';
  }

  @override
  String get qualifiedViewsHelp =>
      'Created when a user first reaches the required verified watch-time threshold for an episode. Repeat views by the same user of the same episode do not increase the count. Invalid or manipulative traffic is excluded.';

  @override
  String get uniqueViewersTitle => 'Unique Viewers';

  @override
  String get uniqueViewersHelp =>
      'Number of distinct viewers who created at least one verified qualified view on the related content in the selected period.';

  @override
  String get watchTimeTitle => 'Watch Time';

  @override
  String get watchTimeHelp =>
      'Total server-verified watch time in the selected period. Replays may be included in this engagement metric.';

  @override
  String get completionRateTitle => 'Completion Rate';

  @override
  String get completionRateHelp =>
      'Shows how many qualified playback sessions in the selected period reached 95% verified watch.';

  @override
  String get partnerChangeWarning =>
      'Changing the partner assignment closes the current assignment now and (if a new Partner is selected) starts the new assignment now. Past assignment intervals and historical metrics are kept; backdating is not allowed.';

  @override
  String get unassignWarning =>
      'Removing the partner assignment closes the current assignment now. Past assignment intervals and historical metrics are kept.';

  @override
  String get integrityUnavailable =>
      'Data integrity: Unavailable. Metrics are not shown as a reliable result.';

  @override
  String integrityWarning(String label) {
    return 'Data integrity: $label. Numbers in this report are not presented as an authoritative financial result for now; review the Analytics Health check.';
  }

  @override
  String get presetTotal => 'Total';

  @override
  String get presetToday => 'Today';

  @override
  String get presetYesterday => 'Yesterday';

  @override
  String get presetLast7Days => 'Last 7 Days';

  @override
  String get presetThisWeek => 'This Week';

  @override
  String get presetPreviousWeek => 'Previous Week';

  @override
  String get presetLast30Days => 'Last 30 Days';

  @override
  String get presetThisMonth => 'This Month';

  @override
  String get presetPreviousMonth => 'Previous Month';

  @override
  String get presetCustom => 'Custom Range';

  @override
  String get integrityHealthy => 'Healthy';

  @override
  String get integrityWarningLabel => 'Warning';

  @override
  String get integrityUnavailableLabel => 'Unavailable';

  @override
  String get reasonEventReward => 'Event Reward';

  @override
  String get reasonCustomerSupport => 'Customer Support';

  @override
  String get reasonTechnicalIssue => 'Technical Issue';

  @override
  String get reasonPromotional => 'Promotion';

  @override
  String get reasonPaymentResolution => 'Payment Resolution';

  @override
  String get reasonTestCredit => 'Test Coins';

  @override
  String get reasonOther => 'Other';

  @override
  String get reasonIncorrectCreditReversal => 'Reverse Incorrect Coin Credit';

  @override
  String get reasonRewardCorrection => 'Incorrect Reward Correction';

  @override
  String get reasonAbuseCorrection => 'Abuse Correction';

  @override
  String get reasonPaymentIssueResolution => 'Payment Issue Resolution';

  @override
  String get reasonTestDebit => 'Test Coin Debit';

  @override
  String get txnEpisodeUnlock => 'Episode Unlock';

  @override
  String get txnRewardedAd => 'Rewarded Ad';

  @override
  String get txnAdminCoinCredit => 'Admin Coin Credit';

  @override
  String get txnAdminCoinDebit => 'Admin Coin Debit';

  @override
  String get txnAdminTestCredit => 'Legacy Test Credit';

  @override
  String get systemActor => 'System';

  @override
  String get anonymousUser => 'Anonymous User';

  @override
  String get unconfirmed => 'Unconfirmed';

  @override
  String get banned => 'Banned';

  @override
  String get disabled => 'Disabled';

  @override
  String get filterWalletDebitExact => 'Coin Debit';

  @override
  String memberCountAssignment(int count) {
    return 'Members $count · Assignment';
  }

  @override
  String get restoreEpisodeConfirm => 'Restore this episode from the archive?';

  @override
  String get ageNotSpecified => 'Not specified';

  @override
  String get descriptorViolence => 'Violence';

  @override
  String get descriptorStrongViolence => 'Intense Violence';

  @override
  String get descriptorProfanity => 'Profanity';

  @override
  String get descriptorMatureThemes => 'Mature Themes';

  @override
  String get descriptorSexualContent => 'Sexual Content';

  @override
  String get descriptorSubstance => 'Alcohol / Tobacco / Drug References';

  @override
  String get descriptorFearHorror => 'Fear / Thriller';

  @override
  String get auditSeriesCreated => 'Series Created';

  @override
  String get auditSeriesUnpublished => 'Series Unpublished';

  @override
  String get auditSeriesRestored => 'Series Restored';

  @override
  String get auditEpisodesReordered => 'Episode Order Changed';

  @override
  String get auditEpisodeCreated => 'Episode Created';

  @override
  String get auditEpisodePublished => 'Episode Published';

  @override
  String get auditEpisodeUnpublished => 'Episode Unpublished';

  @override
  String get auditEpisodeArchived => 'Episode Archived';

  @override
  String get auditEpisodeRestored => 'Episode Restored';

  @override
  String get auditVideoAttached => 'Video Attached';

  @override
  String get auditVideoReplacementRequested => 'Video Replacement Requested';

  @override
  String get auditVideoPromoted => 'Video Activated';

  @override
  String analyticsHealthFetchFailed(String message) {
    return 'Analytics health could not be retrieved: $message';
  }

  @override
  String analyticsHealthTitle(String label) {
    return 'Analytics Health: $label';
  }

  @override
  String get analyticsIntegrityUnavailable =>
      'Analytics integrity verification is currently unavailable.';

  @override
  String memberStatusConfirm(String name, String status) {
    return 'Set $name\'s status to “$status”?';
  }

  @override
  String get noResultsPeriod => 'No results found.';

  @override
  String get ready => 'Ready';

  @override
  String get publishBlockedSeriesArchived =>
      'An episode of an archived series cannot be published.';

  @override
  String get publishBlockedEpisodeArchived =>
      'An archived episode cannot be published.';

  @override
  String get publishBlockedNeedsVideo =>
      'An active video is required to publish.';

  @override
  String get publishBlockedVideoProcessing => 'The video is processing.';

  @override
  String get publishBlockedVideoError => 'The video error must be resolved.';

  @override
  String get publishBlockedVideoNotReady => 'The video is not ready yet.';

  @override
  String get publishBlockedPaidCoinPrice =>
      'Paid episodes must have a coin price greater than 0.';

  @override
  String get continueAction => 'Continue';

  @override
  String get stay => 'Stay';

  @override
  String get clearDate => 'Clear Date';

  @override
  String coinPriceHelper(int max) {
    return 'Maximum $max coins';
  }

  @override
  String get qualified => 'Qualified';

  @override
  String get pending => 'Pending';

  @override
  String get originalAudioSaveFailed =>
      'Original audio language could not be saved.';

  @override
  String get maxFileSize200Mb => 'Maximum file size: 200 MB';

  @override
  String get supportedFormatMp4 => 'Supported format: MP4 (video/mp4)';

  @override
  String currentVideoStatus(String status) {
    return 'Current video status: $status';
  }

  @override
  String get noPendingVideo => 'No pending video.';

  @override
  String get durationMismatch =>
      'Duration does not match the episode; verify synchronization before publishing.';

  @override
  String get date => 'Date';

  @override
  String get amount => 'Amount';

  @override
  String get reason => 'Reason';

  @override
  String get reasonAlt => 'Reason';

  @override
  String get reference => 'Reference';

  @override
  String get next => 'Next';

  @override
  String get accountStatus => 'Account status';

  @override
  String get currentBalance => 'Current balance';

  @override
  String currentBalancePrefixed(String value) {
    return 'Current balance: $value';
  }

  @override
  String get newBalance => 'New balance';

  @override
  String estimatedNewBalance(String value) {
    return 'Estimated new balance: $value';
  }

  @override
  String get toDebit => 'To debit';

  @override
  String get back => 'Back';

  @override
  String get continueShort => 'Continue';

  @override
  String get legalName => 'Legal Name';

  @override
  String get ongoingAssignment => 'ongoing';

  @override
  String errorPrefixed(String message) {
    return 'Error: $message';
  }

  @override
  String currentRolePrefixed(String role) {
    return 'Current role: $role';
  }

  @override
  String get actionsColumn => 'Actions';

  @override
  String get confirmTitle => 'Confirm';

  @override
  String roleToGrantPrefixed(String role) {
    return 'Role to grant: $role';
  }

  @override
  String amountPrefixed(String value) {
    return 'Amount: $value';
  }

  @override
  String nextBalancePrefixed(String value) {
    return 'Next balance: $value';
  }

  @override
  String reasonPrefixed(String value) {
    return 'Reason: $value';
  }

  @override
  String datePrefixed(String value) {
    return 'Date: $value';
  }

  @override
  String referencePrefixed(String value) {
    return 'Reference: $value';
  }

  @override
  String get noEmail => 'No email';

  @override
  String get unknownStatus => 'Unknown';

  @override
  String get pushSending => 'Sending';

  @override
  String get pushCancelled => 'Cancelled';

  @override
  String coinsDebited(String amount, String balance) {
    return '$amount coins were debited. New balance: $balance';
  }

  @override
  String balanceArrow(String before, String after) {
    return 'Balance: $before → $after';
  }
}
