import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/episodes/data/episode_media_tracks_errors.dart';
import 'package:vidxon_admin/features/episodes/data/episode_media_tracks_repository.dart';
import 'package:vidxon_admin/features/episodes/domain/duration_warning.dart';
import 'package:vidxon_admin/features/episodes/domain/episode_media_tracks.dart';

void main() {
  group('runAudioUploadOrchestration', () {
    test('blocks severe mismatch without override before upload', () async {
      final calls = <String>[];

      await expectLater(
        runAudioUploadOrchestration(
          classify: () => const DurationWarningResult(
            level: DurationWarningLevel.severe,
            deltaMs: 5000,
            relative: 0.1,
          ),
          ensureOverrideAllowed: (level) {
            calls.add('check');
            if (level.requiresExplicitOverride) {
              throw EpisodeMediaTracksException(
                message: 'override required',
                kind: EpisodeMediaTracksFailureKind.severeOverrideRequired,
              );
            }
          },
          upload: (_) async {
            calls.add('upload');
            return {'ok': true};
          },
        ),
        throwsA(isA<EpisodeMediaTracksException>()),
      );

      expect(calls, ['check']);
    });

    test('uploads after override check passes', () async {
      final calls = <String>[];

      final result = await runAudioUploadOrchestration(
        classify: () => const DurationWarningResult(
          level: DurationWarningLevel.notice,
          deltaMs: 800,
          relative: 0.008,
        ),
        ensureOverrideAllowed: (level) {
          calls.add('check:${level.name}');
        },
        upload: (classified) async {
          calls.add('upload:${classified?.level.name}');
          return {'ok': true, 'action': 'upload'};
        },
      );

      expect(result['ok'], isTrue);
      expect(calls, ['check:notice', 'upload:notice']);
    });
  });

  group('EpisodeMediaTracksSnapshot', () {
    test('parses list RPC payload without provider secrets', () {
      final snapshot = EpisodeMediaTracksSnapshot.fromMap({
        'originalAudioLocale': 'tr',
        'audioTracks': [
          {
            'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            'episode_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            'locale': 'en',
            'lifecycle': 'active',
            'status': 'ready',
            'duration_warning_level': 'warning',
            'duration_ms': 120000,
            'duration_delta_ms': 1500,
          },
        ],
        'subtitleTracks': [
          {
            'id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
            'episode_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            'locale': 'es',
            'lifecycle': 'active',
            'status': 'ready',
          },
        ],
      });

      expect(snapshot.originalAudioLocale, 'tr');
      expect(snapshot.audioTracks.single.locale, 'en');
      expect(snapshot.audioTracks.single.statusLabel, 'Hazır');
      expect(
        snapshot.audioTracks.single.durationWarningLevel,
        DurationWarningLevel.warning,
      );
      expect(snapshot.subtitleTracks.single.locale, 'es');
      expect(snapshot.subtitleTracks.single.statusLabel, 'Hazır');
    });

    test('maps processing and failed labels', () {
      final processing = EpisodeAudioTrack.fromMap({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'episode_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'locale': 'en',
        'lifecycle': 'pending',
        'status': 'processing',
        'duration_warning_level': 'none',
      });
      final failed = EpisodeAudioTrack.fromMap({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'episode_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'locale': 'en',
        'lifecycle': 'failed',
        'status': 'error',
        'duration_warning_level': 'none',
      });

      expect(processing.statusLabel, 'İşleniyor');
      expect(failed.statusLabel, 'Başarısız');
    });
  });
}
