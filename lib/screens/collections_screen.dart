import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/dock/dock_logic.dart';
import '../core/navigation/app_navigator.dart';
import '../providers/dock_provider.dart';
import 'collection_screen.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dock = context.watch<DockProvider>();
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    final unsorted = DockLogic.inCollection(dock.items, null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Row(
          children: [
            Text('Collections',
                style: TextStyle(
                    color: ink, fontSize: 32, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              onPressed: AppTabs.goSettings,
              icon: Icon(Icons.settings_outlined, color: ink),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _tile(
          context,
          title: 'Unsorted',
          subtitle: '${unsorted.length} waiting for a next step',
          onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CollectionScreen()));
          },
        ),
        for (final collection in dock.collections) ...[
          const SizedBox(height: 10),
          _tile(
            context,
            title: collection.name,
            subtitle: _subtitle(dock, collection.id, collection.tag),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        CollectionScreen(collectionId: collection.id)),
              );
            },
          ),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _create(context),
          icon: const Icon(Icons.add),
          label: const Text('New collection'),
        ),
        const SizedBox(height: 8),
        Text('Stored on this device',
            style: TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }

  String _subtitle(DockProvider dock, String id, String tag) {
    final rows = DockLogic.inCollection(dock.items, id);
    final done = DockLogic.doneCount(rows);
    final count = rows.length.toString().padLeft(2, '0');
    final label = tag.isEmpty ? '' : ' · ${tag.toUpperCase()}';
    return '$count items$label · $done of ${rows.length} done';
  }

  Widget _tile(BuildContext context,
      {required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        title: Text(title,
            style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: TextStyle(color: muted)),
        trailing: Icon(Icons.chevron_right, color: muted),
        onTap: onTap,
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final next = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(),
    );
    if (next == null || !context.mounted) return;
    context.read<DockProvider>().createCollection(next);
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _name = TextEditingController();

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
      title: const Text('Collection name'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Weekend reset'),
        onSubmitted: (value) => _close(value),
      ),
      actions: [
        TextButton(onPressed: () => _close(), child: const Text('Cancel')),
        TextButton(
            onPressed: () => _close(_name.text), child: const Text('Create')),
      ],
    );
  }
}
