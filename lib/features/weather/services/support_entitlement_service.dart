import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeatherSupportTier {
  none,
  coffee,
  supercharge,
  patron;

  String? get productId => switch (this) {
    WeatherSupportTier.none => null,
    WeatherSupportTier.coffee => 'weatheros_coffee_unlock',
    WeatherSupportTier.supercharge => 'weatheros_supercharge_unlock',
    WeatherSupportTier.patron => 'weatheros_patron_unlock',
  };

  String? get tipProductId => switch (this) {
    WeatherSupportTier.none => null,
    WeatherSupportTier.coffee => 'weatheros_coffee_tip',
    WeatherSupportTier.supercharge => 'weatheros_supercharge_tip',
    WeatherSupportTier.patron => 'weatheros_patron_tip',
  };

  String get label => switch (this) {
    WeatherSupportTier.none => 'Explorer',
    WeatherSupportTier.coffee => 'Coffee',
    WeatherSupportTier.supercharge => 'Supercharge',
    WeatherSupportTier.patron => 'Patron',
  };

  String get emoji => switch (this) {
    WeatherSupportTier.none => '◌',
    WeatherSupportTier.coffee => '☕',
    WeatherSupportTier.supercharge => '⚡',
    WeatherSupportTier.patron => '👑',
  };

  String get fallbackPrice => switch (this) {
    WeatherSupportTier.none => '',
    WeatherSupportTier.coffee => r'$1.99',
    WeatherSupportTier.supercharge => r'$4.99',
    WeatherSupportTier.patron => r'$9.99',
  };

  String get unlockSummary => switch (this) {
    WeatherSupportTier.none => 'Core WeatherOS experience',
    WeatherSupportTier.coffee =>
      'Atmosphere personalization + supporter insignia',
    WeatherSupportTier.supercharge =>
      'Coffee perks + advanced forecast tooling',
    WeatherSupportTier.patron => 'Every unlock + experimental WeatherOS Labs',
  };

  bool includes(WeatherSupportTier tier) => index >= tier.index;

  static WeatherSupportTier fromProductId(String productId) {
    return WeatherSupportTier.values.firstWhere(
      (WeatherSupportTier tier) =>
          tier.productId == productId || tier.tipProductId == productId,
      orElse: () => WeatherSupportTier.none,
    );
  }

  static bool isTipProduct(String productId) {
    return WeatherSupportTier.values.any(
      (WeatherSupportTier tier) => tier.tipProductId == productId,
    );
  }
}

enum SupportStoreState { idle, loading, ready, unavailable, error }

enum SupportPurchaseNoticeType {
  purchased,
  tipped,
  restored,
  pending,
  canceled,
  error,
}

class SupportPurchaseNotice {
  const SupportPurchaseNotice({
    required this.type,
    this.tier = WeatherSupportTier.none,
    this.message,
  });

  final SupportPurchaseNoticeType type;
  final WeatherSupportTier tier;
  final String? message;
}

class SupportEntitlementService extends ChangeNotifier {
  SupportEntitlementService._();

  static final SupportEntitlementService instance =
      SupportEntitlementService._();
  static const String _storedTierKey = 'weatheros_support_tier_v1';

  final InAppPurchase _store = InAppPurchase.instance;
  final StreamController<SupportPurchaseNotice> _notices =
      StreamController<SupportPurchaseNotice>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Map<String, ProductDetails> _products = const <String, ProductDetails>{};
  SupportStoreState _storeState = SupportStoreState.idle;
  WeatherSupportTier _entitlement = WeatherSupportTier.none;
  String? _errorMessage;
  String? _activeProductId;
  bool _initialized = false;

  Stream<SupportPurchaseNotice> get notices => _notices.stream;
  SupportStoreState get storeState => _storeState;
  WeatherSupportTier get entitlement => _entitlement;
  String? get errorMessage => _errorMessage;
  bool get isAndroidStorefront =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isBusy => _activeProductId != null;

  bool owns(WeatherSupportTier tier) => _entitlement.includes(tier);

  ProductDetails? productFor(
    WeatherSupportTier tier, {
    bool repeatTip = false,
  }) {
    final productId = repeatTip ? tier.tipProductId : tier.productId;
    return productId == null ? null : _products[productId];
  }

  String priceFor(WeatherSupportTier tier) {
    return productFor(tier)?.price ?? tier.fallbackPrice;
  }

  String tipPriceFor(WeatherSupportTier tier) {
    return productFor(tier, repeatTip: true)?.price ?? tier.fallbackPrice;
  }

  bool canPurchase(WeatherSupportTier tier) {
    return isAndroidStorefront &&
        _storeState == SupportStoreState.ready &&
        !isBusy &&
        !owns(tier) &&
        productFor(tier) != null;
  }

