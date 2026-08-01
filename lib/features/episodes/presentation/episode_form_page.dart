import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../content/data/content_errors.dart';
import '../../content/presentation/content_conflict_helper.dart';
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
        _errorMessage = 'Geçerli bir coin fiyatı girin.';
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
          ),
        );
      } else {
        final episodeNumber = _parseEpisodeNumber();
        if (episodeNumber == null) {
          setState(() {
            _errorMessage = 'Geçerli bir bölüm numarası girin.';
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
          ),
        );
      }

      if (!mounted) {
        return;
      }

      showContentSuccessSnackBar(
        context,
        widget.isEditing
            ? 'Bölüm başarıyla güncellendi.'
            : 'Bölüm başarıyla oluşturuldu.',
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
        _errorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final episode = _episode;

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(widget.isEditing ? 'Bölümü Düzenle' : 'Yeni Bölüm'),
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
                      labelText: 'Bölüm Numarası *',
                      helperText: widget.isEditing
                          ? 'Bölüm numarası sıralama ekranından değiştirilir.'
                          : null,
                    ),
                    validator: (value) {
                      final number = int.tryParse(value?.trim() ?? '');
                      if (number == null || number <= 0) {
                        return 'Bölüm numarası 0\'dan büyük olmalıdır.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isSubmitting,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Başlık *'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Başlık zorunludur.';
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
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ücretsiz Bölüm'),
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
                      labelText: 'Coin Fiyatı',
                      helperText: 'En fazla $episodeMaxCoinPrice jeton',
                    ),
                    validator: (value) {
                      final price = int.tryParse(value?.trim() ?? '');
                      if (price == null || price < 0) {
                        return 'Coin fiyatı negatif olamaz.';
                      }

                      if (price > episodeMaxCoinPrice) {
                        return 'Coin fiyatı en fazla $episodeMaxCoinPrice olabilir.';
                      }

                      if (_isFree && price != 0) {
                        return 'Ücretsiz bölümlerde coin fiyatı 0 olmalıdır.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Yayın Tarihi',
                          ),
                          child: Text(
                            _releaseAtLocal == null
                                ? 'Seçilmedi'
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
                        child: const Text('Yayın Tarihi'),
                      ),
                      if (_releaseAtLocal != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Tarihi Temizle',
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
                      label: 'Yayın Durumu',
                      value: episode.publishLabel,
                    ),
                    const SizedBox(height: 8),
                    _ReadOnlyInfo(
                      label: 'Video',
                      value: episode.videoStatusLabel,
                    ),
                    if (episode.hasPendingReplacement) ...[
                      const SizedBox(height: 8),
                      _ReadOnlyInfo(
                        label: 'Bekleyen Video',
                        value: episode.pendingVideoStatusLabel,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ReadOnlyInfo(
                      label: 'Toplam İzlenme',
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
                        child: const Text('Vazgeç'),
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
                            : Text(widget.isEditing ? 'Güncelle' : 'Kaydet'),
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
