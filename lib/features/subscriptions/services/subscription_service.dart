import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';

/// Subscription state model.
class SubscriptionStatus {
  final bool isProActive;
  final String? activePlanName;
  final DateTime? expirationDate;
  final bool isTrial;

  const SubscriptionStatus({
    required this.isProActive,
    this.activePlanName,
    this.expirationDate,
    this.isTrial = false,
  });
}

/// Service managing RevenueCat in-app subscriptions and Google Play Billing.
class SubscriptionService {
  static bool _isInitialized = false;
  static bool _isConfigured = false;

  /// Initializes RevenueCat SDK.
  /// If [apiKey] is empty, gracefully marks as unconfigured without crashing.
  static Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;

    final key = apiKey ?? '';
    if (key.isEmpty) {
      debugPrint('[SubscriptionService] RevenueCat API key is not configured. Running in unconfigured store mode.');
      _isInitialized = true;
      _isConfigured = false;
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await Purchases.configure(PurchasesConfiguration(key));
        _isConfigured = true;
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[SubscriptionService] Initialization failed: $e');
      _isInitialized = true;
      _isConfigured = false;
    }
  }

  /// Checks current entitlement status.
  static Future<SubscriptionStatus> getSubscriptionStatus() async {
    if (!_isConfigured) {
      return const SubscriptionStatus(isProActive: false);
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[AppConstants.entitlementPro];

      if (entitlement != null && entitlement.isActive) {
        return SubscriptionStatus(
          isProActive: true,
          activePlanName: entitlement.productIdentifier,
          expirationDate: entitlement.expirationDate != null
              ? DateTime.tryParse(entitlement.expirationDate!)
              : null,
          isTrial: entitlement.periodType == PeriodType.trial,
        );
      }
      return const SubscriptionStatus(isProActive: false);
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to fetch customer info: $e');
      return const SubscriptionStatus(isProActive: false);
    }
  }

  /// Restores previous in-app purchases.
  static Future<SubscriptionStatus> restorePurchases() async {
    if (!_isConfigured) {
      throw const SubscriptionException(
        'Store is not configured with an active RevenueCat API key.',
        code: 'STORE_NOT_CONFIGURED',
      );
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      final entitlement = customerInfo.entitlements.all[AppConstants.entitlementPro];
      final isActive = entitlement != null && entitlement.isActive;

      return SubscriptionStatus(
        isProActive: isActive,
        activePlanName: entitlement?.productIdentifier,
        expirationDate: entitlement?.expirationDate != null
            ? DateTime.tryParse(entitlement!.expirationDate!)
            : null,
      );
    } catch (e) {
      throw SubscriptionException('Failed to restore purchases: $e', details: e);
    }
  }

  /// Purchases a subscription package (weekly or yearly).
  static Future<SubscriptionStatus> purchaseSubscription({required bool isYearly}) async {
    if (!_isConfigured) {
      throw const SubscriptionException(
        'In-app purchases require configuring the RevenueCat API key in settings or backend.',
        code: 'STORE_NOT_CONFIGURED',
      );
    }

    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) {
        throw const SubscriptionException(
          'No subscription offerings currently available in Google Play Console.',
          code: 'NO_OFFERINGS',
        );
      }

      final package = isYearly ? currentOffering.annual : currentOffering.weekly;
      if (package == null) {
        throw SubscriptionException(
          '${isYearly ? "Yearly" : "Weekly"} subscription package not found.',
          code: 'PACKAGE_NOT_FOUND',
        );
      }

      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = purchaseResult.customerInfo;
      final entitlement = customerInfo.entitlements.all[AppConstants.entitlementPro];
      final isActive = entitlement != null && entitlement.isActive;

      return SubscriptionStatus(
        isProActive: isActive,
        activePlanName: entitlement?.productIdentifier,
      );
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      throw SubscriptionException('Purchase could not be completed: $e', details: e);
    }
  }
}
