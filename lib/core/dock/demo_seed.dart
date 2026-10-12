import 'dock_logic.dart';

class DemoSeed {
  DemoSeed._();

  static const collectionId = 'weekend';
  static const itemIds = {'chair', 'field', 'quote', 'shoes', 'sunday', 'lamp', 'desk'};

  static List<DockCollection> collections() => [
        DockCollection(id: collectionId, name: 'Weekend reset', tag: 'PERSONAL'),
      ];

  static List<DockItem> items(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, 18);
    final tomorrow = DockLogic.tomorrowMorning(now);
    return [
      DockItem(
        id: 'chair',
        title: 'Build a better reading corner',
        body: 'Use what you already own.',
        url: 'https://studio.example/reading-corner',
        kind: SaveKind.link,
        lane: Lane.tryOut,
        collectionId: collectionId,
        remindAt: tomorrow,
      ),
      DockItem(
        id: 'field',
        title: 'Weekend field guide',
        body: 'A short PDF to keep with the trip notes.',
        kind: SaveKind.file,
        lane: Lane.reference,
        fileName: 'field-notes.pdf',
        pages: 12,
      ),
      DockItem(
        id: 'quote',
        title: 'Less collecting. More doing.',
        body: 'A note to reread before saving another link.',
        kind: SaveKind.note,
        lane: Lane.read,
      ),
      DockItem(
        id: 'shoes',
        title: 'Everyday walking shoes',
        url: 'https://store.example/walking-shoes',
        kind: SaveKind.link,
        lane: Lane.buy,
        remindAt: today,
      ),
      DockItem(
        id: 'sunday',
        title: 'A quieter Sunday',
        body: 'Leave the morning empty and read one thing.',
        kind: SaveKind.note,
        lane: Lane.read,
        collectionId: collectionId,
      ),
      DockItem(
        id: 'lamp',
        title: 'Raise the reading lamp',
        body: 'Try it for one evening before buying anything.',
        url: 'https://studio.example/lamp-height',
        kind: SaveKind.link,
        lane: Lane.tryOut,
      ),
      DockItem(
        id: 'desk',
        title: 'Clear the desk',
        body: 'Only the book and the lamp stay.',
        kind: SaveKind.note,
        lane: Lane.tryOut,
        collectionId: collectionId,
        done: true,
      ),
    ];
  }
}
