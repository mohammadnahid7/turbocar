import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/sequential_image_queue.dart';

class SequentialNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget Function(BuildContext, String)? placeholder;

  const SequentialNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.errorWidget,
    this.placeholder,
  });

  @override
  State<SequentialNetworkImage> createState() => _SequentialNetworkImageState();
}

class _SequentialNetworkImageState extends State<SequentialNetworkImage> {
  bool _canLoad = false;
  bool _taskCompleted = false;

  @override
  void initState() {
    super.initState();
    _requestLoading();
  }

  Future<void> _requestLoading() async {
    await StrictSequentialImageQueue().waitForTurn();
    if (mounted) {
      setState(() {
        _canLoad = true;
      });
    } else {
      // If disposed while waiting, release the lock immediately
      StrictSequentialImageQueue().taskCompleted();
    }
  }

  void _signalCompletion() {
    if (!_taskCompleted) {
      _taskCompleted = true;
      StrictSequentialImageQueue().taskCompleted();
    }
  }

  @override
  void dispose() {
    // If we were loading or waiting, we might need to cleanup?
    // Actually, if we are disposed, we should signal completion so the queue doesn't stall
    // ONLY if we were the one holding the lock (i.e. _canLoad was true) AND we haven't signaled yet.
    if (_canLoad && !_taskCompleted) {
      _signalCompletion();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canLoad) {
      // Show placeholder or empty space while waiting
      return widget.placeholder?.call(context, widget.imageUrl) ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorWidget: (context, url, error) {
        _signalCompletion();
        return widget.errorWidget?.call(context, url, error) ??
            const Icon(Icons.error);
      },
      placeholder: (context, url) {
        return widget.placeholder?.call(context, url) ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      imageBuilder: (context, imageProvider) {
        // As soon as image is available (loaded), signal completion
        // Note: imageBuilder is called when image is loaded.
        // However, CachedNetworkImage also has checks.
        // Let's use listener logic or just assume imageBuilder call means success.
        // Better: ensure this runs only once.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _signalCompletion();
        });

        return Image(
          image: imageProvider,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
        );
      },
      // Using a listener to be safer about completion?
      // CachedNetworkImage doesn't expose a simple "onComplete".
      // But imageBuilder is only called on success.
    );
  }
}
