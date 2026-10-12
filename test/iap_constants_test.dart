import 'package:flutter_test/flutter_test.dart';
import 'package:savedock/core/constants/iap_constants.dart';
import 'package:savedock/core/services/iap_config_service.dart';
import 'package:savedock/models/shop_item.dart';

void main() {
  test('SaveDock IAP ids and N315 endpoint', () {
    expect(IapConstants.productPrefix, 'sd');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N315.json');
    expect(IapConstants.coinPackIds.first, 'sd_pack_1');
    expect(IapConstants.coinPackIds.last, 'sd_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'sd_remove_ads');
    expect(IapConstants.proProductId, 'sd_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'sd_remove_ads', 'sd_pro']));
    expect(IapConstants.coinsForProduct('sd_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'SaveDock'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'SaveDock', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'SaveDock');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
