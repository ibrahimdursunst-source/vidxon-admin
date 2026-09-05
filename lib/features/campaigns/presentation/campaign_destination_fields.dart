import 'package:flutter/material.dart';

import '../../episodes/domain/admin_episode.dart';
import '../application/campaign_destination_controller.dart';
import '../domain/campaign_destination.dart';

class CampaignDestinationFields extends StatelessWidget {
  const CampaignDestinationFields({
    super.key,
    required this.controller,
    required this.destinationType,
    required this.onDestinationTypeChanged,
  });

  final CampaignDestinationController controller;
  final String destinationType;
  final ValueChanged<String> onDestinationTypeChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('campaign-destination-type'),
              initialValue: destinationType,
              decoration: const InputDecoration(labelText: 'Hedef Türü'),
              items: [
                for (final option in kCampaignDestinationOptions)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(option.label),
                  ),
              ],
              onChanged: (value) =>
                  onDestinationTypeChanged(value ?? CampaignDestinationType.none),
            ),
            const SizedBox(height: 12),
            if (controller.showSeriesPicker) _SeriesPicker(controller: controller),
            if (controller.showEpisodePicker) ...[
              const SizedBox(height: 12),
              _EpisodePicker(controller: controller),
            ],
            FormField<String>(
              validator: (_) => controller.validate(),
              builder: (state) {
                if (state.errorText == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SeriesPicker extends StatelessWidget {
  const _SeriesPicker({required this.controller});

  final CampaignDestinationController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedSeries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('campaign-series-picker'),
      children: [
        const Text(
          'Dizi',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (controller.seriesUnavailable)
          const _UnavailableBanner(
            key: Key('campaign-series-unavailable'),
            message:
                'Kayıtlı dizi artık kullanılamıyor. Mevcut hedef korunur; yeni bir dizi seçmezseniz önceki hedef değişmez.',
          ),
        if (selected != null) ...[
          _SelectedEntityCard(
            title: selected.title,
            subtitle: selected.publishLabel,
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          key: const Key('campaign-series-search'),
          decoration: const InputDecoration(
            labelText: 'Dizi ara',
            hintText: 'Başlık veya slug',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
          onChanged: controller.setSeriesQuery,
        ),
        const SizedBox(height: 8),
        if (controller.loadingSeries)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.loadError != null && controller.series.isEmpty)
          Text(
            controller.loadError!,
            style: const TextStyle(color: Colors.orangeAccent),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Material(
              color: Colors.white.withValues(alpha: 0.03),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (controller.filteredSeries.isEmpty)
                    const ListTile(
                      dense: true,
                      title: Text('Eşleşen dizi yok'),
                    )
                  else
                    for (final series in controller.filteredSeries)
                      ListTile(
                        key: Key('campaign-series-option-${series.id}'),
                        dense: true,
                        selected: series.id == controller.selectedSeriesId,
                        title: Text(series.title),
                        subtitle: Text(series.publishLabel),
                        onTap: () => controller.selectSeries(series),
                      ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EpisodePicker extends StatelessWidget {
  const _EpisodePicker({required this.controller});

  final CampaignDestinationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('campaign-episode-picker'),
      children: [
        if (controller.episodeUnavailable)
          const _UnavailableBanner(
            key: Key('campaign-episode-unavailable'),
            message:
                'Kayıtlı bölüm artık kullanılamıyor. Mevcut hedef korunur; yeni bir bölüm seçmezseniz önceki hedef değişmez.',
          ),
        if (controller.selectedSeriesId == null &&
            controller.selectedEpisode == null &&
            !controller.episodeUnavailable)
          const Text(
            'Önce bir dizi seçin, ardından bölümü seçin.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          )
        else if (controller.loadingEpisodes)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey(
              'campaign-episode-dropdown-${controller.selectedEpisodeId}-${controller.episodes.length}',
            ),
            initialValue: controller.selectedEpisodeId,
            decoration: const InputDecoration(labelText: 'Bölüm'),
            hint: const Text('Bölüm seçin'),
            items: [
              for (final episode in controller.episodes)
                DropdownMenuItem(
                  value: episode.id,
                  child: Text(_episodeLabel(episode)),
                ),
            ],
            onChanged: (id) {
              if (id == null) return;
              final episode = controller.episodes
                  .where((item) => item.id == id)
                  .firstOrNull;
              if (episode != null) controller.selectEpisode(episode);
            },
          ),
      ],
    );
  }

  String _episodeLabel(AdminEpisode episode) {
    return campaignEpisodePickerLabel(
      episodeNumber: episode.episodeNumber,
      title: episode.title,
    );
  }
}

class _SelectedEntityCard extends StatelessWidget {
  const _SelectedEntityCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(message, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
