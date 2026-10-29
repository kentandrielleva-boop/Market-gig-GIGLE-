import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/theme/app_colors.dart';
import 'package:marketplace_gig/data/repositories/repositories.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/shared/listing_actions.dart';
import 'package:marketplace_gig/features/shared/shared_widgets.dart';

/// Reviews about a user as a scrolling page/tab body (profile tab, public
/// profile, Ratings screen). Others may review them after a chat; on your
/// own profile it is read-only apart from replying.
class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) =>
      ReviewsSection(target: (kind: ReviewKind.user, id: uid));
}

/// Everything about the reviews of one user or listing: the write/edit
/// button (gated on having chatted, see [ProfileRepository.addReview]),
/// average + per-star distribution (tap a bar to filter), sort, the
/// viewer's own review pinned first, and a paged list with "Load more".
class ReviewsSection extends ConsumerStatefulWidget {
  const ReviewsSection({
    super.key,
    required this.target,
    this.listing,
    this.embedded = false,
  });

  final ReviewTarget target;

  /// The reviewed listing (required for listing targets: owner + title).
  final Listing? listing;

  /// Inside another scroll view (listing detail): lays out as a headed
  /// Column instead of its own ListView.
  final bool embedded;

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  int? _stars;
  ReviewSort _sort = ReviewSort.recent;
  int _limit = reviewPageSize;

  /// Last page shown, kept while a new filter/limit loads (no flicker).
  List<Review>? _lastPage;

  ReviewTarget get _target => widget.target;
  bool get _isUserTarget => _target.kind == ReviewKind.user;

  String get _ownerId => _isUserTarget ? _target.id : widget.listing!.ownerId;

  void _setFilter({int? stars, ReviewSort? sort}) {
    setState(() {
      _stars = stars;
      _sort = sort ?? _sort;
      _limit = reviewPageSize;
    });
  }

  void _openSheet(Review? mine, List<ReviewContext> contexts) {
    final repo = ref.read(profileRepositoryProvider);
    final listing = widget.listing;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _isUserTarget
          ? ReviewSheet(
              title: 'Rate this user',
              initial: mine,
              contexts: contexts,
              onSubmit: (rating, comment, chat) => repo.addReview(
                revieweeId: _target.id,
                context: chat!,
                rating: rating,
                comment: comment,
              ),
              onDelete: () => repo.deleteReview(_target.id),
            )
          : ReviewSheet(
              title: listing!.isGig ? 'Rate this gig' : 'Rate this item',
              initial: mine,
              onSubmit: (rating, comment, _) => repo.addListingReview(
                listing: listing,
                rating: rating,
                comment: comment,
              ),
              onDelete: () => repo.deleteListingReview(listing.id),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final isOwner = me == _ownerId;
    final query = (stars: _stars, sort: _sort, limit: _limit);

    final mineAsync = ref.watch(myReviewProvider(_target));
    final mine = mineAsync.value;
    final distribution = ref.watch(reviewDistributionProvider(_target)).value;
    final pageAsync = ref.watch(reviewPageProvider((_target, query)));
    if (pageAsync.hasValue) _lastPage = pageAsync.value;
    final page = pageAsync.value ?? _lastPage;

    // Verified reviews: a user can be rated after a chat with them, a
    // listing after messaging its owner about it. Editing your own review
    // is always offered (deleting needs no chat).
    var contexts = const <ReviewContext>[];
    var hasChat = false;
    var gateKnown = false;
    if (!isOwner) {
      if (_isUserTarget) {
        final async = ref.watch(reviewContextsProvider(_target.id));
        contexts = async.value ?? const [];
        hasChat = contexts.isNotEmpty;
        gateKnown = async.hasValue;
      } else {
        final async = ref.watch(canReviewListingProvider(_target.id));
        hasChat = async.value ?? false;
        gateKnown = async.hasValue;
      }
    }
    final canWrite = !isOwner && (mine != null || hasChat);
    // Wait for the own-review lookup so a returning reviewer can't start a
    // "new" review before their existing one is known.
    final ready = mineAsync.hasValue && (mine != null || gateKnown);
    final writeLabel = mine != null
        ? 'Edit your review'
        : _isUserTarget
        ? 'Leave a review'
        : 'Write a review';
    final writeButton = isOwner
        ? null
        : widget.embedded
        ? TextButton.icon(
            onPressed: canWrite && ready
                ? () => _openSheet(mine, contexts)
                : null,
            icon: Icon(
              mine == null ? Icons.rate_review_outlined : Icons.edit_outlined,
              size: 18,
            ),
            label: Text(writeLabel),
          )
        : OutlinedButton.icon(
            onPressed: canWrite && ready
                ? () => _openSheet(mine, contexts)
                : null,
            icon: Icon(mine == null ? Icons.star_outline : Icons.edit_outlined),
            label: Text(writeLabel),
          );
    final gateHint = isOwner || canWrite || !gateKnown
        ? null
        : _isUserTarget
        ? 'Chat with them first to leave a review.'
        : 'Message the seller to leave a review.';

    final total = distribution?.fold<int>(0, (sum, c) => sum + c) ?? 0;
    final children = <Widget>[
      if (widget.embedded)
        Row(
          children: [
            Expanded(
              child: Text('Reviews', style: theme.textTheme.titleMedium),
            ),
            ?writeButton,
          ],
        )
      else if (writeButton != null)
        Align(alignment: Alignment.centerRight, child: writeButton),
      if (gateHint != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            gateHint,
            textAlign: widget.embedded ? TextAlign.start : TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      const SizedBox(height: 8),
    ];

    if (distribution == null) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      return _wrap(children);
    }

    if (total == 0 && mine == null) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: widget.embedded ? 0 : 40),
          child: Text(
            !widget.embedded
                ? 'No reviews yet'
                : canWrite
                ? 'No reviews yet — be the first.'
                : 'No reviews yet.',
            textAlign: widget.embedded ? TextAlign.start : TextAlign.center,
            style: widget.embedded
                ? theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
      );
      return _wrap(children);
    }

