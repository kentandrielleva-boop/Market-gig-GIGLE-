import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_gig/core/providers/app_providers.dart';
import 'package:marketplace_gig/core/widgets/app_backdrop.dart';
import 'package:marketplace_gig/core/widgets/app_header.dart';
import 'package:marketplace_gig/core/widgets/gigl_buttons.dart';
import 'package:marketplace_gig/domain/models/models.dart';

/// Lets the signed-in user edit their display name, bio, and avatar.
///
/// Edits are written to the `profiles` row (name/bio/avatar_url) and, when a
/// new picture is picked, the image is uploaded to the public `avatars`
/// storage bucket first and its public URL is saved on the profile. The
/// realtime profile stream in [profileProvider] reflects the change as soon as
/// the upsert lands, so the profile screen header updates without a reload.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String _avatarUrl = '';
  String? _pickedPath;
  bool _initialized = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _pickedPath = file.path;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(profileRepositoryProvider);
      var avatarUrl = _avatarUrl;
      if (_pickedPath != null) {
        avatarUrl = await repo.uploadAvatar(_pickedPath!);
      }
      await repo.updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on Object catch (error) {
      setState(() => _error = 'Could not save profile. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _hydrateFrom(UserProfile? profile) {
    if (profile == null) return;
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _avatarUrl = profile.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final isLoading = profileAsync.isLoading;
    // Hydrate once profile arrives, and also re-hydrate if still empty
    // when null transitions to data (fixes CTA→edit blank fields).
    if (!_initialized) _hydrateFrom(profile);

    final canSave = _nameController.text.trim().isNotEmpty && !_busy;
    final showLoading = isLoading && !_initialized && profile == null;

    if (showLoading) {
      return const Scaffold(
        body: AppBackdrop(
          variant: AppBackdropVariant.form,
          child: SafeArea(
            child: Column(
              children: [
                AppHeader(title: 'Edit profile'),
                Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AppBackdrop(
        variant: AppBackdropVariant.form,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(title: 'Edit profile'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _busy ? null : _pickAvatar,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: scheme.primaryContainer,
                                backgroundImage: _pickedPath != null
                                    ? FileImage(File(_pickedPath!))
                                    : (_avatarUrl.isNotEmpty
                                          ? NetworkImage(_avatarUrl)
                                          : null),
                                child: _pickedPath == null && _avatarUrl.isEmpty
                                    ? const Icon(Icons.person, size: 48)
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: scheme.primary,
                                  child: Icon(
                                    Icons.photo_camera,
                                    size: 18,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the photo to change your avatar',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        maxLength: 60,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bioController,
                        onChanged: (_) => setState(() {}),
                        maxLength: 200,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText: 'Tell people about yourself…',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      InkButton(
                        onPressed: canSave ? _save : null,
                        busy: _busy,
                        label: 'Save',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
