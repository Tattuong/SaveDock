import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/share_inbox.dart';
import '../providers/dock_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import 'collections_screen.dart';
import 'dock_screen.dart';
import 'save_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    ShareInbox.listen((pieces) async {
      if (!mounted || pieces.isEmpty) return;
      final dock = context.read<DockProvider>();
      final pro = context.read<ShopProvider>().hasPro;
      await dock.takeShares(pieces, pro: pro);
      if (!mounted || dock.notice == null) return;
      AppToast.show(context, title: dock.notice!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasOf(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _tab == 0 ? const DockScreen() : const CollectionsScreen()),
            const AdBannerSlot(),
            _Bar(
              index: _tab,
              onChanged: (value) => setState(() => _tab = value),
              onSave: () => showSaveSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onSave;

  const _Bar({required this.index, required this.onChanged, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final yellow = AppColors.primaryOf(context);
    final ink = AppColors.onPrimaryOf(context);
    final muted = AppColors.mutedInk(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.canvasOf(context),
        border: Border(top: BorderSide(color: AppColors.borderOf(context))),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _tab(0, Icons.menu_book_outlined, 'Dock', yellow, muted),
            _tab(1, Icons.folder_outlined, 'Collections', yellow, muted),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Material(
                color: yellow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onSave,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 92,
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: ink, size: 18),
                        const SizedBox(width: 4),
                        Text('Save', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(int value, IconData icon, String label, Color active, Color muted) {
    final selected = index == value;
    final color = selected ? active : muted;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? active : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