    // Profiles show the average in their header already.
    if (widget.embedded) {
      children
        ..add(_RatingSummary(distribution: distribution))
        ..add(const SizedBox(height: 12));
    } else {
      children.add(
        Text('Rating distribution', style: theme.textTheme.titleMedium),
      );
    }
    children
      ..add(
        _DistributionBars(
          distribution: distribution,
          selected: _stars,
          onTap: (stars) => _setFilter(stars: _stars == stars ? null : stars),
        ),
      )
      ..add(const SizedBox(height: 8))
      ..add(
        Row(
          children: [
            if (_stars != null)
              InputChip(
                label: Text('Showing $_stars★'),
                onDeleted: () => _setFilter(),
                deleteButtonTooltipMessage: 'Clear filter',
              ),
            const Spacer(),
            if (_stars == null)
              PopupMenuButton<ReviewSort>(
                tooltip: 'Sort reviews',
                initialValue: _sort,
                onSelected: (sort) => _setFilter(sort: sort),
                itemBuilder: (_) => [
                  for (final sort in ReviewSort.values)
                    PopupMenuItem(value: sort, child: Text(_sortLabel(sort))),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 18),
                      const SizedBox(width: 4),
                      Text(_sortLabel(_sort)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      )
      ..add(const SizedBox(height: 8));

    // Own review pinned first (it may sit on any page), then the page minus
    // it so it isn't listed twice.
    final showMine = mine != null && (_stars == null || mine.rating == _stars);
    if (showMine) {
      children.add(
        ReviewCard(review: mine, isMine: true, showListing: _isUserTarget),
      );
    }
    if (page == null) {
      if (pageAsync.hasError) {
        children.add(asyncErrorWidget(pageAsync.error!));
      } else {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return _wrap(children);
    }
    final others = [
      for (final review in page)
        if (review.reviewerId.isEmpty || review.reviewerId != me) review,
    ];
    if (others.isEmpty && !showMine) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _stars == null ? 'No reviews yet.' : 'No $_stars★ reviews yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    for (final review in others) {
      children.add(ReviewCard(review: review, showListing: _isUserTarget));
    }
    // A full page means there may be more.
    if (page.length >= _limit) {
      children.add(
        Center(
          child: pageAsync.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                )
              : TextButton(
                  onPressed: () => setState(() => _limit += reviewPageSize),
                  child: const Text('Load more reviews'),
                ),
        ),
      );
    }
    return _wrap(children);
  }

  Widget _wrap(List<Widget> children) {
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}

String _sortLabel(ReviewSort sort) => switch (sort) {
  ReviewSort.recent => 'Most recent',
  ReviewSort.highest => 'Highest rated',
  ReviewSort.lowest => 'Lowest rated',
};

/// "★★★★☆ 4.0 · 3 reviews", from the exact per-star counts.
class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.distribution});

