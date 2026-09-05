import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/admin_l10n.dart';
import '../../content/data/content_errors.dart';
import '../../content/presentation/content_conflict_helper.dart';
import '../../content_rating/presentation/content_rating_editor.dart';
import '../data/episode_repository.dart';
import '../domain/admin_episode.dart';
import '../domain/create_episode_input.dart';
import '../domain/episode_release_at.dart';
import '../domain/update_episode_input.dart';

class EpisodeFormPage extends StatefulWidget {
  const EpisodeFormPage({required this.seriesId, this.episode, super.key});

  final String seriesId;
  final AdminEpisode? episode;

  bool get isEditing => episode != null;

  @override
  State<EpisodeFormPage> createState() => _EpisodeFormPageState();
}

class _EpisodeFormPageState extends State<EpisodeFormPage> {
  static const _primaryColor = Color(0xFFE50914);

  final _formKey = GlobalKey<FormState>();
  final _episodeNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _synopsisController = TextEditingController();
  final _coinPriceController = TextEditingController(text: '0');

  final EpisodeRepository _repository = EpisodeRepository();

  AdminEpisode? _episode;
  bool _isFree = false;
  DateTime? _releaseAtLocal;
  bool _useContentRatingOverride = false;
  int? _contentAgeRating;

  /// Null = inherit series descriptors; non-null (including empty) = explicit.
  List<String>? _contentDescriptors;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _episode = widget.episode;
    _initializeFromEpisode();
  }

  void _initializeFromEpisode() {
    final episode = _episode;
    if (episode == null) {
      return;
    }

    _episodeNumberController.text = episode.episodeNumber.toString();
    _titleController.text = episode.title;
    _synopsisController.text = episode.synopsis;
    _coinPriceController.text = episode.coinPrice.toString();
    _isFree = episode.isFree;
    _releaseAtLocal = releaseAtUtcToLocal(episode.releaseAt);
    _useContentRatingOverride = episode.hasContentRatingOverride;
    _contentAgeRating = episode.contentAgeRating;
    // Preserve NULL (inherit) vs [] (explicit empty); do not collapse null → [].
    _contentDescriptors = episode.contentDescriptors == null
        ? null
        : List<String>.from(episode.contentDescriptors!);
  }

  @override
  void dispose() {
    _episodeNumberController.dispose();
    _titleController.dispose();
    _synopsisController.dispose();
    _coinPriceController.dispose();
    super.dispose();
  }

  int? _parseEpisodeNumber() {
    return int.tryParse(_episodeNumberController.text.trim());
  }

  int? _parseCoinPrice() {
    return int.tryParse(_coinPriceController.text.trim());
  }

  void _onIsFreeChanged(bool value) {
    setState(() {
      _isFree = value;
      if (value) {
        _coinPriceController.text = '0';
      }
    });
  }

  Future<void> _pickReleaseDateTime() async {
    if (_isSubmitting) {
      return;
    }

    final now = DateTime.now();
    final initialDate = _releaseAtLocal ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_releaseAtLocal ?? now),
    );

    if (!mounted || pickedTime == null) {
      return;
    }

    setState(() {
      _releaseAtLocal = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    if (!_formKey.currentState!.validate()) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      return;
    }

    final coinPrice = _parseCoinPrice();
    if (coinPrice == null) {
      setState(() {
        _errorMessage = context.l10n.validCoinPrice;
        _isSubmitting = false;
      });
      return;
    }

    try {
      final AdminEpisode result;

      if (widget.isEditing) {
        final episode = _episode!;
        result = await _repository.updateEpisode(
          UpdateEpisodeInput(
            episodeId: episode.id,
            title: _titleController.text.trim(),
            synopsis: _synopsisController.text.trim(),
            isFree: _isFree,
            coinPrice: coinPrice,
            expectedContentVersion: episode.contentVersion,
            releaseAtLocal: _releaseAtLocal,
            useContentRatingOverride: _useContentRatingOverride,
            contentAgeRating: _contentAgeRating,
            contentDescriptors: _contentDescriptors,
          ),
        );
      } else {
        final episodeNumber = _parseEpisodeNumber();
        if (episodeNumber == null) {
          setState(() {
            _errorMessage = context.l10n.validEpisodeNumber;
            _isSubmitting = false;
          });
          return;
        }

        result = await _repository.createEpisode(
          CreateEpisodeInput(
            seriesId: widget.seriesId,
            episodeNumber: episodeNumber,
            title: _titleController.text.trim(),
            synopsis: _synopsisController.text.trim(),
            isFree: _isFree,
            coinPrice: coinPrice,
            releaseAtLocal: _releaseAtLocal,
            useContentRatingOverride: _useContentRatingOverride,
            contentAgeRating: _contentAgeRating,
            contentDescriptors: _contentDescriptors,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      showContentSuccessSnackBar(
        context,
        widget.isEditing
            ? context.l10n.episodeUpdated
            : context.l10n.episodeCreated,
      );

      Navigator.of(context).pop(result);
    } on EpisodeValidationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
    } on ContentException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.isConflict && widget.isEditing) {
        await handleContentConflict<AdminEpisode>(
          context: context,
          error: error,
          reloadFresh: () => _repository.fetchById(_episode!.id),
          onFreshLoaded: (fresh) {
            setState(() {
              _episode = fresh;
              _initializeFromEpisode();
              _isSubmitting = false;
            });
          },
        );
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = context.l10n.unexpectedRetry;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final episode = _episode;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(widget.isEditing ? l10n.editEpisode : l10n.newEpisode),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _episodeNumberController,
                    enabled: !_isSubmitting && !widget.isEditing,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.episodeNumberStar,
                      helperText: widget.isEditing
                          ? l10n.episodeNumberReorderHint
                          : null,
                    ),
                    validator: (value) {
                      final number = int.tryParse(value?.trim() ?? '');
                      if (number == null || number <= 0) {
                        return l10n.episodeNumberMustBePositive;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isSubmitting,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.titleRequiredStar,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.titleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _synopsisController,
                    enabled: !_isSubmitting,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.description,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.useDifferentRatingForEpisode),
                    subtitle: Text(
                      _useContentRatingOverride
                          ? l10n.episodeSpecificRating
                          : l10n.useSeriesRating,
                    ),
                    value: _useContentRatingOverride,
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _useContentRatingOverride = value;
                              if (!value) {
                                // Override off → full series inheritance.
                                _contentAgeRating = null;
                                _contentDescriptors = null;
                              }
                            });
                          },
                  ),
                  if (_useContentRatingOverride) ...[
                    const SizedBox(height: 8),
                    ContentRatingEditor(
                      ageRating: _contentAgeRating,
                      descriptors: const [],
                      includeDescriptors: false,
                      enabled: !_isSubmitting,
                      onAgeChanged: (value) {
                        setState(() => _contentAgeRating = value);
                      },
                      onDescriptorsChanged: (_) {},
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.inheritDescriptorsFromSeries),
                      subtitle: Text(
                        _contentDescriptors == null
                            ? l10n.seriesDescriptorsUsed
                            : _contentDescriptors!.isEmpty
                            ? l10n.episodeNoDescriptors
                            : l10n.episodeSpecificDescriptors,
                      ),
                      value: _contentDescriptors == null,
                      onChanged: _isSubmitting
                          ? null
                          : (inherit) {
                              setState(() {
                                // Explicit off → start as [] (not inferred from empty).
                                _contentDescriptors = inherit
                                    ? null
                                    : <String>[];
                              });
                            },
                    ),
                    if (_contentDescriptors != null) ...[
                      const SizedBox(height: 8),
                      ContentRatingEditor(
                        ageRating: null,
                        descriptors: _contentDescriptors!,
                        includeAge: false,
                        showSectionTitle: false,
                        enabled: !_isSubmitting,
                        onAgeChanged: (_) {},
                        onDescriptorsChanged: (value) {
                          setState(() => _contentDescriptors = value);
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.freeEpisode),
                    value: _isFree,
                    onChanged: _isSubmitting ? null : _onIsFreeChanged,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _coinPriceController,
                    enabled: !_isSubmitting && !_isFree,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.coinPrice,
                      helperText: l10n.coinPriceHelper(episodeMaxCoinPrice),
                    ),
                    validator: (value) {
                      final price = int.tryParse(value?.trim() ?? '');
                      if (price == null || price < 0) {
                        return l10n.coinPriceNotNegative;
                      }

                      if (price > episodeMaxCoinPrice) {
                        return l10n.coinPriceMax(episodeMaxCoinPrice);
                      }

                      if (_isFree && price != 0) {
                        return l10n.freeEpisodeCoinMustBeZero;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.releaseDate,
                          ),
                          child: Text(
                            _releaseAtLocal == null
                                ? l10n.notSelected
                                : formatEpisodeDateTime(
                                    _releaseAtLocal!.toUtc(),
                                  ),
                            style: TextStyle(
                              color: _releaseAtLocal == null
                                  ? const Color(0xFF777777)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : _pickReleaseDateTime,
                        child: Text(l10n.releaseDate),
                      ),
                      if (_releaseAtLocal != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: l10n.clearDate,
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _releaseAtLocal = null;
                                  });
                                },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ],
                  ),
                  if (widget.isEditing && episode != null) ...[
                    const SizedBox(height: 24),
                    _ReadOnlyInfo(
                      label: l10n.publishStatus,
                      value: adminPublishDisplayLabel(
                        l10n,
                        episode.publishLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ReadOnlyInfo(
                      label: l10n.video,
                      value: adminVideoStatusLabel(
                        l10n,
                        episode.videoStatusLabel,
                      ),
                    ),
                    if (episode.hasPendingReplacement) ...[
                      const SizedBox(height: 8),
                      _ReadOnlyInfo(
                        label: l10n.pendingVideo,
                        value: adminVideoStatusLabel(
                          l10n,
                          episode.pendingVideoStatusLabel,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ReadOnlyInfo(
                      label: l10n.qualifiedViews,
                      value: episode.qualifiedViewsTotal.toString(),
                    ),
                    const SizedBox(height: 8),
                    _ReadOnlyInfo(
                      label: l10n.legacyCounterSeed,
                      value: episode.totalViews.toString(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.dismiss),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryColor,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.isEditing ? l10n.update : l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE50914).withValues(alpha: 0.4),
        ),
      ),
      child: SelectableText(
        message,
        style: const TextStyle(color: Color(0xFFFFB4B4)),
      ),
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFFB3B3B3))),
        Text(value),
      ],
    );
  }
}
