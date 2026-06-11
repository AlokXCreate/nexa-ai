import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:localmind_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:localmind_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:localmind_ai/features/auth/domain/entities/user_entity.dart';

final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDatasourceProvider));
});

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
