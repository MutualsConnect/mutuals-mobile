/// Saldo de la billetera (`WalletResponse`).
class Wallet {
  const Wallet({required this.gems, required this.shields, required this.shieldPriceGems});

  final int gems;
  final int shields;

  /// Cuántas gemas cuesta un escudo.
  final int shieldPriceGems;

  /// Cuántos escudos alcanzan a comprarse con las gemas actuales.
  int get affordableShields => shieldPriceGems <= 0 ? 0 : gems ~/ shieldPriceGems;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        gems: (json['gems'] as num).toInt(),
        shields: (json['shields'] as num).toInt(),
        shieldPriceGems: (json['shieldPriceGems'] as num).toInt(),
      );
}

enum WalletCurrency { gems, shields }

enum WalletTransactionType { earn, spend, giftSent, giftReceived, used, grant }

WalletTransactionType _type(String raw) => switch (raw) {
      'EARN' => WalletTransactionType.earn,
      'SPEND' => WalletTransactionType.spend,
      'GIFT_SENT' => WalletTransactionType.giftSent,
      'GIFT_RECEIVED' => WalletTransactionType.giftReceived,
      'USED' => WalletTransactionType.used,
      _ => WalletTransactionType.grant,
    };

/// Un movimiento de la billetera (`WalletTransactionResponse`).
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.currency,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.reason,
    this.counterpartyUsername,
  });

  final int id;
  final WalletCurrency currency;

  /// Positivo si entra, negativo si sale.
  final int amount;
  final WalletTransactionType type;
  final String? reason;
  final String? counterpartyUsername;
  final DateTime createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: (json['id'] as num).toInt(),
        currency: json['currency'] == 'SHIELDS' ? WalletCurrency.shields : WalletCurrency.gems,
        amount: (json['amount'] as num).toInt(),
        type: _type(json['type'] as String),
        reason: json['reason'] as String?,
        counterpartyUsername: json['counterpartyUsername'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get currencyEmoji => currency == WalletCurrency.gems ? '💎' : '🛡️';

  /// Título corto del movimiento, en español.
  String get title => switch (type) {
        WalletTransactionType.earn => 'Ganaste gemas',
        WalletTransactionType.spend => 'Compraste escudos',
        WalletTransactionType.giftSent => 'Regalaste un escudo',
        WalletTransactionType.giftReceived => 'Te regalaron un escudo',
        WalletTransactionType.used => 'Usaste un escudo',
        WalletTransactionType.grant => 'Recibiste un obsequio',
      };
}
