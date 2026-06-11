import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:localmind_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:localmind_ai/features/auth/domain/entities/user_entity.dart';
import 'package:localmind_ai/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Stream<UserEntity?> get authStateChanges {
    return _datasource.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToEntity(firebaseUser);
    });
  }

  @override
  Future<Either<String, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _datasource.loginWithEmail(email: email, password: password);
      if (credential.user == null) return const Left('User not found');
      return Right(_mapFirebaseUserToEntity(credential.user!));
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Authentication error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _datasource.registerWithEmail(email: email, password: password);
      if (credential.user == null) return const Left('User creation failed');
      return Right(_mapFirebaseUserToEntity(credential.user!));
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Registration error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signInWithGoogle() async {
    try {
      final credential = await _datasource.signInWithGoogle();
      if (credential == null || credential.user == null) {
        return const Left('Google Sign-In canceled');
      }
      return Right(_mapFirebaseUserToEntity(credential.user!));
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Google Sign-In error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> loginAsGuest() async {
    return Right(UserEntity.guest());
  }

  @override
  Future<Either<String, Unit>> sendPasswordResetEmail({required String email}) async {
    try {
      await _datasource.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Failed to send password reset email');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> sendEmailVerification() async {
    try {
      await _datasource.sendEmailVerification();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Failed to send email verification');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _datasource.logout();
  }

  UserEntity _mapFirebaseUserToEntity(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      isGuest: false,
    );
  }
}