  bool canTip(WeatherSupportTier tier) {
    return isAndroidStorefront &&
        _storeState == SupportStoreState.ready &&
        !isBusy &&
        _entitlement != WeatherSupportTier.none &&
        productFor(tier, repeatTip: true) != null;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _storeState = SupportStoreState.loading;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    final storedTierIndex = preferences.getInt(_storedTierKey) ?? 0;
    if (storedTierIndex >= 0 &&
        storedTierIndex < WeatherSupportTier.values.length) {
      _entitlement = WeatherSupportTier.values[storedTierIndex];
    }

    if (!isAndroidStorefront) {
      _storeState = SupportStoreState.unavailable;
      notifyListeners();
      return;
    }

    _purchaseSubscription ??= _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _activeProductId = null;
        _errorMessage = 'Google Play Billing connection failed.';
        _storeState = SupportStoreState.error;
        _notices.add(
          SupportPurchaseNotice(
            type: SupportPurchaseNoticeType.error,
            message: _errorMessage,
          ),
        );
        notifyListeners();
      },
    );

    try {
      if (!await _store.isAvailable()) {
        _storeState = SupportStoreState.unavailable;
        notifyListeners();
        return;
      }

      final productIds = WeatherSupportTier.values
          .expand(
            (WeatherSupportTier tier) => <String?>[
              tier.productId,
              tier.tipProductId,
            ],
          )
          .whereType<String>()
          .toSet();
      final response = await _store.queryProductDetails(productIds);
      _products = <String, ProductDetails>{
        for (final ProductDetails product in response.productDetails)
          product.id: product,
      };

      if (response.error != null) {
        _errorMessage = response.error!.message;
      } else if (_products.isEmpty) {
        _errorMessage = 'Support unlocks are not active in Google Play yet.';
      }
      _storeState = _products.isEmpty
          ? SupportStoreState.unavailable
          : SupportStoreState.ready;
      notifyListeners();

      await _store.restorePurchases();
    } catch (_) {
      _errorMessage = 'Support unlocks could not be loaded from Google Play.';
      _storeState = SupportStoreState.error;
      notifyListeners();
    }
  }

  Future<void> purchase(
    WeatherSupportTier tier, {
    bool repeatTip = false,
  }) async {
    final product = productFor(tier, repeatTip: repeatTip);
    final allowed = repeatTip ? canTip(tier) : canPurchase(tier);
    if (product == null || !allowed) return;

    _activeProductId = product.id;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final launched = repeatTip
          ? await _store.buyConsumable(purchaseParam: purchaseParam)
          : await _store.buyNonConsumable(purchaseParam: purchaseParam);
      if (!launched) {
        _activeProductId = null;
        _notices.add(
          const SupportPurchaseNotice(
            type: SupportPurchaseNoticeType.error,
            message: 'Google Play could not start the purchase.',
          ),
        );
        notifyListeners();
      }
    } catch (_) {
      _activeProductId = null;
      _notices.add(
        const SupportPurchaseNotice(
          type: SupportPurchaseNoticeType.error,
          message: 'Google Play could not start the purchase.',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      final tier = WeatherSupportTier.fromProductId(purchase.productID);
      if (tier == WeatherSupportTier.none) continue;
      final isTip = WeatherSupportTier.isTipProduct(purchase.productID);

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _activeProductId = purchase.productID;
          _notices.add(
            SupportPurchaseNotice(
              type: SupportPurchaseNoticeType.pending,
              tier: tier,
            ),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!isTip) await _grant(tier);
          if (purchase.pendingCompletePurchase) {
            await _store.completePurchase(purchase);
          }
          _activeProductId = null;
          _notices.add(
            SupportPurchaseNotice(
              type: isTip
                  ? SupportPurchaseNoticeType.tipped
                  : purchase.status == PurchaseStatus.restored
                  ? SupportPurchaseNoticeType.restored
                  : SupportPurchaseNoticeType.purchased,
              tier: tier,
            ),
          );
        case PurchaseStatus.canceled:
          _activeProductId = null;
          _notices.add(
            SupportPurchaseNotice(
              type: SupportPurchaseNoticeType.canceled,
              tier: tier,
            ),
          );
        case PurchaseStatus.error:
          _activeProductId = null;
          _notices.add(
            SupportPurchaseNotice(
              type: SupportPurchaseNoticeType.error,
              tier: tier,
              message: purchase.error?.message ?? 'Purchase failed.',
            ),
          );
      }
    }
    notifyListeners();
  }

  Future<void> _grant(WeatherSupportTier tier) async {
    if (_entitlement.includes(tier)) return;
    _entitlement = tier;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_storedTierKey, tier.index);
  }
}
