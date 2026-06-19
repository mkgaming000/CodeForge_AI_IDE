import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// The result of a storage-permission check or request.
enum StorageAccessStatus {
  /// Full read/write access to shared storage is granted.
  granted,

  /// Access has not been requested yet, or was denied but can be asked
  /// again.
  denied,

  /// Access was permanently denied; the user must enable it from system
  /// Settings.
  permanentlyDenied,

  /// Not applicable on this platform (e.g. desktop/iOS sandboxes don't use
  /// this permission model).
  notApplicable,
}

/// Wraps `permission_handler` to manage the broad file-system access
/// CodeForge needs to open arbitrary project folders and run builds/tools in
/// later phases.
///
/// On Android 11+ this requires the special "All files access" permission
/// (`MANAGE_EXTERNAL_STORAGE`), which can only be granted via a system
/// Settings screen — [requestStorageAccess] opens that screen for the user.
/// On Android 10 and below, the legacy `READ/WRITE_EXTERNAL_STORAGE`
/// permissions are requested instead.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Checks the current storage access status without prompting the user.
  Future<StorageAccessStatus> checkStorageAccess() async {
    if (!Platform.isAndroid) return StorageAccessStatus.notApplicable;

    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) return StorageAccessStatus.granted;

    // Fall back to legacy storage permission for Android <= 10, where
    // MANAGE_EXTERNAL_STORAGE is not applicable and reports as restricted.
    if (manageStatus.isRestricted || manageStatus.isLimited) {
      final legacy = await Permission.storage.status;
      if (legacy.isGranted) return StorageAccessStatus.granted;
    }

    if (manageStatus.isPermanentlyDenied) {
      return StorageAccessStatus.permanentlyDenied;
    }
    return StorageAccessStatus.denied;
  }

  /// Requests storage access, prompting the user if necessary. Returns the
  /// resulting status.
  Future<StorageAccessStatus> requestStorageAccess() async {
    if (!Platform.isAndroid) return StorageAccessStatus.notApplicable;

    final current = await checkStorageAccess();
    if (current == StorageAccessStatus.granted) return current;

    // Request the modern "All files access" permission first.
    final manageResult = await Permission.manageExternalStorage.request();
    if (manageResult.isGranted) return StorageAccessStatus.granted;

    // Some OEM/Android versions report manageExternalStorage as restricted
    // rather than granting it — fall back to the classic permission set.
    final legacyResult = await Permission.storage.request();
    if (legacyResult.isGranted) return StorageAccessStatus.granted;

    if (manageResult.isPermanentlyDenied || legacyResult.isPermanentlyDenied) {
      return StorageAccessStatus.permanentlyDenied;
    }
    return StorageAccessStatus.denied;
  }

  /// Opens the app's system Settings page, used when permission has been
  /// permanently denied and must be granted manually.
  Future<void> openSettings() => openAppSettings();
}
