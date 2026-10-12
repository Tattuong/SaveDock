import 'dart:convert';

enum Lane { read, tryOut, buy, reference }

enum SaveKind { link, note, file }

enum SaveResult { added, duplicate, full }

class DockCollection {
  final String id;
  String name;
  String tag;

  DockCollection({required this.id, required this.name, this.tag = ''});

  DockCollection copy() => DockCollection(id: id, name: name, tag: tag);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'tag': tag};

  factory DockCollection.fromJson(Map<String, dynamic> json) => DockCollection(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
      );
}

class DockItem {
  final String id;
  String title;
  String body;
  String url;
  SaveKind kind;
  Lane? lane;
  String? collectionId;
  DateTime? remindAt;
  bool done;
  String? filePath;
  String? fileName;
  int? pages;
  DateTime createdAt;

  DockItem({
    required this.id,
    required this.title,
    this.body = '',
    this.url = '',
    required this.kind,
    this.lane,
    this.collectionId,
    this.remindAt,
    this.done = false,
    this.filePath,
    this.fileName,
    this.pages,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DockItem copy() => DockItem(
        id: id,
        title: title,
        body: body,
        url: url,
        kind: kind,
        lane: lane,
        collectionId: collectionId,
        remindAt: remindAt,
        done: done,
        filePath: filePath,
        fileName: fileName,
        pages: pages,
        createdAt: createdAt,
      );

  String get host => DockLogic.hostOf(url);

  String get kindLabel {
    final name = (fileName ?? '').toLowerCase();
    if (kind == SaveKind.file && name.endsWith('.pdf')) return 'PDF';
    return switch (kind) {
      SaveKind.link => 'LINK',
      SaveKind.note => 'NOTE',
      SaveKind.file => 'FILE',
    };
  }

  String get meta {
    if (kind == SaveKind.file && pages != null) return '$kindLabel · $pages PAGES';
    if (host.isNotEmpty) return host;
    return kindLabel;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'url': url,
        'kind': kind.name,
        'lane': lane?.name,
        'collectionId': collectionId,
        'remindAt': remindAt?.toIso8601String(),
        'done': done,
        'filePath': filePath,
        'fileName': fileName,
        'pages': pages,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DockItem.fromJson(Map<String, dynamic> json) => DockItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        url: json['url'] as String? ?? '',
        kind: SaveKind.values.byName(json['kind'] as String? ?? 'note'),
        lane: json['lane'] == null ? null : Lane.values.byName(json['lane'] as String),
        collectionId: json['collectionId'] as String?,
        remindAt: json['remindAt'] == null
            ? null
            : DateTime.tryParse(json['remindAt'] as String),
        done: json['done'] == true,
        filePath: json['filePath'] as String?,
        fileName: json['fileName'] as String?,
        pages: (json['pages'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class DockLogic {
  DockLogic._();

  static const laneOrder = [Lane.read, Lane.tryOut, Lane.buy, Lane.reference];

  static String laneLabel(Lane lane) => switch (lane) {
        Lane.read => 'Read',
        Lane.tryOut => 'Try',
        Lane.buy => 'Buy',
        Lane.reference => 'Reference',
      };

  static String laneShort(Lane lane) => switch (lane) {
        Lane.read => 'Read',
        Lane.tryOut => 'Try',
        Lane.buy => 'Buy',
        Lane.reference => 'Ref',
      };

  static String hostOf(String raw) {
    final uri = _uri(raw);
    if (uri == null || uri.host.isEmpty) return '';
    final host = uri.host.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static String normalizeUrl(String raw) {
    final uri = _uri(raw.trim());
    if (uri == null || uri.host.isEmpty) return raw.trim().toLowerCase();
    var path = uri.path;
    if (path.length > 1 && path.endsWith('/')) path = path.substring(0, path.length - 1);
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '${uri.scheme.toLowerCase()}://${uri.host.toLowerCase()}$path$query';
  }

  static Uri? _uri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    return Uri.tryParse(withScheme);
  }

  static bool looksLikeLink(String raw) {
    final uri = _uri(raw);
    return uri != null && uri.host.contains('.');
  }

  static List<DockItem> openItems(List<DockItem> items) =>
      [for (final item in items) if (!item.done) item];

  static int countLane(List<DockItem> items, Lane lane) =>
      openItems(items).where((item) => item.lane == lane).length;

  static List<DockItem> filterLane(List<DockItem> items, Lane? lane) {
    final open = openItems(items);
    if (lane == null) return open;
    return [for (final item in open) if (item.lane == lane) item];
  }

  static List<DockItem> inCollection(List<DockItem> items, String? collectionId) => [
        for (final item in items)
          if (item.collectionId == collectionId) item,
      ];

  static int doneCount(List<DockItem> items) => items.where((item) => item.done).length;

  static List<DockItem> remindersOn(List<DockItem> items, DateTime day) => [
        for (final item in openItems(items))
          if (item.remindAt != null && sameDay(item.remindAt!, day)) item,
      ];

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String remindLabel(DateTime? at, DateTime now) {
    if (at == null) return 'Remind me';
    final clock = _clock(at);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (sameDay(at, now)) return 'Today, $clock';
    if (sameDay(at, tomorrow)) return 'Tomorrow, $clock';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[at.month - 1]} ${at.day}, $clock';
  }

  static String _clock(DateTime at) =>
      '${at.hour}:${at.minute.toString().padLeft(2, '0')}';

  static DateTime tomorrowMorning(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1, 9);

  static DateTime laterToday(DateTime now) {
    final later = now.add(const Duration(hours: 4));
    if (!sameDay(later, now)) return DateTime(now.year, now.month, now.day, 21);
    return DateTime(later.year, later.month, later.day, later.hour, later.minute);
  }

  static DateTime nextWeekend(DateTime now) {
    var day = DateTime(now.year, now.month, now.day + 1);
    while (day.weekday != DateTime.saturday) {
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return DateTime(day.year, day.month, day.day, 10);
  }

  static DockItem? duplicateLink(List<DockItem> items, String url) {
    final key = normalizeUrl(url);
    if (key.isEmpty) return null;
    for (final item in items) {
      if (item.done || item.kind != SaveKind.link || item.url.isEmpty) continue;
      if (normalizeUrl(item.url) == key) return item;
    }
    return null;
  }

  static List<DockItem> search(List<DockItem> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return [
      for (final item in items)
        if (_haystack(item).contains(q)) item,
    ];
  }

  static String _haystack(DockItem item) {
    final lane = item.lane == null ? 'unsorted' : '${laneLabel(item.lane!).toLowerCase()} ${laneShort(item.lane!).toLowerCase()}';
    return '${item.title} ${item.body} ${item.url} ${item.host} ${item.kind.name} ${item.kindLabel} ${item.fileName ?? ''} $lane'
        .toLowerCase();
  }

  static String exportJson({
    required List<DockCollection> collections,
    required List<DockItem> items,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'SaveDock',
      'exportedAt': DateTime.now().toIso8601String(),
      'collections': [for (final collection in collections) collection.toJson()],
      'items': [for (final item in items) item.toJson()],
    });
  }

  static String titleFromLink(String url) {
    final host = hostOf(url);
    return host.isEmpty ? 'Saved link' : host;
  }

  static String titleFromFile(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return name;
    return name.substring(0, dot);
  }
}
