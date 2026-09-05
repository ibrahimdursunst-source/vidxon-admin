import 'package:flutter/material.dart';

import '../../../l10n/admin_l10n.dart';
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
              decoration: InputDecoration(
                labelText: context.l10n.destinationType,
              ),
              items: [
                for (final option in kCampaignDestinationOptions)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(
                      adminDestinationTypeLabel(context.l10n, option.value),
                    ),
                  ),
              ],
              onChanged: (value) => onDestinationTypeChanged(
                value ?? CampaignDestinationType.none,
              ),
            ),
            const SizedBox(height: 12),
            if (controller.showSeriesPicker)
              _SeriesPicker(controller: controller),
            if (controller.showEpisodePicker) ...[
              const SizedBox(height: 12),
              _EpisodePicker(controller: controller),
            ],
            FormField<String>(
              validator: (_) {
                final raw = controller.validate();
                if (raw == 'Dizi seçin') return context.l10n.selectSeries;
                if (raw == 'Bölüm seçin') return context.l10n.selectEpisode;
                return raw;
              },
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
        Text(
          context.l10n.destinationSeries,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (controller.seriesUnavailable)
          _UnavailableBanner(
            key: const Key('campaign-series-unavailable'),
            message: context.l10n.seriesUnavailableBanner,
          ),
        if (selected != null && !controller.seriesPickerOpen)
          _SelectedEntityCard(
            key: const Key('campaign-series-selected'),
            title: selected.title,
            subtitle: adminPublishedLabel(context.l10n, selected.isPublished),
            actionLabel: context.l10n.changeSeries,
            actionKey: const Key('campaign-series-change'),
            onChange: controller.beginChangeSeries,
          ),
        if (controller.isSeriesCatalogVisible) ...[
          if (selected != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('campaign-series-cancel-change'),
                onPressed: controller.cancelChangeSeries,
                child: Text(context.l10n.dismiss),
              ),
            ),
          ],
          TextField(
            key: const Key('campaign-series-search'),
            decoration: InputDecoration(
              labelText: context.l10n.searchSeries,
              hintText: context.l10n.titleOrSlug,
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
            onChanged: controller.setSeriesQuery,
          ),
          const SizedBox(height: 8),
          if (controller.loadingSeries)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.seriesLoadError != null &&
              controller.series.isEmpty)
            Text(
              controller.seriesLoadError ==
                      'Diziler yüklenemedi. Lütfen tekrar deneyin.'
                  ? context.l10n.seriesCatalogLoadFailed
                  : controller.seriesLoadError!,
              style: const TextStyle(color: Colors.orangeAccent),
            )
          else
            ConstrainedBox(
              key: const Key('campaign-series-results'),
              constraints: const BoxConstraints(maxHeight: 220),
              child: Material(
                color: Colors.white.withValues(alpha: 0.03),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (controller.filteredSeries.isEmpty)
                      ListTile(
                        dense: true,
                        title: Text(context.l10n.noMatchingSeries),
                      )
                    else
                      for (final series in controller.filteredSeries)
                        ListTile(
                          key: Key('campaign-series-option-${series.id}'),
                          dense: true,
                          selected: series.id == controller.selectedSeriesId,
                          title: Text(series.title),
                          subtitle: Text(
                            adminPublishedLabel(
                              context.l10n,
                              series.isPublished,
                            ),
                          ),
                          onTap: () => controller.selectSeries(series),
                        ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EpisodePicker extends StatelessWidget {
  const _EpisodePicker({required this.controller});

  final CampaignDestinationController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedEpisode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('campaign-episode-picker'),
      children: [
        Text(
          context.l10n.destinationEpisode,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (controller.episodeUnavailable)
          _UnavailableBanner(
            key: const Key('campaign-episode-unavailable'),
            message: context.l10n.episodeUnavailableBanner,
          ),
        if (controller.selectedSeriesId == null)
          Text(
            key: const Key('campaign-episode-need-series'),
            context.l10n.selectSeriesFirst,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          )
        else if (controller.loadingEpisodes)
          Padding(
            key: const Key('campaign-episode-loading'),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(context.l10n.episodesLoading),
              ],
            ),
          )
        else if (controller.episodeLoadError != null)
          Column(
            key: const Key('campaign-episode-error'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.episodeLoadError == 'Bölümler yüklenemedi.'
                    ? context.l10n.episodesLoadFailed
                    : controller.episodeLoadError!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
              TextButton(
                key: const Key('campaign-episode-retry'),
                onPressed: controller.reloadEpisodes,
                child: Text(context.l10n.retry),
              ),
            ],
          )
        else if (controller.episodes.isEmpty)
          Text(
            key: const Key('campaign-episode-empty'),
            context.l10n.episodesEmptyForSeries,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          )
        else if (selected != null && !controller.episodePickerOpen)
          _SelectedEntityCard(
            key: const Key('campaign-episode-selected'),
            title: _episodeLabel(context, selected),
            subtitle: adminPublishedLabel(context.l10n, selected.isPublished),
            actionLabel: context.l10n.changeEpisode,
            actionKey: const Key('campaign-episode-change'),
            onChange: controller.beginChangeEpisode,
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey(
              'campaign-episode-dropdown-${controller.selectedSeriesId}-${controller.episodes.length}',
            ),
            initialValue: controller.selectedEpisodeId,
            decoration: InputDecoration(
              labelText: context.l10n.destinationEpisode,
            ),
            hint: Text(context.l10n.selectEpisode),
            items: [
              for (final episode in controller.episodes)
                DropdownMenuItem(
                  value: episode.id,
                  child: Text(_episodeLabel(context, episode)),
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

  String _episodeLabel(BuildContext context, AdminEpisode episode) {
    final trimmed = episode.title.trim();
    if (trimmed.isEmpty) {
      return context.l10n.episodePickerNumberOnly(episode.episodeNumber);
    }
    return context.l10n.episodePickerLabel(episode.episodeNumber, trimmed);
  }
}

class _SelectedEntityCard extends StatelessWidget {
  const _SelectedEntityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionKey,
    required this.onChange,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            key: actionKey,
            onPressed: onChange,
            child: Text(actionLabel),
          ),
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
