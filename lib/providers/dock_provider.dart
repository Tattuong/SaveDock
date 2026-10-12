import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/iap_constants.dart';
import '../core/dock/demo_seed.dart';
import '../core/dock/dock_logic.dart';
import '../core/services/hive_service.dart';

class SharedPiece {
  final String? text;
  final String? path;
  final String? mime;

  const SharedPiece({this.text, this.path, this.mime});
}

class DockProvider extends ChangeNotifier {
  static const _key = 'sd_dock';
  static const _seedKey = 'sd_demo_seeded';
  static const _uuid = Uuid();

  List<DockItem> items = [];
  List<DockCollection> collections = [];
  String? notice;

  bool canSave(bool pro) {
    final cap = pro ? IapConstants.proArchiveLimit : IapConstants.freeArchiveLimit;
    return items.length < cap;
  }

  List<DockItem> get open => DockLogic.openItems(items);

  int remindersToday(DateTime now) => DockLogic.remindersOn(items, now).length;

  Future<void> init() async {
    final raw = HiveService.data.get(_key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final itemRaw = map['items'];
        final collectionRaw = map['collections'];
        if (itemRaw is List) {
          items = [
            for (final item in itemRaw)
              if (item is Map) DockItem.fromJson(Map<String, dynamic>.from(item)),
          ];
        }
        if (collectionRaw is List) {
          collections = [
            for (final item in collectionRaw)
              if (item is Map) DockCollection.fromJson(Map<String, dynamic>.from(item)),
          ];
        }
      } catch (_) {
        items = [];
        collections = [];
      }
    }
    final seeded = HiveService.kv.get(_seedKey) == true;
    if (items.isEmpty && collections.isEmpty && !seeded) {
      final now = DateTime.now();
      items = DemoSeed.items(now);
      collections = DemoSeed.collections();
      await HiveService.kv.put(_seedKey, true);
      await _save();
    }
    notifyListeners();
  }

  DockItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  DockCollection? collectionById(String id) {
    for (final collection in collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  SaveResult addLink(
    String url, {
    String? title,
    String? collectionId,
    String body = '',
    required bool pro,
  }) {
    notice = null;
    final trimmed = url.trim();
    if (DockLogic.duplicateLink(items, trimmed) != null) {
      notice = 'Already in your dock';
      notifyListeners();
      return SaveResult.duplicate;
    }
    if (!roomFor(pro)) return SaveResult.full;
    items = [
      DockItem(
        id: _uuid.v4(),
        title: (title ?? '').trim().isEmpty ? DockLogic.titleFromLink(trimmed) : title!.trim(),
        body: body,
        url: trimmed,
        kind: SaveKind.link,
        collectionId: collectionId,
      ),
      ...items,
    ];
    _save();
    notifyListeners();
    return SaveResult.added;
  }

  SaveResult addNote(String title, String body, {String? collectionId, required bool pro}) {
    notice = null;
    if (!roomFor(pro)) return SaveResult.full;
    final name = title.trim().isEmpty ? _firstLine(body) : title.trim();
    items = [
      DockItem(
        id: _uuid.v4(),
        title: name.isEmpty ? 'Note' : name,
        body: body.trim(),
        kind: SaveKind.note,
        collectionId: collectionId,
      ),
      ...items,
    ];
    _save();
    notifyListeners();
    return SaveResult.added;
  }

  Future<SaveResult> addFile(String path, {String? collectionId, required bool pro}) async {
    notice = null;
    if (!roomFor(pro)) return SaveResult.full;
    final name = path.split(Platform.pathSeparator).last;
    final stored = await _copyIn(path, name);
    items = [
      DockItem(
        id: _uuid.v4(),
        title: DockLogic.titleFromFile(name),
        kind: SaveKind.file,
        filePath: stored,
        fileName: name,
        collectionId: collectionId,
      ),
      ...items,
    ];
    await _save();
    notifyListeners();
    return SaveResult.added;
  }

  Future<void> takeShares(List<SharedPiece> pieces, {required bool pro}) async {
    notice = null;
    for (final piece in pieces) {
      final text = (piece.text ?? '').trim();
      final path = (piece.path ?? '').trim();
      if (path.isNotEmpty && await File(path).exists()) {
        final mime = (piece.mime ?? '').toLowerCase();
        if (!mime.startsWith('text')) {
          await addFile(path, pro: pro);
          continue;
        }
      }
      if (text.isEmpty && path.isNotEmpty && !await File(path).exists()) {
        _keepText(path, pro);
        continue;
      }
      if (text.isNotEmpty) _keepText(text, pro);
    }
  }

  void _keepText(String text, bool pro) {
    if (DockLogic.looksLikeLink(text)) {
      addLink(text, pro: pro);
      return;
    }
    addNote('', text, pro: pro);
  }

  void setLane(String id, Lane lane) {
    final item = itemById(id);
    if (item == null) return;
    item.lane = lane;
    _save();
    notifyListeners();
  }

  void setReminder(String id, DateTime? at) {
    final item = itemById(id);
    if (item == null) return;
    item.remindAt = at;
    _save();
    notifyListeners();
  }

  void markDone(String id, {bool done = true}) {
    final item = itemById(id);
    if (item == null) return;
    item.done = done;
    _save();
    notifyListeners();
  }

  void moveToCollection(String id, String? collectionId) {
    final item = itemById(id);
    if (item == null) return;
    item.collectionId = collectionId;
    _save();
    notifyListeners();
  }

  void renameItem(String id, String title) {
    final item = itemById(id);
    final next = title.trim();
    if (item == null || next.isEmpty) return;
    item.title = next;
    _save();
    notifyListeners();
  }

  void deleteItem(String id) {
    items = [for (final item in items) if (item.id != id) item];
    _save();
    notifyListeners();
  }

  void createCollection(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    collections = [
      ...collections,
      DockCollection(id: _uuid.v4(), name: trimmed, tag: 'PERSONAL'),
    ];
    _save();
    notifyListeners();
  }

  void renameCollection(String id, String name) {
    final collection = collectionById(id);
    final next = name.trim();
    if (collection == null || next.isEmpty) return;
    collection.name = next;
    _save();
    notifyListeners();
  }

  void deleteCollection(String id) {
    collections = [for (final collection in collections) if (collection.id != id) collection];
    for (final item in items) {
      if (item.collectionId == id) item.collectionId = null;
    }
    _save();
    notifyListeners();
  }

  String exportAll() => DockLogic.exportJson(collections: collections, items: items);

  String exportCollection(String? collectionId) {
    final owned = DockLogic.inCollection(items, collectionId);
    final cols = [
      for (final collection in collections)
        if (collection.id == collectionId) collection,
    ];
    return DockLogic.exportJson(collections: cols, items: owned);
  }

  bool roomFor(bool pro) {
    if (canSave(pro)) return true;
    notice = pro ? 'Dock is full' : 'Open SaveDock Pro to keep more than 8 saves';
    notifyListeners();
    return false;
  }

  String _firstLine(String body) {
    final line = body.trim().split('\n').first.trim();
    if (line.length <= 48) return line;
    return line.substring(0, 48);
  }

  Future<String> _copyIn(String source, String name) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory('${root.path}/saves');
    if (!await folder.exists()) await folder.create(recursive: true);
    final safe = name.replaceAll(RegExp(r'[\\/]'), '_');
    final dest = File('${folder.path}/${_uuid.v4()}_$safe');
    await File(source).copy(dest.path);
    return dest.path;
  }

  Future<void> _save() async {
    await HiveService.data.put(
      _key,
      jsonEncode({
        'items': [for (final item in items) item.toJson()],
        'collections': [for (final collection in collections) collection.toJson()],
      }),
    );
  }
}
