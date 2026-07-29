import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/episode_video_upload_errors.dart';
import '../data/episode_video_upload_repository.dart';
import '../domain/admin_episode.dart';
import '../domain/episode_video_file.dart';

enum _UploadStage {
  noFileSelected('Video seçilmedi'),
  preparingTicket('Yükleme bağlantısı hazırlanıyor'),
  uploadingVideo('Video Cloudflare\'a yükleniyor'),
  attachingVideo('Video bölüme bağlanıyor'),
  completed('Yükleme tamamlandı'),
  failed('Yükleme başarısız');

  const _UploadStage(this.label);

  final String label;
}

String formatEpisodeVideoFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class EpisodeVideoUploadPage extends StatefulWidget {
  const EpisodeVideoUploadPage({
    required this.episode,
    required this.seriesTitle,
    this.repository,
    super.key,
  });

  final AdminEpisode episode;
  final String seriesTitle;
  final EpisodeVideoUploadRepository? repository;

  @override
  State<EpisodeVideoUploadPage> createState() => _EpisodeVideoUploadPageState();
}

class _EpisodeVideoUploadPageState extends State<EpisodeVideoUploadPage> {
  static const _primaryColor = Color(0xFFE50914);

  late final EpisodeVideoUploadRepository _repository =
      widget.repository ?? EpisodeVideoUploadRepository();

  EpisodeVideoFile? _selectedFile;
  bool _isUploading = false;
  bool _canRetryAttach = false;
  String? _pendingStreamUid;
  String? _errorMessage;
  double _progress = 0;
  _UploadStage _stage = _UploadStage.noFileSelected;

  bool get _uploadInProgress => _isUploading;

  Future<void> _pickVideo() async {
    if (_isUploading) {
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [EpisodeVideoFile.allowedExtension],
      withData: false,
      withReadStream: true,
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;

    try {
      final file = EpisodeVideoFileValidator.validate(
        name: picked.name,
        size: picked.size,
        contentType: EpisodeVideoFile.allowedContentType,
        readStream: picked.readStream,
      );

      setState(() {
        _selectedFile = file;
        _errorMessage = null;
        _canRetryAttach = false;
        _pendingStreamUid = null;
        _stage = _UploadStage.noFileSelected;
      });
    } on EpisodeVideoFileValidationException catch (error) {
      setState(() {
        _errorMessage = error.message;
        _canRetryAttach = false;
        _pendingStreamUid = null;
      });
    }
  }

  Future<void> _startUpload() async {
    final file = _selectedFile;
    if (file == null || _isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0;
      _errorMessage = null;
      _canRetryAttach = false;
      _pendingStreamUid = null;
      _stage = _UploadStage.preparingTicket;
    });

    try {
      final ticket = await _repository.createUploadTicket(
        episodeId: widget.episode.id,
        file: file,
      );

      if (!mounted) {
        return;
      }

      setState(() => _stage = _UploadStage.uploadingVideo);

      await _repository.uploadVideo(
        ticket: ticket,
        file: file,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }

          setState(() => _progress = progress);
        },
      );

      if (!mounted) {
        return;
      }

      setState(() => _stage = _UploadStage.attachingVideo);

      final updatedEpisode = await _repository.attachVideo(
        episodeId: widget.episode.id,
        streamUid: ticket.uid,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stage = _UploadStage.completed;
        _progress = 1;
      });

      Navigator.of(context).pop(updatedEpisode);
    } on EpisodeVideoUploadException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
        _stage = _UploadStage.failed;
        _errorMessage = error.message;
        _canRetryAttach = error.canRetryAttach;
        _pendingStreamUid = error.pendingStreamUid;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
        _stage = _UploadStage.failed;
        _errorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
        _canRetryAttach = false;
        _pendingStreamUid = null;
      });
    }
  }

  Future<void> _retryAttach() async {
    final streamUid = _pendingStreamUid;
    if (streamUid == null || _isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _stage = _UploadStage.attachingVideo;
    });

    try {
      final updatedEpisode = await _repository.attachVideo(
        episodeId: widget.episode.id,
        streamUid: streamUid,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updatedEpisode);
    } on EpisodeVideoUploadException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
        _stage = _UploadStage.failed;
        _errorMessage = error.message;
        _canRetryAttach = error.canRetryAttach;
        _pendingStreamUid = error.pendingStreamUid ?? streamUid;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
        _stage = _UploadStage.failed;
        _errorMessage =
            'Video yüklendi fakat bölüme bağlanamadı. Videoyu yeniden yüklemeyin; bağlama işlemini tekrar deneyin.';
        _canRetryAttach = true;
        _pendingStreamUid = streamUid;
      });
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_uploadInProgress) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('Yükleme devam ediyor'),
          content: const Text(
            'Video yüklemesi sürerken sayfadan ayrılırsanız işlem yarıda kalabilir. '
            'Yine de çıkmak istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Kal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _primaryColor),
              child: const Text('Çık'),
            ),
          ],
        );
      },
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final selectedFile = _selectedFile;
    final canUpload = selectedFile != null && !_isUploading && !_canRetryAttach;

    return PopScope(
      canPop: !_uploadInProgress,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_uploadInProgress) {
          return;
        }

        final shouldLeave = await _confirmLeave();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090909),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111111),
          title: const Text('Video Yükle'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoCard(
                    seriesTitle: widget.seriesTitle,
                    episodeNumber: episode.episodeNumber,
                    episodeTitle: episode.title,
                    currentStatus: episode.videoStatusLabel,
                  ),
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Video Dosyası',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickVideo,
                            icon: const Icon(Icons.video_file_outlined),
                            label: const Text('MP4 Seç'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF333333)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (selectedFile != null) ...[
                            Text(
                              selectedFile.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatEpisodeVideoFileSize(selectedFile.size),
                              style: const TextStyle(color: Color(0xFFB3B3B3)),
                            ),
                          ] else
                            const Text(
                              'Henüz video seçilmedi.',
                              style: TextStyle(color: Color(0xFFB3B3B3)),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Maksimum dosya boyutu: 200 MB',
                            style: TextStyle(color: Color(0xFFB3B3B3)),
                          ),
                          const Text(
                            'Desteklenen format: MP4 (video/mp4)',
                            style: TextStyle(color: Color(0xFFB3B3B3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isUploading || _stage == _UploadStage.failed) ...[
                    Text(
                      _stage.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_stage == _UploadStage.uploadingVideo ||
                        _stage == _UploadStage.completed) ...[
                      LinearProgressIndicator(
                        value: _progress.clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: const Color(0xFF2A2A2A),
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).clamp(0, 100).round()}%',
                        style: const TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    ],
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1111),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5A2222)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFB4B4)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_canRetryAttach)
                    FilledButton(
                      onPressed: _isUploading ? null : _retryAttach,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Bağlamayı Tekrar Dene'),
                    )
                  else
                    FilledButton(
                      onPressed: canUpload ? _startUpload : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Video Yükle'),
                    ),
                  if (_stage == _UploadStage.completed)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Video Cloudflare Stream tarafından işlenmeye devam edecek. '
                        'İşlem tamamlandığında bölüm listesinde durum güncellenecektir.',
                        style: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.seriesTitle,
    required this.episodeNumber,
    required this.episodeTitle,
    required this.currentStatus,
  });

  final String seriesTitle;
  final int episodeNumber;
  final String episodeTitle;
  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seriesTitle,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Bölüm $episodeNumber · $episodeTitle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Mevcut video durumu: $currentStatus',
              style: const TextStyle(color: Color(0xFFB3B3B3)),
            ),
          ],
        ),
      ),
    );
  }
}
