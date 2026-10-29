import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/domain/models/models.dart';

/// Edits the owner-editable fields of an existing listing. Keeps its own state
/// so it never disturbs an in-progress draft in `postFormProvider`.
class EditListingSheet extends ConsumerStatefulWidget {
  const EditListingSheet({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<EditListingSheet> createState() => _EditListingSheetState();
}

class _EditListingSheetState extends ConsumerState<EditListingSheet> {
  static const _durations = ['1-3 days', '1 week', '2 weeks', '1 month'];

  late final _title = TextEditingController(text: widget.listing.title);
  late final _price = TextEditingController(
    text: widget.listing.price.toStringAsFixed(
      widget.listing.price.truncateToDouble() == widget.listing.price ? 0 : 2,
    ),
  );
  late final _description = TextEditingController(
    text: widget.listing.description,
  );
  late final _location = TextEditingController(text: widget.listing.location);
  late String? _duration = widget.listing.duration;
  late bool _remoteOnly = widget.listing.remoteOnly;
  late ListingStatus _status = widget.listing.status;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  double? get _parsedPrice => double.tryParse(_price.text.replaceAll(',', ''));

  bool get _canSave =>
      !_busy &&
      _title.text.trim().isNotEmpty &&
      _location.text.trim().isNotEmpty &&
      _parsedPrice != null;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(listingRepositoryProvider)
          .updateListing(
            widget.listing.copyWith(
              title: _title.text.trim(),
              price: _parsedPrice,
              description: _description.text.trim(),
              location: _location.text.trim(),
              duration: _duration,
              clearDuration: _duration == null,
              remoteOnly: _remoteOnly,
              status: _status,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save changes. $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGig = widget.listing.type == ListingType.gig;
    final durations = {..._durations, ?_duration}.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isGig ? 'Edit gig' : 'Edit item',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              maxLength: 12,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price / Budget',
                prefixText: '₱ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _location,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location',
                helperText: 'Barangay, city or landmark',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLength: 2000,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (isGig) ...[
              const SizedBox(height: 8),
              Text('Duration / Timeline', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in durations)
                    GiglChoiceChip(
                      label: d,
                      selected: _duration == d,
                      onSelected: (_) => setState(() => _duration = d),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remote-Only'),
                value: _remoteOnly,
                onChanged: (v) => setState(() => _remoteOnly = v),
              ),
            ],
            const SizedBox(height: 16),
            Text('Status', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ListingStatus>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ListingStatus.active,
                  label: Text('Active'),
                ),
                ButtonSegment(
                  value: ListingStatus.paused,
                  label: Text('Paused'),
                ),
                ButtonSegment(
                  value: ListingStatus.completed,
                  label: Text('Completed'),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              'Only active listings appear in other people\'s feeds.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
