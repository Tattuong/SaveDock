import 'package:flutter_test/flutter_test.dart';
import 'package:savedock/core/dock/demo_seed.dart';
import 'package:savedock/core/dock/dock_logic.dart';

void main() {
  test('demo dock matches the six open lanes', () {
    final now = DateTime(2026, 10, 9, 15);
    final items = DemoSeed.items(now);
    expect(DockLogic.openItems(items), hasLength(6));
    expect(DockLogic.countLane(items, Lane.read), 2);
    expect(DockLogic.countLane(items, Lane.tryOut), 2);
    expect(DockLogic.countLane(items, Lane.buy), 1);
    expect(DockLogic.countLane(items, Lane.reference), 1);
    final weekend = DockLogic.inCollection(items, DemoSeed.collectionId);
    expect(weekend, hasLength(3));
    expect(DockLogic.doneCount(weekend), 1);
    expect(DockLogic.remindersOn(items, now), hasLength(1));
    expect(DockLogic.remindLabel(items.first.remindAt, now), 'Tomorrow, 9:00');
  });

  test('duplicate links and search use the site and the lane', () {
    final items = DemoSeed.items(DateTime(2026, 10, 9));
    expect(DockLogic.duplicateLink(items, 'https://studio.example/reading-corner/'), isNotNull);
    expect(DockLogic.duplicateLink(items, 'https://other.example'), isNull);
    expect(DockLogic.hostOf('https://www.store.example/shoes'), 'store.example');
    final found = DockLogic.search(items, 'pdf');
    expect(found.single.title, 'Weekend field guide');
    expect(DockLogic.search(items, 'sunday').single.lane, Lane.read);
    final exported = DockLogic.exportJson(collections: DemoSeed.collections(), items: items);
    expect(exported, contains('SaveDock'));
    expect(exported, contains('Weekend reset'));
  });
}
