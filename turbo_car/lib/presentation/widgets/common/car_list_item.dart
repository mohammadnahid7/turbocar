import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turbo_car/presentation/widgets/common/custom_button.dart';
import '../../../data/models/car_model.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/car_image_provider.dart';

class CarListItem extends ConsumerStatefulWidget {
  final CarModel car;
  final bool showSaveButton;
  final bool showDeleteButton;
  final bool showEditButton;
  final bool showShareButton;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  const CarListItem({
    super.key,
    required this.car,
    this.showSaveButton = true,
    this.showDeleteButton = false,
    this.showEditButton = false,
    this.showShareButton = false,
    this.onTap,
    this.onSave,
    this.onDelete,
    this.onEdit,
    this.onShare,
  });

  @override
  ConsumerState<CarListItem> createState() => _CarListItemState();
}

class _CarListItemState extends ConsumerState<CarListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep widget alive to prevent rebuilds

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super for AutomaticKeepAlive
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: SizedBox(
          height: 120,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car image
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: widget.car.images.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            final imageMap = ref.watch(carImageServiceProvider);
                            final localPath = imageMap[widget.car.id];

                            if (localPath != null) {
                              return Image.file(
                                File(localPath),
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 96,
                                      height: 96,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                              );
                            }

                            // While waiting for download, show placeholder
                            return Container(
                              width: 96,
                              height: 96,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 96,
                          height: 96,
                          color: Colors.grey[300],
                          child: const Icon(Icons.car_rental),
                        ),
                ),
                // Car details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.car.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                widget.car.make,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Expanded(
                          child: Text(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            widget.car.description,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              height: 1.1,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        // Price
                        Text(
                          Helpers.formatPrice(widget.car.price),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Save/Delete/Edit buttons
                if (widget.showSaveButton ||
                    widget.showDeleteButton ||
                    widget.showEditButton)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showEditButton)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CustomButton.icon(
                            icon: Icons.edit,
                            onPressed: widget.onEdit,
                            height: 35,
                            width: 35,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            backgroundColor: Theme.of(context).primaryColorDark,
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                        ),
                      if (widget.showDeleteButton || widget.showSaveButton)
                        CustomButton.icon(
                          icon: widget.showDeleteButton
                              ? Icons.delete
                              : Icons.bookmark,
                          onPressed: widget.showDeleteButton
                              ? widget.onDelete
                              : widget.onSave,
                          height: 35,
                          width: 35,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          backgroundColor: Theme.of(context).primaryColorDark,
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                          foregroundColor: widget.showDeleteButton
                              ? Theme.of(context).colorScheme.error
                              : (widget.car.isFavorited
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary),
                        ),
                    ],
                  ),
                //           SizedBox(
                //   height: 35,
                //   width: 35,
                //   child: IconButton(
                //     padding: EdgeInsets.zero,
                //     iconSize: 20,
                //     icon: Icon(
                //       showDeleteButton
                //           ? Icons.delete
                //           : car.isFavorited
                //           ? Icons.favorite
                //           : Icons.favorite_border,
                //       color: showDeleteButton
                //           ? Colors.red
                //           : car.isFavorited
                //           ? Colors.red
                //           : null,
                //     ),
                //     onPressed: showDeleteButton ? onDelete : onSave,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
