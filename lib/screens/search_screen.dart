import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/dock/dock_logic.dart';
import '../providers/dock_provider.dart';
import 'sort_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  var _leaving = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _close() {
    if (_leaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dock = context.watch<DockProvider>();
    final found = DockLogic.search(dock.items, _query.text);
    final ink = AppColors.inkOf(context);
    final muted = AppColors.secondaryInk(context);
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvasOf(context),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: _close,
                        icon: Icon(Icons.arrow_back, color: ink)),
                    Expanded(
                      child: TextField(
                        controller: _query,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Name, note, site, or type',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Text('${found.length} found',
                        style: TextStyle(
                            color: muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final item in found)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title,
                            style: TextStyle(
                                color: ink, fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          '${item.kindLabel} · ${item.lane == null ? 'Unsorted' : DockLogic.laneLabel(item.lane!)}'
                          '${item.host.isEmpty ? '' : ' · ${item.host}'}',
                          style: TextStyle(color: muted),
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => SortScreen(itemId: item.id)));
                        },
                      ),
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
