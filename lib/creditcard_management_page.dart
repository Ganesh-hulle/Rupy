import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/add_card_dialog.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/cards/card_repository.dart';

class CreditCard {
  final String id;
  final String bankName;
  final String? bankIconUrl;
  final String cardNumber;
  final String holderName;
  final String expiryDate;
  final String cvv;
  final Color cardColor;
  final Color textColor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CreditCard({
    required this.id,
    required this.bankName,
    this.bankIconUrl,
    required this.cardNumber,
    required this.holderName,
    required this.expiryDate,
    required this.cvv,
    required this.cardColor,
    required this.textColor,
    this.createdAt,
    this.updatedAt,
  });

  CreditCard copyWith({
    String? id,
    String? bankName,
    String? bankIconUrl,
    String? cardNumber,
    String? holderName,
    String? expiryDate,
    String? cvv,
    Color? cardColor,
    Color? textColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCard(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      bankIconUrl: bankIconUrl ?? this.bankIconUrl,
      cardNumber: cardNumber ?? this.cardNumber,
      holderName: holderName ?? this.holderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardColor: cardColor ?? this.cardColor,
      textColor: textColor ?? this.textColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toStorageMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'bankName': bankName,
      'bankIconUrl': bankIconUrl,
      'cardNumber': cardNumber,
      'holderName': holderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardColor': cardColor.value,
      'textColor': textColor.value,
      'createdAt': (createdAt ?? now).millisecondsSinceEpoch,
      'updatedAt': (updatedAt ?? now).millisecondsSinceEpoch,
    };
  }

  factory CreditCard.fromStorage(Map<String, dynamic> data) {
    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    return CreditCard(
      id: (data['id'] ?? '').toString(),
      bankName: (data['bankName'] ?? data['bank_name'] ?? 'Unknown') as String,
      bankIconUrl: data['bankIconUrl'] as String?,
      cardNumber:
          (data['cardNumber'] ?? data['card_number'] ?? '**** **** **** 0000')
              as String,
      holderName: (data['holderName'] ?? data['card_holder_name'] ?? '')
          .toString(),
      expiryDate: (data['expiryDate'] ?? data['expiry_date'] ?? '').toString(),
      cvv: (data['cvv'] ?? '***').toString(),
      cardColor: Color((data['cardColor'] ?? 0xFF334155) as int),
      textColor: Color((data['textColor'] ?? 0xFFFFFFFF) as int),
      createdAt: toDate(data['createdAt'] ?? data['created_at']),
      updatedAt: toDate(data['updatedAt'] ?? data['updated_at']),
    );
  }
}

class CreditCardManagementPage extends StatefulWidget {
  @override
  State<CreditCardManagementPage> createState() =>
      _CreditCardManagementPageState();
}

class _CreditCardManagementPageState extends State<CreditCardManagementPage>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _cardTransitionController;
  late AnimationController _detailsController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _detailsFadeAnimation;
  late Animation<double> _detailsScaleAnimation;
  late final CardCubit _cardCubit;
  bool _revealSensitive = false;

  Future<void> _onAddCard() async {
    // Expecting your dialog to return either a CreditCard or a Map<String, dynamic>
    final result = await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddCardDialog(),
    );

    if (result == null) return;

    CreditCard? newCard;

    if (result is CreditCard) {
      newCard = result;
    } else if (result is Map) {
      newCard = CreditCard(
        id: (result['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString(),
        bankName: result['bankName'] ?? 'New Bank',
        bankIconUrl: result['bankIconUrl'] as String?,
        cardNumber: result['cardNumber'] ?? '**** **** **** 0000',
        holderName: result['holderName'] ?? '',
        expiryDate: result['expiryDate'] ?? '',
        cvv: result['cvv'] ?? '***',
        cardColor: (result['cardColor'] is Color)
            ? result['cardColor']
            : const Color(0xFF334155),
        textColor: (result['textColor'] is Color)
            ? result['textColor']
            : Colors.white,
        createdAt: DateTime.now(),
      );
    }

    if (newCard == null) return;

    await _cardCubit.addCard(newCard!);
    setState(() => selectedCard = newCard);

    // Play the select animation for the newly added card
    _detailsController
      ..reset()
      ..forward();
    _cardTransitionController
      ..reset()
      ..forward();
  }

  Future<void> _editCard(CreditCard card) async {
    final result = await showDialog<CreditCard>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddCardDialog(existing: card),
    );
    if (result != null) {
      await _cardCubit.addCard(result);
      setState(() => selectedCard = result);
      _detailsController
        ..reset()
        ..forward();
      _cardTransitionController
        ..reset()
        ..forward();
    }
  }