  final List<int> distribution;

  @override
  Widget build(BuildContext context) {
    var total = 0;
    var stars = 0;
    for (var i = 0; i < distribution.length; i++) {
      total += distribution[i];
      stars += distribution[i] * (i + 1);
    }
    final average = total == 0 ? 0.0 : stars / total;
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < average.round() ? Icons.star : Icons.star_border,
            size: 18,
            color: AppColors.amber,
          ),
        const SizedBox(width: 8),
        Text(
          '${average.toStringAsFixed(1)} · $total '
          '${total == 1 ? 'review' : 'reviews'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// One bar per star (5 → 1); tapping a bar filters to that star count.
class _DistributionBars extends StatelessWidget {
  const _DistributionBars({
    required this.distribution,
    required this.selected,
    required this.onTap,
  });

  final List<int> distribution;
  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = distribution.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (var stars = 5; stars >= 1; stars--)
          Semantics(
            button: true,
            selected: selected == stars,
            label: 'Show $stars star reviews',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onTap(stars),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$stars ★',
                        style: selected == stars
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: maxCount == 0
                            ? 0
                            : distribution[stars - 1] / maxCount,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        color: selected == null || selected == stars
                            ? null
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${distribution[stars - 1]}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One review: rater (tap → their profile), stars, badges, comment, the
/// owner's reply, and the actions the viewer has on it — reply when they're
/// the reviewed user / listing owner, report when it's someone else's.
class ReviewCard extends ConsumerWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.showListing = true,
    this.isMine = false,
  });

  final Review review;

  /// Off under a listing's own reviews, where the title would repeat it.
  final bool showListing;

  /// The viewer's own review, pinned first and labelled.
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(currentUserIdProvider);
    final canReply = review.ownerId.isNotEmpty && review.ownerId == me;
    final canReport =
        !isMine && review.reviewerId.isNotEmpty && review.reviewerId != me;
    final footer = [
      if (showListing && review.listingTitle.isNotEmpty) review.listingTitle,
      if (review.isEdited) 'Edited',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: isMine
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, canReport ? 4 : 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  // Tapping the author opens their profile (to message them).
                  child: GestureDetector(
                    onTap: review.reviewerId.isEmpty
                        ? null
                        : () => context.push('/user/${review.reviewerId}'),
                    child: Text(
                      review.raterName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    review.rating,
                    (_) => const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.amber,
                    ),
                  ),
                ),
                if (canReport)
                  PopupMenuButton<void>(
                    tooltip: 'Review options',
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        onTap: () => _report(context, ref),
                        child: const Text('Report review'),
                      ),
                    ],
                  ),
              ],
            ),
            if (isMine || review.verified) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (isMine) const _Badge(label: 'Your review'),
                  if (review.verified)
                    const _Badge(
                      label: 'Verified chat',
                      icon: Icons.verified_outlined,
                    ),
                ],
              ),
            ],
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment),
            ],
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(footer, style: theme.textTheme.bodySmall),
            ],
            if (review.hasReply) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.kind == ReviewKind.listing
                          ? 'Response from the seller'
                          : 'Response from ${canReply ? 'you' : 'them'}',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(review.reply),
                  ],
                ),
              ),
            ],
            if (canReply)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _reply(context, ref),
                  icon: Icon(
                    review.hasReply ? Icons.edit_outlined : Icons.reply,
                    size: 18,
                  ),
                  label: Text(review.hasReply ? 'Edit reply' : 'Reply'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _reply(BuildContext context, WidgetRef ref) {
    final repo = ref.read(profileRepositoryProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ReplySheet(
        initial: review.reply,
        onSave: (text) => repo.setReviewReply(review, text),
      ),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(profileRepositoryProvider);
    final filed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ReportSheet(
        title: 'Report review',
        subtitle: review.comment.isEmpty
            ? 'Review by ${review.raterName}'
            : '${review.raterName}: “${review.comment}”',
        onSubmit: (reason, details) =>
            repo.reportReview(review, reason, details: details),
      ),
    );
    if (filed == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          filed
              ? 'Thanks — we will look into this review.'
              : 'You already reported this review.',
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.onSecondaryContainer),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with a 1–5 star picker and an optional comment. [onSubmit]
/// does the write; the sheet closes and thanks the user once it completes.
/// With [initial] it edits that review: fields start pre-filled, and
/// [onDelete] (if given) offers removing it after a confirmation.
///
/// User reviews must cite a chat: pass the shared [contexts] (a picker shows
/// when there are several). Null means the caller resolves the chat itself
/// (listing reviews).
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initial,
    this.onDelete,
    this.contexts,
  });

  final String title;
  final Future<void> Function(int rating, String comment, ReviewContext? chat)
  onSubmit;
  final Review? initial;
  final Future<void> Function()? onDelete;
  final List<ReviewContext>? contexts;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  late int _rating = widget.initial?.rating.clamp(1, 5) ?? 5;
  late final _commentController = TextEditingController(
    text: widget.initial?.comment,
  );
  late ReviewContext? _chat = _initialChat();
  bool _busy = false;
  String? _error;

  bool get _editing => widget.initial != null;
  bool get _needsChat => widget.contexts != null;

  ReviewContext? _initialChat() {
    final contexts = widget.contexts;
    if (contexts == null || contexts.isEmpty) return null;
    final current = widget.initial?.conversationId;
    for (final chat in contexts) {
      if (chat.conversationId == current) return chat;
    }
    return contexts.first;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_rating, _commentController.text, _chat);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing ? 'Review updated' : 'Review submitted — thank you!',
          ),
        ),
      );
    } on Object catch (error) {
      setState(() => _error = 'Could not submit review. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your review?'),
        content: const Text(
          'Your rating and comment will be removed. You can write a new '
          'review later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete!();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review deleted')));
    } on Object catch (error) {
      setState(() => _error = 'Could not delete review. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contexts = widget.contexts ?? const <ReviewContext>[];
    // An old review written before chats were required can still be
    // deleted, but saving it now needs a chat to cite.
    final blockedByChat = _needsChat && _chat == null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing ? 'Edit your review' : widget.title,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  iconSize: 36,
                  tooltip: '$star star${star == 1 ? '' : 's'}',
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.amber,
                  ),
                  onPressed: () => setState(() => _rating = star),
                );
              }),
            ),
            const SizedBox(height: 8),
            if (contexts.length > 1) ...[
              DropdownButtonFormField<ReviewContext>(
                initialValue: _chat,
                decoration: const InputDecoration(
                  labelText: 'Review for',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final chat in contexts)
                    DropdownMenuItem(value: chat, child: Text(chat.label)),
                ],
                onChanged: (chat) => setState(() => _chat = chat),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: reviewTextMaxLength,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            if (blockedByChat) ...[
              Text(
                'Chat with them first to update this review.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _busy || blockedByChat ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_editing ? 'Update review' : 'Submit review'),
            ),
            if (_editing && widget.onDelete != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : _delete,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete review'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The reviewed user's / listing owner's public reply to a review.
class _ReplySheet extends StatefulWidget {
  const _ReplySheet({required this.initial, required this.onSave});

  final String initial;

  /// Saves the reply; an empty string removes it.
  final Future<void> Function(String text) onSave;

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  late final _controller = TextEditingController(text: widget.initial);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String text, String done) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on Object catch (error) {
      setState(() => _error = 'Could not save reply. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial.isEmpty ? 'Reply to review' : 'Edit your reply',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Your reply is public and shown under the review.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: reviewTextMaxLength,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reply',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, _) => FilledButton(
                onPressed: _busy || value.text.trim().isEmpty
                    ? null
                    : () => _save(value.text, 'Reply posted'),
                child: const Text('Save reply'),
              ),
            ),
            if (widget.initial.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : () => _save('', 'Reply removed'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete reply'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
