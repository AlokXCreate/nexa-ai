import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:localmind_ai/features/auth/domain/entities/user_entity.dart';
import 'package:localmind_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:localmind_ai/features/auth/presentation/providers/auth_providers.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isVerificationEmailSent;
  final bool isPasswordResetEmailSent;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isVerificationEmailSent = false,
    this.isPasswordResetEmailSent = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool? isVerificationEmailSent,
    bool? isPasswordResetEmailSent,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isVerificationEmailSent: isVerificationEmailSent ?? this.isVerificationEmailSent,
      isPasswordResetEmailSent: isPasswordResetEmailSent ?? this.isPasswordResetEmailSent,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.loginWithEmail(email: email, password: password);
    result.fold(
      (error) => state = state.copyWith(isLoading: false, errorMessage: error),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.registerWithEmail(email: email, password: password);
    result.fold(
      (error) => state = state.copyWith(isLoading: false, errorMessage: error),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.signInWithGoogle();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, errorMessage: error),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> loginAsGuest() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.loginAsGuest();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, errorMessage: error),
      (user) => state = state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.sendPasswordResetEmail(email: email);
    result.fold(
      (error) => state = state.copyWith(isLoading: false, errorMessage: error),
      (_) => state = state.copyWith(isLoading: false, isPasswordResetEmailSent: true),
    );
  }

  Future<void> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.sendEmailVerification();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, errorMessage: error),
      (_) => state = state.copyWith(isLoading: false, isVerificationEmailSent: true),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = state.copyWith(isLoading: false, clearUser: true);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
