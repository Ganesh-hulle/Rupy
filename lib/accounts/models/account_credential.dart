import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AccountCredential extends Equatable {
  AccountCredential({
    String? id,
    required this.bankName,
    required this.username,
    required this.password,
    this.website,
    required this.lastUpdated,
    this.brandColor,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String bankName;
  final String username;
  final String password;
  final String? website;
  final DateTime lastUpdated;
  final Color? brandColor;

  AccountCredential copyWith({
    String? id,
    String? bankName,
    String? username,
    String? password,
    String? website,
    DateTime? lastUpdated,
    Color? brandColor,
  }) {
    return AccountCredential(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      brandColor: brandColor ?? this.brandColor,
    );
  }

  Map<String, dynamic> toMap() => {
    'bankName': bankName,
    'username': username,
    'password': password,
    'website': website,
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    'brandColor': brandColor?.value,
  };

  factory AccountCredential.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return AccountCredential(
      id: id,
      bankName: (map['bankName'] ?? map['bank_name'] ?? 'Bank').toString(),
      username: (map['username'] ?? map['login_id'] ?? '').toString(),
      password: (map['password'] ?? map['login_password'] ?? '').toString(),
      website: map['website'] as String?,
      lastUpdated: toDate(
        map['lastUpdated'] ??
            map['updated_at'] ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      brandColor: map['brandColor'] != null
          ? Color(map['brandColor'] as int)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bankName,
    username,
    password,
    website,
    lastUpdated,
    brandColor,
  ];
}
