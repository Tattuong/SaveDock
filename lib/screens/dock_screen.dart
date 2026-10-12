import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/dock/dock_logic.dart';
import '../providers/dock_provider.dart';
import '../widgets/coin_balance_chip.dart';
import '../widgets/dock_art.dart';
import 'search_screen.dart';
import 'sort_screen.dart';

class DockScreen extends StatefulWidget {
  const DockScreen({super.key});

  @override
  State<DockScreen> createState() => _DockScreenState();
}

class _DockScreenState extends State<DockScreen> {
  Lane? _lane;

  @override
  Widget build(BuildContext context) {
    final dock = context.watch<DockProvider>();
    final open = dock.open;
    final shown = DockLogic.filterLane(dock.items, _lane);
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    final yellow = AppColors.primaryOf(context);
    final count = open.length.toString().padLeft(2, '0');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Row(
          children: [
            Icon(Icons.folder_outlined, color: ink, size: 22),
            const SizedBox(width: 8),
            Text('savedock', style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 18)),
            const Spacer(),
            const CoinBalanceChip(variant: CoinChipVariant.header),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
              },
              icon: Icon(Icons.search, color: ink),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Your next\ngood idea.', style: TextStyle(color: ink, fontSize: 40, height: 0.95, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Text('$count ITEMS IN YOUR DOCK', style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.6)),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(null, 'All', open.length, yellow, muted, ink),
              for (final lane in DockLogic.laneOrder)
                _chip(lane, DockLogic.laneShort(lane), DockLogic.countLane(dock.items, lane), yellow, muted, ink),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Text(
              'Nothing here yet. Share a link, or tap Save.',
              style: TextStyle(color: muted),
            ),
          ),
        ..._tiles(shown),
        if (dock.remindersToday(DateTime.now()) > 0) ...[
          const SizedBox(height: 4),
          _ReminderRow(count: dock.remindersToday(DateTime.now())),
        ],
      ],
    );
  }

  Widget _chip(Lane? lane, String label, int count, Color yellow, Color muted, Color ink) {
    final selected = _lane == lane;
    final color = selected ? yellow : muted;
    final n = count.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () => setState(() => _lane = lane),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label $n', style: TextStyle(color: selected ? ink : color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Container(height: 2, width: 36, color: selected ? yellow : Colors.transparent),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final int count;

  const _ReminderRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final dock = context.read<DockProvider>();
    final due = DockLogic.remindersOn(dock.items, DateTime.now());
    final ink = AppColors.inkOf(context);
    final label = count == 1 ? '1 reminder today' : '$count reminders today';
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(Icons.schedule, color: ink, size: 20),
        title: Text(label, style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
        trailing: Icon(Icons.chevron_right, color: AppColors.secondaryInk(context)),
        onTap: due.isEmpty
            ? null
            : () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: AppColors.surfaceOf(context),
                  showDragHandle: true,
                  builder: (sheet) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in due)
                          ListTile(
                            title: Text(item.title),
                            subtitle: Text(DockLogic.remindLabel(item.remindAt, DateTime.now())),
                            onTap: () {
                              Navigator.pop(sheet);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SortScreen(itemId: item.id)),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
      ),
    );
  }
}

class _DismissCard extends StatelessWidget {
  final DockItem item;
  final _Fit fit;

  const _DismissCard({required this.item, this.fit = _Fit.row});

  @override
  Widget build(BuildContext context) {
    final yellow = AppColors.primaryOf(context);
    final onYellow = AppColors.onPrimaryOf(context);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(18)),
        child: Text('Done', style: TextStyle(color: onYellow, fontWeight: FontWeight.w800)),
      ),
      onDismissed: (_) {
        context.read<DockProvider>().markDone(item.id);
        AppMessenger.done(context, item.id, item.title);
      },
      child: _DockCard(item: item, fit: fit),
    );
  }
}

class AppMessenger {
  static void done(BuildContext context, String id, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title marked done'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => context.read<DockProvider>().markDone(id, done: false),
        ),
      ),
    );
  }
}

enum _Fit { hero, tile, row }

