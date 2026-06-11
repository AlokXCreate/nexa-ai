import 'package:fpdart/fpdart.dart';
import 'package:localmind_ai/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  
  Future<Either<String, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<String, UserEntity>> registerWithEmail({
    required String email,
    required String password,
  });

  Future<Either<String, UserEntity>> signInWithGoogle();

  Future<Either<String, UserEntity>> loginAsGuest();

  Future<Either<String, Unit>> sendPasswordResetEmail({required String email});

  Future<Either<String, Unit>> sendEmailVerification();

  Future<void> logout();
}