  Future<void> _deleteCard(CreditCard card) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete card'),
            content: Text('Remove ${card.bankName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm) {
      await _cardCubit.deleteCard(card.id);
    }
  }

  CreditCard? selectedCard;

  List<CreditCard> cards = [];

  @override
  void initState() {
    super.initState();
    _cardCubit = CardCubit(CardRepository())..loadCards();
    selectedCard = null;

    _shimmerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();

    _cardTransitionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _detailsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _cardSlideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardTransitionController,
        curve: Curves.easeInOut,
      ),
    );

    _detailsFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _detailsController, curve: Curves.easeOut),
    );

    _detailsScaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _detailsController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _cardTransitionController.dispose();
    _detailsController.dispose();
    _cardCubit.close();
    super.dispose();
  }

  void _selectCard(CreditCard card) {
    if (selectedCard?.id == card.id) return;

    setState(() {
      selectedCard = card;
      _revealSensitive = false;
    });
    _detailsController.reset();
    _cardTransitionController.reset();

    _cardTransitionController.forward();
    _detailsController.forward();
  }

  List<CreditCard> get availableCards =>
      cards.where((c) => c.id != selectedCard?.id).toList();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth / 1.586; // credit card ratio

    return BlocProvider.value(
      value: _cardCubit,
      child: BlocListener<CardCubit, CardState>(
        listenWhen: (previous, current) => previous.cards != current.cards,
        listener: (context, state) {
          setState(() {
            cards = state.cards;
            if (selectedCard == null && cards.isNotEmpty) {
              selectedCard = cards.first;
              _detailsController.forward();
              _cardTransitionController.forward();
            } else if (selectedCard != null &&
                !cards.any((c) => c.id == selectedCard!.id)) {
              selectedCard = cards.isNotEmpty ? cards.first : null;
            }
          });
        },
        child: BlocBuilder<CardCubit, CardState>(
          builder: (context, state) {
            final loading = state.loading && cards.isEmpty;
            return Scaffold(
              backgroundColor: Color(0xFFF1F5F9),
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
                title: Text(
                  'My Cards',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              body: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Selected Card
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: cardHeight,
                            child: selectedCard != null
                                ? AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _detailsFadeAnimation,
                                      _detailsScaleAnimation,
                                    ]),
                                    builder: (_, __) => FadeTransition(
                                      opacity: _detailsFadeAnimation,
                                      child: ScaleTransition(
                                        scale: _detailsScaleAnimation,
                                        child: _buildGlassCard(
                                          selectedCard!,
                                          cardHeight,
                                        ),
                                      ),
                                    ),
                                  )
                                : _buildEmptyState(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your Cards',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _onAddCard,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Card'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Card list
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: availableCards.isEmpty
                                ? _buildListEmpty()
                                : ListView.separated(
                                    itemCount: availableCards.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(height: 12),
                                    itemBuilder: (_, index) {
                                      final card = availableCards[index];
                                      return GestureDetector(
                                        onTap: () => _selectCard(card),
                                        child: _buildMiniCard(card),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _onAddCard,
                icon: const Icon(Icons.add_card),
                label: const Text('New card'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard(CreditCard card, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Frosted glass background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [card.cardColor, card.cardColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.white.withOpacity(0.02)),
          ),

          // Shimmer layer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(
                  (_shimmerController.value * height * 2) - height,
                  0,
                ),
                child: Container(
                  width: height / 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.07),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              );
            },
          ),

          // Card content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Name + Icon
                Row(
                  children: [
                    if (card.bankIconUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          backgroundImage: NetworkImage(card.bankIconUrl!),
                          radius: 16,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        card.bankName,
                        style: TextStyle(
                          color: card.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _revealSensitive
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: card.textColor,
                      ),
                      tooltip: _revealSensitive
                          ? 'Hide details'
                          : 'Show details',
                      onPressed: () => setState(() {
                        _revealSensitive = !_revealSensitive;
                      }),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: card.textColor),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editCard(card);
                            break;
                          case 'delete':
                            _deleteCard(card);
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  _displayNumber(card),
                  style: TextStyle(
                    color: card.textColor,
                    fontSize: 22,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardField(
                      "CARD HOLDER",
                      card.holderName,
                      card.textColor,
                    ),
                    _buildCardField("EXPIRES", card.expiryDate, card.textColor),
                    _buildCardField("CVV", _displayCvv(card), card.textColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardField(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _displayNumber(CreditCard card) {
    if (_revealSensitive) return _groupCard(card.cardNumber);
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.isNotEmpty
        ? digits.substring(
            digits.length - (digits.length >= 4 ? 4 : digits.length),
          )
        : '****';
    return '**** **** **** $last4';
  }

  String _displayCvv(CreditCard card) {
    if (_revealSensitive) return card.cvv;
    return '***';
  }

  String _maskForList(CreditCard card) {
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.isNotEmpty
        ? digits.substring(
            digits.length - (digits.length >= 4 ? 4 : digits.length),
          )
        : '****';
    return '**** **** **** $last4';
  }

  String _groupCard(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(d[i]);
    }
    return buffer.toString();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.credit_card,
              size: 48,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No cards yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text('Add your first card to keep it synced across devices'),
        ],
      ),
    );
  }

  Widget _buildListEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nothing here yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _onAddCard,
            icon: const Icon(Icons.add),
            label: const Text('Add a card'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(CreditCard card) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [card.cardColor, card.cardColor.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: card.cardColor.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (card.bankIconUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(card.bankIconUrl!),
                backgroundColor: Colors.white.withOpacity(0.15),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.bankName,
                style: TextStyle(
                  color: card.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _maskForList(card),
                style: TextStyle(
                  color: card.textColor.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: card.textColor.withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}
