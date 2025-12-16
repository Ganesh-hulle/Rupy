import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/accounts/models/account_credential.dart';

class AccountsState extends Equatable {
  const AccountsState({
    this.loading = false,
    this.items = const [],
    this.error,
  });

  final bool loading;
  final List<AccountCredential> items;
  final String? error;

  AccountsState copyWith({
    bool? loading,
    List<AccountCredential>? items,
    String? error,
  }) {
    return AccountsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, items, error];
}

class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repository) : super(const AccountsState());

  final AccountsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repository.fetchAccounts();
      emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> save(AccountCredential account) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.saveAccount(account);
      final updated = [
        account,
        ...state.items.where((a) => a.id != account.id),
      ];
      emit(state.copyWith(loading: false, items: updated));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> delete(String id) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteAccount(id);
      emit(
        state.copyWith(
          loading: false,
          items: state.items.where((a) => a.id != id).toList(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