List<Widget> _tiles(List<DockItem> shown) {
  final out = <Widget>[];
  var i = 0;
  while (i < shown.length) {
    final item = shown[i];
    final hero = item.kind == SaveKind.link && item.lane != Lane.buy;
    if (hero) {
      final side = <DockItem>[];
      var j = i + 1;
      while (j < shown.length && side.length < 2 && _isSide(shown[j])) {
        side.add(shown[j]);
        j++;
      }
      if (side.isNotEmpty) {
        out.add(_Mosaic(hero: item, side: side));
        out.add(const SizedBox(height: 12));
        i = j;
        continue;
      }
    }
    out.add(_DismissCard(item: item));
    out.add(const SizedBox(height: 12));
    i++;
  }
  return out;
}

bool _isSide(DockItem item) => item.kind == SaveKind.file || item.kind == SaveKind.note;

class _Mosaic extends StatelessWidget {
  final DockItem hero;
  final List<DockItem> side;

  const _Mosaic({required this.hero, required this.side});

  @override
  Widget build(BuildContext context) {
    const height = 292.0;
    final tile = side.length == 1 ? height : (height - 10) / 2;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _DismissCard(item: hero, fit: _Fit.hero)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < side.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  SizedBox(height: tile, child: _DismissCard(item: side[i], fit: _Fit.tile)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DockCard extends StatelessWidget {
  final DockItem item;
  final _Fit fit;

  const _DockCard({required this.item, this.fit = _Fit.row});

  @override
  Widget build(BuildContext context) {
    void open() {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SortScreen(itemId: item.id)));
    }

    if (item.kind == SaveKind.file) return _FileCard(item: item, onTap: open, fit: fit);
    if (item.kind == SaveKind.note) return _NoteCard(item: item, onTap: open, fit: fit);
    if (item.lane == Lane.buy) return _BuyCard(item: item, onTap: open);
    if (fit == _Fit.row) return _LinkRow(item: item, onTap: open);
    return _LinkCard(item: item, onTap: open);
  }
}

class _LinkCard extends StatelessWidget {
  final DockItem item;
  final VoidCallback onTap;

  const _LinkCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 292,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(width: double.infinity, child: ChairArt()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_kicker(item), style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 18))),
                      Icon(Icons.open_in_new, size: 16, color: muted),
                    ],
                  ),
                  if (item.host.isNotEmpty) Text(item.host, style: TextStyle(color: muted, fontSize: 13)),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final DockItem item;
  final VoidCallback onTap;
  final _Fit fit;

  const _FileCard({required this.item, required this.onTap, required this.fit});

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: fit == _Fit.tile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(18)), child: FieldArt())),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.meta, style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800)),
                        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              )
            : SizedBox(
                height: 148,
                child: Row(
                  children: [
                    const Expanded(child: ClipRRect(borderRadius: BorderRadius.horizontal(left: Radius.circular(18)), child: FieldArt())),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.meta, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Text(item.title, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final DockItem item;
  final VoidCallback onTap;
  final _Fit fit;

  const _NoteCard({required this.item, required this.onTap, required this.fit});

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('“', style: TextStyle(color: ink, fontSize: 28, height: 0.8, fontWeight: FontWeight.w800)),
              Text(
                item.title,
                maxLines: fit == _Fit.tile ? 3 : 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: fit == _Fit.tile ? 16 : 20, height: 1.15),
              ),
              const SizedBox(height: 10),
              Text('${item.kindLabel} · ${item.lane == null ? 'UNSORTED' : DockLogic.laneLabel(item.lane!).toUpperCase()}',
                  style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final DockItem item;
  final VoidCallback onTap;

  const _LinkRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        onTap: onTap,
        title: Text(item.title, style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
        subtitle: Text(_kicker(item), style: TextStyle(color: muted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: muted),
      ),
    );
  }
}

class _BuyCard extends StatelessWidget {
  final DockItem item;
  final VoidCallback onTap;

  const _BuyCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    final yellow = AppColors.primaryOf(context);
    final onYellow = AppColors.onPrimaryOf(context);
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const ShoeMark(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
                    if (item.host.isNotEmpty) Text(item.host, style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(8)),
                child: Text('BUY', style: TextStyle(color: onYellow, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

String _kicker(DockItem item) {
  final lane = item.lane == null ? 'UNSORTED' : DockLogic.laneLabel(item.lane!).toUpperCase();
  return '${item.kindLabel} · $lane';
}
