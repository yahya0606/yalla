import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/data/repositories/wallet_repository.dart';
import 'package:louage/features/shared/domain/models/wallet_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(FirebaseFirestore.instance);
});

final userWalletProvider = StreamProvider.family<WalletModel?, String>((ref, userId) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getWalletByUserId(userId).asStream();
}); 