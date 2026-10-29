import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/domain/models/models.dart';
import 'package:marketplace_gig/features/post/photo_grid.dart';

/// Opens the post form as a modal bottom sheet.
Future<void> showPostSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const PostSheet(),
  );
}

class PostSheet extends ConsumerStatefulWidget {
  const PostSheet({super.key});

  @override
  ConsumerState<PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends ConsumerState<PostSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController(
      text: ref.read(postFormProvider).location,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(postFormProvider);
    final notifier = ref.read(postFormProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<ListingType>(
                  segments: const [
                    ButtonSegment(
                      value: ListingType.item,
                      label: Text('Sell an Item'),
                    ),
                    ButtonSegment(
                      value: ListingType.gig,
                      label: Text('Post a Gig'),
                    ),
                  ],
                  selected: {form.type},
                  onSelectionChanged: (value) => notifier.setType(value.first),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    PhotoGrid(
                      paths: form.photoPaths,
                      onAdd: () async {
                        final picker = ImagePicker();
                        final files = await picker.pickMultiImage(limit: 5);
                        if (files.isEmpty) return;
                        notifier.addPhotos(files.map((f) => f.path).toList());
                      },
                      onRemove: notifier.removePhotoAt,
                    ),
                    if (form.photoPaths.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Add at least one photo to post.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      maxLength: 80,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: notifier.setTitle,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      maxLength: 12,
                      decoration: const InputDecoration(
                        labelText: 'Price / Budget',
                        prefixText: '₱ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: notifier.setPrice,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        helperText: 'Barangay, city or landmark',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      onChanged: notifier.setLocation,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 4,
                      onChanged: notifier.setDescription,
                    ),
                    if (form.type == ListingType.gig) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Duration / Timeline',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final duration in [
                            '1-3 days',
                            '1 week',
                            '2 weeks',
                            '1 month',
                          ])
                            GiglChoiceChip(
                              label: duration,
                              selected: form.duration == duration,
                              onSelected: (_) => notifier.setDuration(duration),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Remote-Only'),
                        value: form.remoteOnly,
                        onChanged: notifier.setRemoteOnly,
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (form.errorMessage != null) ...[
                        // Shown after a failed submit; cleared automatically as
                        // soon as the user edits the form again.
                        Text(
                          form.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      InkButton(
                        onPressed: form.canSubmit
                            ? () async {
                                final ok = await notifier.submit();
                                if (ok && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Listing posted'),
                                    ),
                                  );
                                }
                              }
                            : null,
                        busy: form.isSubmitting,
                        label: 'Post',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
