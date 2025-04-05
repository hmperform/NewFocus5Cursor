# RevenueCat Integration Plan for Focus5

This document outlines the implementation approach for integrating RevenueCat into the Focus5 app to manage subscriptions and in-app purchases, working alongside Firebase.

## 1. Overview

RevenueCat will be used to:
- Manage subscription offerings ($5/month and $50/year plans)
- Handle cross-platform purchases and entitlements
- Track subscription analytics
- Support future "Focus Points" (FP) purchase system
- Synchronize purchase data with Firebase

## 2. Implementation Steps

### 2.1 RevenueCat Setup

1. **Create RevenueCat Account**
   - Sign up at [RevenueCat](https://www.revenuecat.com/)
   - Create a new project for Focus5

2. **Configure App in RevenueCat**
   - Add both iOS and Android apps
   - Configure App Store Connect and Google Play Console credentials
   - Set up webhook endpoints for Firebase integration

3. **Set Up Products**
   - Create "Premium" entitlement
   - Configure products:
     - `focus5_monthly`: $5.00/month subscription
     - `focus5_yearly`: $50.00/year subscription

4. **Configure Offering Structure**
   - Create a "Standard" offering with both subscription options
   - Set the yearly plan as the default highlighted option

### 2.2 Flutter Integration

1. **Add RevenueCat SDK to Flutter Project**
   - Add the package to `pubspec.yaml`:
     ```yaml
     dependencies:
       purchases_flutter: ^5.6.0
     ```

2. **Initialize RevenueCat SDK**
   - In the app initialization code:
     ```dart
     import 'package:purchases_flutter/purchases_flutter.dart';
     
     Future<void> initPlatformState() async {
       await Purchases.setDebugLogsEnabled(true);
       
       PurchasesConfiguration configuration;
       if (Platform.isAndroid) {
         configuration = PurchasesConfiguration("android-api-key");
       } else if (Platform.isIOS) {
         configuration = PurchasesConfiguration("ios-api-key");
       } else {
         // Handle other platforms if needed
         return;
       }
       
       await Purchases.configure(configuration);
       
       // Identify the user when they log in
       if (currentUser != null) {
         await Purchases.logIn(currentUser.id);
       }
     }
     ```

3. **Implement Paywall UI Integration**
   - Connect existing paywall UI to RevenueCat offerings:
     ```dart
     Future<void> fetchOfferings() async {
       try {
         Offerings offerings = await Purchases.getOfferings();
         if (offerings.current != null) {
           // Display the offerings in the UI
           setState(() {
             monthlyProduct = offerings.current?.monthly;
             yearlyProduct = offerings.current?.annual;
           });
         }
       } on PlatformException catch (e) {
         // Handle error
       }
     }
     ```

4. **Implement Purchase Flow**
   - Handle subscription purchases:
     ```dart
     Future<void> purchasePackage(Package package) async {
       try {
         CustomerInfo customerInfo = await Purchases.purchasePackage(package);
         
         // Check if user has premium entitlement
         EntitlementInfo? entitlement = customerInfo.entitlements.all["premium"];
         if (entitlement != null && entitlement.isActive) {
           // User has access to premium features
           unlockPremiumFeatures();
         }
       } on PlatformException catch (e) {
         var errorCode = PurchasesErrorHelper.getErrorCode(e);
         if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
           // User canceled
         } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
           // User not allowed to purchase
         }
         // Handle other errors
       }
     }
     ```

5. **Check Subscription Status**
   - Implement logic to check if the user has active subscription:
     ```dart
     Future<bool> checkPremiumStatus() async {
       try {
         CustomerInfo customerInfo = await Purchases.getCustomerInfo();
         return customerInfo.entitlements.all["premium"]?.isActive ?? false;
       } catch (e) {
         return false;
       }
     }
     ```

6. **Restore Purchases**
   - Allow users to restore previous purchases:
     ```dart
     Future<void> restorePurchases() async {
       try {
         CustomerInfo customerInfo = await Purchases.restorePurchases();
         // Check premium status after restore
         bool isPremium = customerInfo.entitlements.all["premium"]?.isActive ?? false;
       } catch (e) {
         // Handle restore error
       }
     }
     ```

### 2.3 Firebase Integration

1. **Install Firebase Extension**
   - In Firebase Console, install the RevenueCat extension
   - Configure the extension settings:
     - Webhook Events collection name: `revenuecat_events`
     - Customers collection name: `revenuecat_customers`
     - Enable custom claims for user entitlements

2. **Set Up Firebase Authentication User IDs**
   - Ensure Firebase user IDs are used as RevenueCat user identifiers:
     ```dart
     // After Firebase auth
     User? firebaseUser = FirebaseAuth.instance.currentUser;
     if (firebaseUser != null) {
       await Purchases.logIn(firebaseUser.uid);
     }
     ```

3. **Access Control with Custom Claims**
   - Use Firebase Authentication custom claims to check subscription status:
     ```dart
     // On client
     Future<bool> checkPremiumWithFirebase() async {
       try {
         IdTokenResult tokenResult = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
         return tokenResult.claims?['revenueCatEntitlements']?.contains('premium') ?? false;
       } catch (e) {
         return false;
       }
     }
     ```

4. **React to Purchase Events**
   - Create a Cloud Function to react to subscription events:
     ```javascript
     exports.onSubscriptionStatusChange = functions.firestore
       .document('revenuecat_events/{eventId}')
       .onCreate(async (snapshot, context) => {
         const event = snapshot.data();
         
         if (event.type === 'INITIAL_PURCHASE' || event.type === 'RENEWAL') {
           // Update user status in your own database
           await admin.firestore().collection('users')
             .doc(event.app_user_id)
             .update({
               isPremium: true,
               subscriptionExpiresAt: new Date(event.expires_date),
               subscriptionPlan: event.product_id
             });
         } else if (event.type === 'EXPIRATION' || event.type === 'CANCELLATION') {
           // Handle subscription end
           await admin.firestore().collection('users')
             .doc(event.app_user_id)
             .update({
               isPremium: false
             });
         }
       });
     ```

## 3. Focus Points (FP) System - Future Implementation

### 3.1 Design the Focus Points System

1. **Points Structure**
   - Define the points economy:
     - Daily streak rewards: 5-10 FP
     - Quiz completion: 15-25 FP
     - Course completion: 50-100 FP
   - Define course unlocking costs:
     - Standard courses: 200-500 FP
     - Premium courses: 1000+ FP

2. **RevenueCat Product Configuration**
   - Define consumable products for point packs:
     - `fp_small`: $1.99 for 100 FP
     - `fp_medium`: $4.99 for 300 FP
     - `fp_large`: $9.99 for 700 FP
     - `fp_mega`: $19.99 for 1800 FP

### 3.2 Implement Point Purchases

1. **Add Consumable Products to RevenueCat**
   - Configure each Focus Points pack as a non-subscription consumable product

2. **Purchase Implementation**
   - Implement purchase flow for consumable products:
     ```dart
     Future<void> purchaseFocusPoints(Package package) async {
       try {
         // Make the purchase
         CustomerInfo customerInfo = await Purchases.purchasePackage(package);
         
         // Get the product identifier to determine which FP pack was purchased
         String? productId = getProductIdFromPurchase(customerInfo);
         
         // Award the appropriate number of points
         if (productId != null) {
           int pointsToAward = getPointsForProduct(productId);
           await awardFocusPoints(pointsToAward);
         }
       } on PlatformException catch (e) {
         // Handle errors
       }
     }
     
     Future<void> awardFocusPoints(int points) async {
       // Update in Firestore
       await FirebaseFirestore.instance
           .collection('users')
           .doc(FirebaseAuth.instance.currentUser!.uid)
           .update({
             'focusPoints': FieldValue.increment(points)
           });
     }
     ```

### 3.3 Points Management System

1. **Track Points in Firebase**
   - Store user's current points in Firestore user document:
     ```
     {
       "id": "user123",
       "focusPoints": 750,
       "pointsHistory": [
         {
           "amount": 100,
           "source": "purchase",
           "productId": "fp_small",
           "timestamp": Timestamp
         },
         {
           "amount": 50,
           "source": "course_completion",
           "courseId": "course123",
           "timestamp": Timestamp
         }
       ],
       "pointsSpent": [
         {
           "amount": 200,
           "item": "course",
           "itemId": "premium_course_1",
           "timestamp": Timestamp
         }
       ]
     }
     ```

2. **Points Transaction Cloud Functions**
   - Create secure Cloud Functions for points transactions:
     ```javascript
     exports.spendFocusPoints = functions.https.onCall(async (data, context) => {
       // Ensure user is authenticated
       if (!context.auth) {
         throw new functions.https.HttpsError(
           'unauthenticated', 
           'User must be authenticated'
         );
       }
       
       const userId = context.auth.uid;
       const pointsToSpend = data.points;
       const itemType = data.itemType;
       const itemId = data.itemId;
       
       // Verify user has enough points in a transaction
       const userRef = admin.firestore().collection('users').doc(userId);
       
       return admin.firestore().runTransaction(async (transaction) => {
         const userDoc = await transaction.get(userRef);
         const userData = userDoc.data();
         
         if (!userData || userData.focusPoints < pointsToSpend) {
           throw new functions.https.HttpsError(
             'failed-precondition',
             'Not enough Focus Points'
           );
         }
         
         // Update points balance
         transaction.update(userRef, {
           focusPoints: FieldValue.increment(-pointsToSpend),
           pointsSpent: FieldValue.arrayUnion([{
             amount: pointsToSpend,
             item: itemType,
             itemId: itemId,
             timestamp: admin.firestore.FieldValue.serverTimestamp()
           }])
         });
         
         // Update item ownership
         if (itemType === 'course') {
           transaction.update(userRef, {
             unlockedCourses: FieldValue.arrayUnion([itemId])
           });
         }
         
         return { success: true };
       });
     });
     ```

## 4. Testing Strategy

1. **RevenueCat Sandbox Testing**
   - Test subscription purchases using sandbox accounts
   - Test subscription lifecycle (purchase, renewal, cancellation)
   - Verify Firebase data updates

2. **Focus Points Testing**
   - Test point earning mechanisms
   - Test point purchase flows
   - Test course unlocking with points

3. **Edge Cases**
   - Network interruptions during purchase
   - Account switching
   - Subscription restoration

## 5. Production Considerations

1. **Monitoring**
   - Set up RevenueCat dashboards for revenue monitoring
   - Configure alerting for subscription events
   - Monitor user engagement with point economy

2. **Server-Side Validation**
   - Validate purchases server-side
   - Protect against client-side manipulation of point balances

3. **Compliance**
   - Ensure subscription terms are clearly communicated
   - Implement proper privacy disclosures for payment handling
   - Address app store requirements for in-app purchases

## 6. Future Enhancements

1. **Subscription Tiers**
   - Consider multiple subscription tiers with different benefits
   - Implement upgrade/downgrade paths

2. **Promotional Offers**
   - Implement introductory offers
   - Create time-limited promotions

3. **Referral System**
   - Allow users to earn FP by referring friends
   - Implement subscription discounts for referrals 