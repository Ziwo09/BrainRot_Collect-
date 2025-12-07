import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_data.dart';

class GameProvider with ChangeNotifier {
  // --- RESURSE ---
  int _gold = 2000;
  int _gems = 50;
  int _brainRotDust = 0; // Currency pentru duplicate

  int get gold => _gold;
  int get gems => _gems;
  int get dust => _brainRotDust;

  // --- INVENTAR ---
  // Mapare: CardID -> Cantitate deținută
  final Map<String, int> _inventory = {};

  // --- INITIALIZARE ---
  GameProvider() {
    // Populăm inventarul cu 0
    for (var card in masterCardList) {
      _inventory[card.id] = 0;
    }
  }

  int getCardCount(String id) => _inventory[id] ?? 0;

  // Lista cărților deținute (măcar o bucată)
  List<GameCard> get unlockedCards =>
      masterCardList.where((c) => (_inventory[c.id] ?? 0) > 0).toList();

  // Progres total (ex: 6/12)
  String get collectionProgress =>
      "${unlockedCards.length}/${masterCardList.length}";
  double get collectionPercentage =>
      unlockedCards.length / masterCardList.length;

  // --- LOGICA GACHA (CHEST OPENING) ---

  // Costuri
  static const int chestCost = 500;

  bool get canOpenChest => _gold >= chestCost;

  GameCard? openChest() {
    if (!canOpenChest) return null;

    _gold -= chestCost;

    // Algoritm de șanse
    final rand = Random();
    double roll = rand.nextDouble(); // 0.0 - 1.0

    Rarity pickedRarity;
    if (roll < 0.05) {
      pickedRarity = Rarity.legendary; // 5%
    } else if (roll < 0.20) {
      pickedRarity = Rarity.epic; // 15%
    } else if (roll < 0.50) {
      pickedRarity = Rarity.rare; // 30%
    } else {
      pickedRarity = Rarity.common; // 50%
    }

    // Alegem o carte random din raritatea respectivă
    List<GameCard> pool =
        masterCardList.where((c) => c.rarity == pickedRarity).toList();
    GameCard droppedCard = pool[rand.nextInt(pool.length)];

    _addCardToInventory(droppedCard);
    notifyListeners();
    return droppedCard;
  }

  void _addCardToInventory(GameCard card) {
    if (_inventory[card.id]! > 0) {
      // ESTE DUPLICAT -> Convertim in DUST
      int dustAmount = 0;
      switch (card.rarity) {
        case Rarity.common:
          dustAmount = 10;
          break;
        case Rarity.rare:
          dustAmount = 50;
          break;
        case Rarity.epic:
          dustAmount = 200;
          break;
        case Rarity.legendary:
          dustAmount = 1000;
          break;
      }
      _brainRotDust += dustAmount;
      // Totuși, îl adăugăm și la counter (opțional, dacă vrei să păstrezi duplicatele pt trade)
      _inventory[card.id] = _inventory[card.id]! + 1;
    } else {
      // Carte nouă!
      _inventory[card.id] = 1;
    }
  }

  // --- LOGICA DE TRADING (5 Comune -> 1 Rară) ---

  // Verifică dacă avem suficiente cărți de o anumită raritate pentru trade
  bool canTrade(Rarity fromRarity) {
    int totalOwnedOfRarity = 0;
    for (var card in masterCardList.where((c) => c.rarity == fromRarity)) {
      // Calculăm doar duplicatele "extra" sau toate?
      // Cerința: "daca un player are 5 carti comune". Vom folosi totalul.
      totalOwnedOfRarity += _inventory[card.id] ?? 0;
    }
    return totalOwnedOfRarity >= 5;
  }

  String tradeCards(Rarity fromRarity) {
    if (!canTrade(fromRarity)) return "Nu ai suficiente cărți!";
    if (fromRarity == Rarity.legendary) return "Nu poți upgrada legendare!";

    // 1. Consumăm 5 cărți random din raritatea curentă
    int removed = 0;
    List<GameCard> pool =
        masterCardList.where((c) => c.rarity == fromRarity).toList();

    // Iterăm și scădem până am scos 5
    while (removed < 5) {
      // Luăm o carte random din pool
      var randomCard = pool[Random().nextInt(pool.length)];
      if ((_inventory[randomCard.id] ?? 0) > 0) {
        _inventory[randomCard.id] = _inventory[randomCard.id]! - 1;
        removed++;
      }
    }

    // 2. Oferim o carte de raritate superioară
    Rarity nextRarity = Rarity.values[fromRarity.index + 1];
    List<GameCard> rewardPool =
        masterCardList.where((c) => c.rarity == nextRarity).toList();
    GameCard reward = rewardPool[Random().nextInt(rewardPool.length)];

    // Adăugăm recompensa (fără logica de Dust aici, e trade direct)
    _inventory[reward.id] = (_inventory[reward.id] ?? 0) + 1;

    notifyListeners();
    return "Succes! Ai primit ${reward.name} (${nextRarity.name})";
  }

  // --- LOGICA DUST TO GEMS ---
  // Rata: 100 Dust -> 10 Gems
  void convertDustToGems() {
    if (_brainRotDust >= 100) {
      _brainRotDust -= 100;
      _gems += 10;
      notifyListeners();
    }
  }

  // --- CHEAT (PENTRU TESTARE) ---
  void addMoney() {
    _gold += 1000;
    notifyListeners();
  }
}
