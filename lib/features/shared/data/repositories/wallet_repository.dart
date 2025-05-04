import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:louage/features/shared/domain/models/wallet_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'wallets';

  WalletRepository(this._firestore);

  Future<WalletModel?> getWalletByUserId(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      if (doc.docs.isEmpty) {
        // Create a new wallet if none exists
        final newWallet = WalletModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          balance: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore.collection(_collection).doc(newWallet.id).set(newWallet.toMap());
        return newWallet;
      }

      return WalletModel.fromMap(doc.docs.first.data());
    } catch (e) {
      print('Error getting wallet: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(String walletId, double amount) async {
    try {
      final doc = await _firestore.collection(_collection).doc(walletId).get();
      if (!doc.exists) throw Exception('Wallet not found');

      final currentBalance = (doc.data()?['balance'] as num).toDouble();
      final newBalance = currentBalance + amount;

      await _firestore.collection(_collection).doc(walletId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating wallet balance: $e');
      rethrow;
    }
  }
} 