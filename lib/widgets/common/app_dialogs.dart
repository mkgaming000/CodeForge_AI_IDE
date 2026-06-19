import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What the user chose when prompted about unsaved changes.
enum UnsavedChangesAction { save, discard, cancel }

/// Centralized, reusable dialogs for file operations and confirmations.
class AppDialogs {
  AppDialogs._();

  static final RegExp _invalidNameChars = RegExp(r'[\\/\x00]');

  /// Validates a file/folder name: non-empty, trimmed, and free of path
  /// separators or null bytes. Returns an error string, or `null` if valid.
  static String? validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Name cannot be empty';
    if (trimmed == '.' || trimmed == '..') return 'Invalid name';
    if (_invalidNameChars.hasMatch(trimmed)) return 'Name cannot contain / or \\';
    return null;
  }

  /// Generic text-input dialog. Returns the entered text, or `null` if the
  /// user cancelled.
  static Future<String?> textInput({
    required BuildContext context,
    required String title,
    String? label,
    String initialValue = '',
    String confirmLabel = 'OK',
    String Function(String)? validate,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLines: maxLines,
              minLines: maxLines > 1 ? 3 : 1,
              decoration: InputDecoration(labelText: label),
              inputFormatters: inputFormatters,
              validator: validate == null
                  ? null
                  : (value) {
                      final error = validate(value ?? '');
                      return error.isEmpty ? null : error;
                    },
              onFieldSubmitted: maxLines > 1
                  ? null
                  : (value) {
                      if (formKey.currentState?.validate() ?? true) {
                        Navigator.of(context).pop(value.trim());
                      }
                    },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? true) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  /// Prompts for a new file name. [defaultExtension] (e.g. ".dart") is
  /// pre-filled to save typing, with the cursor placed before it.
  static Future<String?> newFileName(BuildContext context, {String defaultExtension = '.txt'}) {
    return textInput(
      context: context,
      title: 'New File',
      label: 'File name',
      initialValue: 'untitled$defaultExtension',
      confirmLabel: 'Create',
      validate: (value) => validateName(value) ?? '',
    );
  }

  static Future<String?> newFolderName(BuildContext context) {
    return textInput(
      context: context,
      title: 'New Folder',
      label: 'Folder name',
      initialValue: 'New Folder',
      confirmLabel: 'Create',
      validate: (value) => validateName(value) ?? '',
    );
  }

  static Future<String?> rename(BuildContext context, String currentName) {
    return textInput(
      context: context,
      title: 'Rename',
      label: 'New name',
      initialValue: currentName,
      confirmLabel: 'Rename',
      validate: (value) => validateName(value) ?? '',
    );
  }

  /// Generic Yes/No confirmation dialog.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Confirms deletion of [name] (a file or folder).
  static Future<bool> confirmDelete(BuildContext context, String name, {required bool isDirectory}) {
    return confirm(
      context: context,
      title: isDirectory ? 'Delete folder?' : 'Delete file?',
      message: isDirectory
          ? '"$name" and everything inside it will be permanently deleted.'
          : '"$name" will be permanently deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
  }

  /// Prompts the user about unsaved changes in [fileName] before closing or
  /// navigating away.
  static Future<UnsavedChangesAction> unsavedChanges(BuildContext context, String fileName) async {
    final result = await showDialog<UnsavedChangesAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved changes'),
          content: Text('"$fileName" has unsaved changes. Save before closing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.discard),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(UnsavedChangesAction.save),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return result ?? UnsavedChangesAction.cancel;
  }

  /// Shows a transient error message at the bottom of the screen.
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Shows a transient informational message at the bottom of the screen.
  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
