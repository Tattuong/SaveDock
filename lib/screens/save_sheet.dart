import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/dock/dock_logic.dart';
import '../providers/dock_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_toast.dart';
import 'sort_screen.dart';

Future<void> showSaveSheet(BuildContext context, {String? collectionId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    showDragHandle: true,
    builder: (_) => _SaveSheet(collectionId: collectionId),
  );
}

class _SaveSheet extends StatefulWidget {
  final String? collectionId;

  const _SaveSheet({this.collectionId});

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  var _mode = 0;
  var _leaving = false;
  final _link = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();

  void _leave(void Function(NavigatorState navigator)? after) {
    if (_leaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      after?.call(navigator);
    });
  }

  @override
  void dispose() {
    _link.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(null);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Save',
                style: TextStyle(
                    color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              widget.collectionId == null
                  ? 'It lands in Unsorted. You can give it a next step after.'
                  : 'It stays in this collection. You can give it a next step after.',
              style: TextStyle(color: AppColors.secondaryInk(context)),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                    value: 0, label: Text('Link'), icon: Icon(Icons.link)),
                ButtonSegment(
                    value: 1, label: Text('Note'), icon: Icon(Icons.notes)),
                ButtonSegment(
                    value: 2,
                    label: Text('File'),
                    icon: Icon(Icons.attach_file)),
              ],
              selected: {_mode},
              onSelectionChanged: (value) {
                FocusManager.instance.primaryFocus?.unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _mode = value.first);
                });
              },
            ),
            const SizedBox(height: 12),
            if (_mode == 0) ...[
              TextField(
                  controller: _link,
                  decoration: const InputDecoration(labelText: 'Link'),
                  keyboardType: TextInputType.url),
              TextField(
                  controller: _title,
                  decoration:
                      const InputDecoration(labelText: 'Name (optional)')),
            ],
            if (_mode == 1) ...[
              TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note'),
                  minLines: 3,
                  maxLines: 6),
            ],
            if (_mode == 2)
              const Text(
                  'Pick a file from this device. The page itself is not downloaded for offline reading.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _save,
                child: Text(_mode == 2 ? 'Choose file' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final dock = context.read<DockProvider>();
    final pro = context.read<ShopProvider>().hasPro;
    final collectionId = widget.collectionId;
    late final SaveResult result;
    if (_mode == 2) {
      final picked = await FilePicker.platform.pickFiles();
      final path = picked?.files.single.path;
      if (path == null) return;
      result = await dock.addFile(path, collectionId: collectionId, pro: pro);
    } else if (_mode == 1) {
      result = dock.addNote(_title.text, _note.text,
          collectionId: collectionId, pro: pro);
    } else {
      if (_link.text.trim().isEmpty) return;
      result = dock.addLink(_link.text,
          title: _title.text, collectionId: collectionId, pro: pro);
    }
    if (!mounted) return;
    if (result == SaveResult.added) {
      final id = dock.items.first.id;
      _leave((navigator) {
        navigator
            .push(MaterialPageRoute(builder: (_) => SortScreen(itemId: id)));
      });
      return;
    }
    AppToast.show(context, title: dock.notice ?? 'Could not save');
  }
}
