import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/dock/dock_logic.dart';
import '../providers/dock_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/dock_art.dart';

class SortScreen extends StatefulWidget {
  final String itemId;

  const SortScreen({super.key, required this.itemId});

  @override
  State<SortScreen> createState() => _SortScreenState();
}

class _SortScreenState extends State<SortScreen> {
  Lane? _lane;
  DateTime? _remind;
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    final dock = context.watch<DockProvider>();
    final item = dock.itemById(widget.itemId);
    final open = dock.open;
    final index = open.indexWhere((row) => row.id == widget.itemId);
    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.canvasOf(context),
        appBar: AppBar(),
        body: const Center(child: Text('This save was removed.')),
      );
    }
    if (!_ready) {
      _lane = item.lane;
      _remind = item.remindAt;
      _ready = true;
    }
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    final yellow = AppColors.primaryOf(context);
    final onYellow = AppColors.onPrimaryOf(context);
    final place = index < 0 ? 1 : index + 1;
    final total = open.isEmpty ? 1 : open.length;
    return Scaffold(
      backgroundColor: AppColors.canvasOf(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: ink)),
                Expanded(
                  child: Text(
                    'SORT YOUR DOCK',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 12),
                  ),
                ),
                Text(
                  '${place.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Give it a\nnext step.', style: TextStyle(color: ink, fontSize: 36, height: 0.95, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _StackCard(item: item),
            const SizedBox(height: 8),
            Text('Drag to a lane, or tap below.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                for (final lane in DockLogic.laneOrder) _laneTile(lane, yellow, onYellow, ink, muted),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                leading: Icon(Icons.notifications_none, color: ink),
                title: Text('Remind me', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                trailing: Text(DockLogic.remindLabel(_remind, DateTime.now()), style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                onTap: () => _pickRemind(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _lane == null
                          ? null
                          : () {
                              dock.setLane(item.id, _lane!);
                              dock.setReminder(item.id, _remind);
                              Navigator.pop(context);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: onYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _lane == null ? 'Pick a lane' : 'Save to ${DockLogic.laneLabel(_lane!)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ink,
                      side: BorderSide(color: AppColors.borderOf(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            if (item.url.isNotEmpty)
              TextButton(
                onPressed: () => _open(item.url),
                child: const Text('Open link'),
              ),
            if (item.kind == SaveKind.file)
              TextButton(
                onPressed: () => _openFile(item),
                child: const Text('Open file'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _laneTile(Lane lane, Color yellow, Color onYellow, Color ink, Color muted) {
    final selected = _lane == lane;
    final icon = switch (lane) {
      Lane.read => Icons.menu_book_outlined,
      Lane.tryOut => Icons.science_outlined,
      Lane.buy => Icons.shopping_cart_outlined,
      Lane.reference => Icons.description_outlined,
    };
    return DragTarget<Lane>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (_) => setState(() => _lane = lane),
      builder: (context, _, __) {
        return Material(
          color: selected ? yellow : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => setState(() => _lane = lane),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? onYellow : ink),
                const SizedBox(height: 4),
                Text(DockLogic.laneLabel(lane), style: TextStyle(color: selected ? onYellow : ink, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickRemind(BuildContext context) async {
    final now = DateTime.now();
    final choice = await showModalBottomSheet<DateTime?>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('No reminder'), onTap: () => Navigator.pop(sheet, DateTime.fromMillisecondsSinceEpoch(0))),
            ListTile(
              title: Text(DockLogic.remindLabel(DockLogic.laterToday(now), now)),
              onTap: () => Navigator.pop(sheet, DockLogic.laterToday(now)),
            ),
            ListTile(
              title: const Text('Tomorrow, 9:00'),
              onTap: () => Navigator.pop(sheet, DockLogic.tomorrowMorning(now)),
            ),
            ListTile(
              title: Text(DockLogic.remindLabel(DockLogic.nextWeekend(now), now)),
              onTap: () => Navigator.pop(sheet, DockLogic.nextWeekend(now)),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    setState(() {
      _remind = choice.millisecondsSinceEpoch == 0 ? null : choice;
    });
  }

  Future<void> _openFile(DockItem item) async {
    final path = item.filePath;
    if (path == null || !File(path).existsSync()) {
      AppToast.show(context, title: 'This sample has no file on the device');
      return;
    }
    await Share.shareXFiles([XFile(path)]);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url.contains('://') ? url : 'https://$url');
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) AppToast.show(context, title: 'Could not open that link');
    }
  }
}

class _StackCard extends StatelessWidget {
  final DockItem item;

  const _StackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    final card = Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: Draggable<Lane>(
        data: item.lane ?? Lane.tryOut,
        feedback: const SizedBox(width: 180, height: 80, child: Material(child: Center(child: Text('Move')))),
        childWhenDragging: Opacity(opacity: 0.4, child: _body(ink, muted)),
        child: _body(ink, muted),
      ),
    );
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Positioned(right: 16, top: 16, left: 32, child: _back(context, 0.4)),
          Positioned(right: 8, top: 8, left: 16, child: _back(context, 0.7)),
          Positioned.fill(child: card),
        ],
      ),
    );
  }

  Widget _back(BuildContext context, double opacity) {
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: const SizedBox(height: 180),
      ),
    );
  }

  Widget _body(Color ink, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: item.kind == SaveKind.file
                ? const FieldArt()
                : item.kind == SaveKind.link
                    ? const ChairArt()
                    : const ColoredBox(color: Color(0xFF222222)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_kicker(item), style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800)),
              Text(item.title, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 18)),
              if (item.host.isNotEmpty) Text(item.host, style: TextStyle(color: muted)),
            ],
          ),
        ),
      ],
    );
  }
}

String _kicker(DockItem item) {
  final lane = item.lane == null ? 'UNSORTED' : DockLogic.laneLabel(item.lane!).toUpperCase();
  return '${item.kindLabel} · $lane';
}
