import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/dock/dock_logic.dart';
import '../providers/dock_provider.dart';
import '../widgets/app_toast.dart';
import 'save_sheet.dart';
import 'sort_screen.dart';

class CollectionScreen extends StatelessWidget {
  final String? collectionId;

  const CollectionScreen({super.key, this.collectionId});

  @override
  Widget build(BuildContext context) {
    final dock = context.watch<DockProvider>();
    final collection =
        collectionId == null ? null : dock.collectionById(collectionId!);
    if (collectionId != null && collection == null) {
      return Scaffold(
        backgroundColor: AppColors.canvasOf(context),
        appBar: AppBar(),
        body: const Center(child: Text('This collection was removed.')),
      );
    }
    final rows = DockLogic.inCollection(dock.items, collectionId);
    final done = DockLogic.doneCount(rows);
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    final yellow = AppColors.primaryOf(context);
    final name = collection?.name ?? 'Unsorted';
    final tag = collection?.tag ?? '';
    final progress = rows.isEmpty ? 0.0 : done / rows.length;
    return Scaffold(
      backgroundColor: AppColors.canvasOf(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: ink)),
                const Spacer(),
                Text('COLLECTION',
                    style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 12)),
                const Spacer(),
                IconButton(
                  onPressed: () => _menu(context, collection?.id),
                  icon: Icon(Icons.more_horiz, color: ink),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(name,
                      style: TextStyle(
                          color: ink,
                          fontSize: 36,
                          height: 1,
                          fontWeight: FontWeight.w800)),
                ),
                const _Bars(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${rows.length.toString().padLeft(2, '0')} ITEMS${tag.isEmpty ? '' : ' · ${tag.toUpperCase()}'}',
              style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Text('$done of ${rows.length} done',
                style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: yellow,
                backgroundColor: AppColors.borderOf(context),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < rows.length; i++) ...[
              _Row(index: i + 1, item: rows[i]),
              const SizedBox(height: 10),
            ],
            _AddTile(
                onTap: () =>
                    showSaveSheet(context, collectionId: collectionId)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Share.share(dock.exportCollection(collectionId)),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Export collection'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.lock_outline, size: 14, color: muted),
                const SizedBox(width: 6),
                Text('Stored on this device',
                    style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, String? id) async {
    final dock = context.read<DockProvider>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Export library'),
              onTap: () {
                Navigator.pop(sheet);
                Share.share(dock.exportAll());
              },
            ),
            if (id != null)
              ListTile(
                title: const Text('Rename collection'),
                onTap: () async {
                  Navigator.pop(sheet);
                  final current = dock.collectionById(id)?.name ?? '';
                  final next = await showDialog<String>(
                    context: context,
                    builder: (_) => _RenameDialog(initial: current),
                  );
                  if (next != null) dock.renameCollection(id, next);
                },
              ),
            if (id != null)
              ListTile(
                title: const Text('Delete collection'),
                onTap: () {
                  Navigator.pop(sheet);
                  dock.deleteCollection(id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    final yellow = AppColors.primaryOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(width: 10, height: 28, color: yellow),
        const SizedBox(width: 4),
        Container(width: 10, height: 44, color: yellow),
        const SizedBox(width: 4),
        Container(width: 10, height: 18, color: yellow.withValues(alpha: 0.45)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final int index;
  final DockItem item;

  const _Row({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final dock = context.read<DockProvider>();
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    final yellow = AppColors.primaryOf(context);
    final onYellow = AppColors.onPrimaryOf(context);
    final lane = item.done
        ? 'DONE'
        : (item.lane == null
            ? 'UNSORTED'
            : DockLogic.laneLabel(item.lane!).toUpperCase());
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SortScreen(itemId: item.id)));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.done)
                    Icon(Icons.check_circle, color: yellow, size: 18)
                  else
                    Text(index.toString().padLeft(2, '0'),
                        style: TextStyle(
                            color: muted, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Text(lane,
                      style: TextStyle(
                          color: item.done ? yellow : muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: muted, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                style: TextStyle(
                  color: item.done ? muted : ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                ),
              ),
              if (item.body.isNotEmpty)
                Text(item.body, style: TextStyle(color: muted, fontSize: 13)),
              if (!item.done && item.kind == SaveKind.link) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _open(context, item.url),
                        child: const Text('Open link'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => dock.markDone(item.id),
                        style: FilledButton.styleFrom(
                            backgroundColor: yellow, foregroundColor: onYellow),
                        child: const Text('Mark done'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.contains('://') ? url : 'https://$url');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        AppToast.show(context, title: 'Could not open that link');
      }
    }
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.secondaryInk(context);
    final ink = AppColors.inkOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: muted.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              Icon(Icons.add, color: ink),
              const SizedBox(height: 4),
              Text('Add something useful',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
              Text('Links, notes, or files.',
                  style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final String initial;

  const _RenameDialog({required this.initial});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename'),
      content: TextField(
          controller: _name,
          autofocus: true,
          onSubmitted: (value) => _close(value)),
      actions: [
        TextButton(onPressed: () => _close(), child: const Text('Cancel')),
        TextButton(
            onPressed: () => _close(_name.text), child: const Text('Save')),
      ],
    );
  }
}
