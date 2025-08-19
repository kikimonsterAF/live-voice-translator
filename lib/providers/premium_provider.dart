import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumProvider extends ChangeNotifier {
  static const String removeAdsId = 'remove_ads';
  static const String _prefsKey = 'is_premium_v1';

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _sub;

  bool _available = false;
  bool _isPremium = false;
  bool _isLoading = true;
  List<ProductDetails> _products = [];

  bool get isAvailable => _available;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // persisted flag
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_prefsKey) ?? false;

    _available = await _iap.isAvailable();
    if (_available) {
      _sub = _iap.purchaseStream.listen(_onPurchases, onDone: () {
        _sub.cancel();
      }, onError: (_) {});

      await _queryProducts();
      await _restore();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _queryProducts() async {
    const ids = {removeAdsId};
    final response = await _iap.queryProductDetails(ids);
    _products = response.productDetails;
    notifyListeners();
  }

  Future<void> buyRemoveAds() async {
    final product = _products.firstWhere((p) => p.id == removeAdsId, orElse: () => throw Exception('Product not found'));
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _restore();

  Future<void> _restore() async {
    final resp = await _iap.queryPastPurchases();
    _onPurchases(resp.pastPurchases);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    bool premium = _isPremium;
    for (final p in purchases) {
      if (p.productID == removeAdsId) {
        premium = true;
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
      }
    }
    if (premium != _isPremium) {
      _isPremium = premium;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isPremium);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try { _sub.cancel(); } catch (_) {}
    super.dispose();
  }
}


