import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/utils/image_picker_service.dart';
import '../../domain/entities/user_activity_entity.dart';
import '../../providers/user_activity_provider.dart';

/// Edit Activity page - form for user activity with photos
class EditUserActivityPage extends ConsumerStatefulWidget {
  const EditUserActivityPage({super.key, this.activityId});
  
  /// If null, creating new activity. If provided, editing existing.
  final String? activityId;

  @override
  ConsumerState<EditUserActivityPage> createState() => _EditUserActivityPageState();
}

class _EditUserActivityPageState extends ConsumerState<EditUserActivityPage> {
  static const int _maxPhotosPerActivity = 5;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;
  List<String> _imageUrls = [];
  bool _hydrated = false;

  String _networkImageUrl(String path) {
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('/media/')) {
      return '${ApiConfig.baseUrl}$t';
    }
    return t;
  }
  
  bool get _isValid => 
    _nameController.text.isNotEmpty && 
    _selectedDate != null;

  /// Helper to build image widget for local file or network URL
  Widget _buildActivityImage(String imagePath, {double? width, double? height}) {
    // Decode at the display resolution rather than the full source
    // resolution — without this, even a small thumbnail slot (e.g. the
    // 90x72 secondary-photo strip) decodes the entire uploaded photo into
    // memory. Only applied when an explicit, finite display size is given —
    // the main photo preview passes width: double.infinity to stretch full
    // width, and (double.infinity * dpr).round() throws ("Unsupported
    // operation: Infinity or NaN toInt"), which crashed the page outright.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (width != null && width.isFinite) ? (width * dpr).round() : null;
    final cacheHeight = (height != null && height.isFinite) ? (height * dpr).round() : null;

    // Check if it's a local file path
    if (imagePath.startsWith('/') || imagePath.contains('cache') || imagePath.contains('tmp')) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) => _buildImageError(width, height),
        );
      }
    }

    final resolvedNetwork = _networkImageUrl(imagePath);
    if (resolvedNetwork.startsWith('http://') || resolvedNetwork.startsWith('https://')) {
      return Image.network(
        resolvedNetwork,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) => _buildImageError(width, height),
      );
    }

    // Fallback for assets
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (context, error, stackTrace) => _buildImageError(width, height),
    );
  }
  
  Widget _buildImageError(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.grey.withValues(alpha: 0.2),
      child: const Center(
        child: AppIcon(AppIcons.gallery, size: 32, color: AppColors.grey),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // If editing, load existing data. The list may still be loading on a
    // cold start / deep link — build() hydrates again once it arrives.
    if (widget.activityId != null) {
      _hydrateFrom(ref.read(userActivityListProvider));
    }
  }

  /// Populates the form from the loaded list. Safe to call multiple times:
  /// only fills once and never clobbers edits the user already started.
  void _hydrateFrom(List<UserActivityEntity> activities) {
    if (_hydrated) return;
    UserActivityEntity? existing;
    for (final activity in activities) {
      if (activity.id == widget.activityId) {
        existing = activity;
        break;
      }
    }
    if (existing == null) return;
    if (_nameController.text.isNotEmpty || _selectedDate != null) return;
    _nameController.text = existing.name;
    _descriptionController.text = existing.description ?? '';
    _selectedDate = existing.date;
    _imageUrls = List.from(existing.imageUrls);
    _hydrated = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _deleteActivity() {
    if (widget.activityId == null) return;
    // Pop immediately — provider removes from list and rolls back on error
    if (mounted && context.mounted) context.pop();
    ref.read(userActivityListProvider.notifier).remove(widget.activityId!).ignore();
  }

  void _save() {
    if (!_isValid) return;

    final activity = UserActivityEntity(
      id: widget.activityId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '1',
      name: _nameController.text.trim(),
      date: _selectedDate!,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      imageUrls: _imageUrls,
      createdAt: DateTime.now(),
    );

    final notifier = ref.read(userActivityListProvider.notifier);
    if (mounted && context.mounted) {
      AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
    }
    if (mounted && context.mounted) context.pop();
    if (widget.activityId != null) {
      notifier.update(activity).ignore();
    } else {
      notifier.add(activity).ignore();
    }
  }

  void _showDatePicker() {
    final l10n = AppLocalizations.of(context)!;

    AppBottomSheet.show(
      context: context,
      title: l10n.gamification_date,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              child: _DatePickerWheel(
                initialDate: _selectedDate ?? DateTime.now(),
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.common_save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSheet() {
    final l10n = AppLocalizations.of(context)!;

    AppBottomSheet.show(
      context: context,
      title: l10n.gamification_activityPhoto,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPhotoOption(
              icon: AppIcons.gallery,
              label: l10n.editProfile_chooseFromGallery,
              onTap: () async {
                Navigator.pop(context);
                await _pickFromGallery();
              },
            ),
            _buildPhotoOption(
              icon: AppIcons.camera,
              label: l10n.editProfile_takePhoto,
              onTap: () async {
                Navigator.pop(context);
                await _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (_imageUrls.length >= _maxPhotosPerActivity) {
      if (mounted && context.mounted) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.profile_activityMaxPhotos,
        );
      }
      return;
    }
    final result = await ImagePickerService().pickFromGallery();
    if (result.isSuccess && result.path != null) {
      setState(() {
        _imageUrls.add(result.path!);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    if (_imageUrls.length >= _maxPhotosPerActivity) {
      if (mounted && context.mounted) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.profile_activityMaxPhotos,
        );
      }
      return;
    }
    final result = await ImagePickerService().pickFromCamera();
    if (result.isSuccess && result.path != null) {
      setState(() {
        _imageUrls.add(result.path!);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Widget _buildPhotoOption({
    required AppIconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AppIcon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hydrate once the list arrives (handles cold-start / deep-link races where
    // the provider was still loading during initState).
    if (widget.activityId != null && !_hydrated) {
      _hydrateFrom(ref.watch(userActivityListProvider));
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.profile_activity,
        actions: [
          if (widget.activityId != null)
            IconButton(
              tooltip: l10n.common_delete,
              onPressed: _deleteActivity,
              icon: const AppIcon(AppIcons.delete, color: Colors.red),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Photo Section ──
                  _buildPhotoSection(isLight, l10n),
                  const SizedBox(height: 16),

                  // ── Details Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.white : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                      ),
                      boxShadow: isLight
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name field
                        _buildInputField(
                          controller: _nameController,
                          label: l10n.gamification_activityName,
                          placeholder: l10n.gamification_activityName,
                          icon: AppIcons.edit,
                        ),
                        const SizedBox(height: 16),
                        
                        // Date field
                        GestureDetector(
                          onTap: _showDatePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isLight ? AppColors.white : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                              ),
                            ),
                            child: Row(
                              children: [
                                AppIcon(
                                  AppIcons.calendar,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_selectedDate != null)
                                        Text(
                                          l10n.gamification_date,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey,
                                          ),
                                        ),
                                      Text(
                                        _selectedDate != null 
                                          ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                                          : l10n.gamification_date,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _selectedDate != null
                                              ? (isLight ? AppColors.textColor : AppColors.textColorDark)
                                              : AppColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppIcon(
                                  AppIcons.chevronRight,
                                  color: AppColors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description field
                        _buildInputField(
                          controller: _descriptionController,
                          label: l10n.gamification_description,
                          placeholder: l10n.gamification_description,
                          icon: AppIcons.document,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isValid ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid ? AppColors.primary : AppColors.secondary,
                  foregroundColor: _isValid ? Colors.white : AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.common_save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(bool isLight, AppLocalizations l10n) {
    if (_imageUrls.isEmpty) {
      return GestureDetector(
        onTap: _showPhotoSheet,
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isLight
                      ? AppColors.primaryLight
                      : AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  AppIcons.camera,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                l10n.gamification_attachPhoto,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main image
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildActivityImage(
                _imageUrls.first,
                width: double.infinity,
                height: 200,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(AppIcons.delete, size: 18, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _showPhotoSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isLight ? AppColors.white : AppColors.surfaceDark).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                    ),
                  ),
                  child: AppIcon(AppIcons.add, size: 20, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        if (_imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _imageUrls.length - 1,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final imageIndex = index + 1;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildActivityImage(
                        _imageUrls[imageIndex],
                        width: 90,
                        height: 72,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(imageIndex),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppIcon(AppIcons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    AppIconData? icon,
    int maxLines = 1,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hasContent = controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 4 : 0),
              child: AppIcon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasContent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    hintText: hasContent ? null : placeholder,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                    ),
                    filled: true,
                    fillColor: isLight ? AppColors.white : AppColors.surfaceDark,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: isLight
                        ? AppColors.textColor
                        : AppColors.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
          if (hasContent)
            GestureDetector(
              onTap: () {
                controller.clear();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isLight
                      ? AppColors.grey.withValues(alpha: 0.2)
                      : AppColors.borderDark,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  AppIcons.close,
                  size: 14,
                  color: AppColors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Date picker wheel widget
class _DatePickerWheel extends StatefulWidget {
  const _DatePickerWheel({
    required this.initialDate,
    required this.onDateChanged,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_DatePickerWheel> createState() => _DatePickerWheelState();
}

class _DatePickerWheelState extends State<_DatePickerWheel> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;
  
  late int _day;
  late int _month;
  late int _year;

  final _years = List.generate(30, (i) => DateTime.now().year - i);

  List<String> _localizedMonths(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return List.generate(
      12,
      (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)),
    );
  }

  @override
  void initState() {
    super.initState();
    _day = widget.initialDate.day;
    _month = widget.initialDate.month;
    _year = widget.initialDate.year;
    
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(initialItem: _years.indexOf(_year).clamp(0, _years.length - 1));
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  /// Clamps the selected day to the number of days in the current month/year
  /// so impossible dates (e.g. 31 February) can't be produced.
  void _clampDayToMonth() {
    final maxDay = _daysInMonth;
    if (_day > maxDay) {
      _day = maxDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayController.hasClients) {
          _dayController.animateToItem(
            _day - 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _updateDate() {
    final today = DateTime.now();
    var date = DateTime(_year, _month, _day);
    if (date.isAfter(DateTime(today.year, today.month, today.day))) {
      date = DateTime(today.year, today.month, today.day);
    }
    widget.onDateChanged(date);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Row(
      children: [
        // Day
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: _dayController,
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              _day = index + 1;
              _updateDate();
            },
            physics: const FixedExtentScrollPhysics(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _daysInMonth,
              builder: (context, index) => Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    color: isLight
                        ? AppColors.textColor
                        : AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Month
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: _monthController,
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              setState(() {
                _month = index + 1;
                _clampDayToMonth();
              });
              _updateDate();
            },
            physics: const FixedExtentScrollPhysics(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 12,
              builder: (context, index) => Center(
                child: Text(
                  _localizedMonths(context)[index],
                  style: TextStyle(
                    fontSize: 18,
                    color: isLight
                        ? AppColors.textColor
                        : AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Year
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: _yearController,
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              setState(() {
                _year = _years[index];
                _clampDayToMonth();
              });
              _updateDate();
            },
            physics: const FixedExtentScrollPhysics(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _years.length,
              builder: (context, index) => Center(
                child: Text(
                  '${_years[index]}',
                  style: TextStyle(
                    fontSize: 18,
                    color: isLight
                        ? AppColors.textColor
                        : AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
