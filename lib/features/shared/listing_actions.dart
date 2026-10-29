import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/post/edit_listing_sheet.dart';

String reportReasonLabel(ReportReason reason) {
  return switch (reason) {
    ReportReason.spam => 'Spam or misleading',
    ReportReason.scam => 'Scam or fraud',
    ReportReason.prohibited => 'Prohibited item or service',
    ReportReason.inappropriate => 'Inappropriate content',
    ReportReason.other => 'Something else',
  };
}

enum _Action { edit, delete, report }

/// Overflow menu for a listing: Edit/Delete on the signed-in user's own
/// listings, Report on everyone else's.
class ListingMenuButton extends ConsumerWidget {
  const ListingMenuButton({super.key, required this.listing, this.color});

  final Listing listing;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwn = listing.ownerId == ref.watch(currentUserIdProvider);
    return PopupMenuButton<_Action>(
      tooltip: 'Listing options',
      icon: Icon(Icons.more_vert, color: color),
      onSelected: (action) => switch (action) {
        _Action.edit => _edit(context),
        _Action.delete => _delete(context, ref),
        _Action.report => _report(context),
      },
      itemBuilder: (_) => isOwn
          ? const [
              PopupMenuItem(
                value: _Action.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: _Action.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                ),
              ),
            ]
          : const [
              PopupMenuItem(
                value: _Action.report,
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Report'),
                ),
              ),
            ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => EditListingSheet(listing: listing),
    );
    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Listing updated')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(listingRepositoryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text(
          '"${listing.title}" will be removed for everyone. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await repo.deleteListing(listing.id);
      messenger.showSnackBar(const SnackBar(content: Text('Listing deleted')));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete listing: $e')),
      );
    }
  }

  Future<void> _report(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final filed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (_, ref, _) => ReportSheet(
          title: 'Report listing',
          subtitle: listing.title,
          onSubmit: (reason, details) => ref
              .read(listingRepositoryProvider)
              .reportListing(listing, reason, details: details),
        ),
      ),
    );
    if (filed == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          filed
              ? 'Thanks — we will review this listing. '
                    'You will no longer see it.'
              : 'You already reported this listing.',
        ),
      ),
    );
  }
}

/// Bottom sheet that picks a [ReportReason] plus optional details and calls
/// [onSubmit]. Pops with its result: true when filed, false when the target
/// was already reported. Shared by listing and user reports.
class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final Future<bool> Function(ReportReason reason, String details) onSubmit;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final filed = await widget.onSubmit(_reason!, _details.text);
      if (mounted) Navigator.of(context).pop(filed);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not send report. $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final reason in ReportReason.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                selected: _reason == reason,
                leading: Icon(
                  _reason == reason
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(reportReasonLabel(reason)),
                onTap: _busy ? null : () => setState(() => _reason = reason),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _reason == null || _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
