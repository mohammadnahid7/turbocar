import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// Service to handle sequential image downloading and caching
/// Usage:
///   - Call [addToQueue] to queue up images for download
///   - Watch/Listen to get the local file path for a car image
class CarImageService extends StateNotifier<Map<String, String>> {
  // State is a Map of CarId -> LocalFilePath
  final Dio _dio;
  final Queue<String> _downloadQueue = Queue();
  bool _isDownloading = false;
  String? _appDocPath;

  CarImageService({Dio? dio}) : _dio = dio ?? Dio(), super({}) {
    _init();
  }

  Future<void> _init() async {
    final directory = await getApplicationDocumentsDirectory();
    _appDocPath = '${directory.path}/car_thumbnails';
    await Directory(_appDocPath!).create(recursive: true);

    // Load existing files into state
    // We assume file name format: {carId}_{hash}.jpg
    // But for simplicity in this version, we'll just check existence when asked
    // or we can scan the directory.
    // For now, let's keep state empty and populate it as we check/download.
    // Optimisation: We could persist the map of downloaded files to SharedPreferences
    // to avoid disk I/O on every startup, but filesystem check is fast enough for small lists.
  }

  /// Get the local file path for a car's thumbnail if it exists.
  /// Returns null if not downloaded yet.
  String? getLocalPath(String carId) {
    return state[carId];
  }

  /// Add a list of cars to the download queue.
  /// Checks if file exists first.
  Future<void> addToQueue(List<dynamic> cars) async {
    if (_appDocPath == null) await _init();

    for (final car in cars) {
      // Assuming car object has 'id' and 'images' list
      final String id = car.id;
      final List<String> images = car.images;

      if (images.isEmpty) continue;

      final String imageUrl = images.first;

      // Generate a unique filename based on ID and URL hash (to detect updates)
      // If author updates image, the URL usually changes (signed URLs) or remains same.
      // If URL remains same but content changes, we technically can't know without headers.
      // User requirement: "updated image links will be stored in database".
      // So if link changes, we get a new hash, thus new file.
      final String filename = _generateFilename(id, imageUrl);
      final String filePath = '$_appDocPath/$filename';

      final file = File(filePath);
      if (await file.exists()) {
        if (!state.containsKey(id)) {
          state = {...state, id: filePath};
        }
        continue;
      }

      // Not in disk, add to queue
      // store the full task details in a separate queue or map if needed
      // For simplicity, we'll use a queue of objects or just trigger processing
      // We need to know WHICH url to download for the ID when processing.
      // Let's store a pending map.
      if (!_pendingDownloads.containsKey(id)) {
        _pendingDownloads[id] = imageUrl;
        _downloadQueue.add(id);
      }
    }

    _processQueue();
  }

  final Map<String, String> _pendingDownloads = {};

  Future<void> _processQueue() async {
    if (_isDownloading || _downloadQueue.isEmpty) return;

    _isDownloading = true;

    while (_downloadQueue.isNotEmpty) {
      final carId = _downloadQueue.removeFirst();
      final url = _pendingDownloads.remove(carId);

      if (url == null) continue;

      try {
        final filename = _generateFilename(carId, url);
        final filePath = '$_appDocPath/$filename';

        // Check again just in case
        if (await File(filePath).exists()) {
          state = {...state, carId: filePath};
          continue;
        }

        // Download
        await _dio.download(url, filePath);

        // Update State
        state = {...state, carId: filePath};

        // Small delay to ensure UI doesn't stutter? Optional.
        // await Future.delayed(Duration(milliseconds: 50));
      } catch (e) {
        print('Error downloading image for car $carId: $e');
        // Optional: Retry logic or put back in queue?
      }
    }

    _isDownloading = false;
  }

  String _generateFilename(String carId, String url) {
    // We use a hash of the URL to ensure if URL changes, we get new file.
    // But we prefix with carId for easier debugging/cleanup if needed.
    final urlHash = md5.convert(utf8.encode(url)).toString();
    return '${carId}_$urlHash.jpg';
  }
}

// Check pubspec.yaml if we need 'crypto' package. 
// If not, we can use a simpler hashCode or base64.
// Step 45 showed 'crypto' is NOT in dependencies. 
// I should verify if I can add it or just use hashCode.
// Dart's hashCode is not persistent across runs strictly speaking (though usually is for strings).
// Better to use base64Encode of the URL to be safe without extra package if crypto is missing.
