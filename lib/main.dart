import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ============================================================================
// GLOBAL KEYS
// ============================================================================
final GlobalKey dustTargetKey = GlobalKey();

// ============================================================================
// 1. DATA MODELS
// ============================================================================

enum Rarity { common, rare, epic, legendary }

extension RarityExtension on Rarity {
  String get label {
    switch (this) {
      case Rarity.common: return "Common";
      case Rarity.rare: return "Rare";
      case Rarity.epic: return "Epic";
      case Rarity.legendary: return "Legendary";
    }
  }

  Color get color {
    switch (this) {
      case Rarity.common: return const Color(0xFFB0BEC5);
      case Rarity.rare: return const Color(0xFF29B6F6);
      case Rarity.epic: return const Color(0xFFAB47BC);
      case Rarity.legendary: return const Color(0xFFFFD54F);
    }
  }
}

class GameCard {
  final String id;
  final String name;
  final String imagePath;
  final Rarity rarity;

  GameCard({required this.id, required this.name, required this.imagePath, required this.rarity});
}

class GachaResult {
  final GameCard card;
  final bool isDuplicate;
  final int dustGained;

  GachaResult({required this.card, required this.isDuplicate, required this.dustGained});
}

final List<GameCard> masterCardList = [
  GameCard(id: 'c1', name: 'Batul', imagePath: 'assets/images/batul.jpg', rarity: Rarity.common),
  GameCard(id: 'c2', name: 'Aeroplanino', imagePath: 'assets/images/aeroplanino.jpg', rarity: Rarity.common),
  GameCard(id: 'c3', name: 'Tree', imagePath: 'assets/images/tree.jpg', rarity: Rarity.common),
  GameCard(id: 'r1', name: 'Bananito', imagePath: 'assets/images/bananito.jpg', rarity: Rarity.rare),
  GameCard(id: 'r2', name: 'Ananasita', imagePath: 'assets/images/ananasita.jpg', rarity: Rarity.rare),
  GameCard(id: 'r3', name: 'Brimbrum', imagePath: 'assets/images/brimbrum.jpg', rarity: Rarity.rare),
  GameCard(id: 'e1', name: 'Ballerina', imagePath: 'assets/images/ballerina.jpg', rarity: Rarity.epic),
  GameCard(id: 'e2', name: 'Bambini', imagePath: 'assets/images/bambini.jpg', rarity: Rarity.epic),
  GameCard(id: 'e3', name: 'Cactufant', imagePath: 'assets/images/cactufant.jpg', rarity: Rarity.epic),
  GameCard(id: 'l1', name: 'Shark', imagePath: 'assets/images/shark.jpg', rarity: Rarity.legendary),
  GameCard(id: 'l2', name: 'Croco', imagePath: 'assets/images/croco.jpg', rarity: Rarity.legendary),
  GameCard(id: 'l3', name: 'Ananasopotam', imagePath: 'assets/images/ananasopotam.jpg', rarity: Rarity.legendary),
];

// ============================================================================
// 2. GAME LOGIC & STATE
// ============================================================================

class GameProvider with ChangeNotifier {
  int _gold = 3000;
  int _gems = 50;
  int _dust = 0;

  bool _isDustVisible = false;
  Timer? _dustTimer;

  int get gold => _gold;
  int get gems => _gems;
  int get dust => _dust;
  bool get isDustVisible => _isDustVisible;

  final Map<String, int> _inventory = {};

  GameProvider() {
    for (var c in masterCardList) _inventory[c.id] = 0;
  }

  int getCardCount(String id) => _inventory[id] ?? 0;
  List<GameCard> get unlockedCards => masterCardList.where((c) => (_inventory[c.id] ?? 0) > 0).toList();
  String get progressString => "${unlockedCards.length}/${masterCardList.length}";
  double get progressValue => unlockedCards.length / masterCardList.length;

  static const int chestPrice = 500;
  bool get canAffordChest => _gold >= chestPrice;

  GachaResult? openChest() {
    if (!canAffordChest) return null;
    _gold -= chestPrice;

    final rand = Random();
    double roll = rand.nextDouble();
    Rarity pickedRarity;
    if (roll < 0.05) pickedRarity = Rarity.legendary;
    else if (roll < 0.20) pickedRarity = Rarity.epic;
    else if (roll < 0.50) pickedRarity = Rarity.rare;
    else pickedRarity = Rarity.common;

    List<GameCard> pool = masterCardList.where((c) => c.rarity == pickedRarity).toList();
    GameCard droppedCard = pool[rand.nextInt(pool.length)];

    return _processCardDrop(droppedCard);
  }

  GachaResult _processCardDrop(GameCard card) {
    int currentCount = _inventory[card.id] ?? 0;
    bool isDup = currentCount > 0;
    int dustGain = 0;

    if (isDup) {
      switch (card.rarity) {
        case Rarity.common: dustGain = 10; break;
        case Rarity.rare: dustGain = 50; break;
        case Rarity.epic: dustGain = 200; break;
        case Rarity.legendary: dustGain = 1000; break;
      }
      _inventory[card.id] = currentCount + 1;
    } else {
      _inventory[card.id] = 1;
    }

    notifyListeners();
    return GachaResult(card: card, isDuplicate: isDup, dustGained: dustGain);
  }

  void showDustBar() {
    _isDustVisible = true;
    notifyListeners();
    _resetHideTimer();
  }

  void collectFlyingDust(int amount) {
    _dust += amount;
    _isDustVisible = true;
    notifyListeners();
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _dustTimer?.cancel();
    _dustTimer = Timer(const Duration(seconds: 4), () {
      _isDustVisible = false;
      notifyListeners();
    });
  }

  bool canTrade(Rarity rarity) {
    int totalOwned = 0;
    for (var c in masterCardList.where((x) => x.rarity == rarity)) {
      totalOwned += _inventory[c.id] ?? 0;
    }
    return totalOwned >= 5;
  }

  // --- RETURN TYPE CHANGED TO GameCard? ---
  GameCard? executeTrade(Rarity fromRarity) {
    if (!canTrade(fromRarity)) return null;

    List<GameCard> pool = masterCardList.where((c) => c.rarity == fromRarity).toList();
    int removed = 0;
    Random rng = Random();

    // Eliminăm 5 cărți
    while (removed < 5) {
      GameCard t = pool[rng.nextInt(pool.length)];
      if ((_inventory[t.id] ?? 0) > 0) {
        _inventory[t.id] = _inventory[t.id]! - 1;
        removed++;
      }
    }

    // Alegem recompensa
    Rarity next = Rarity.values[fromRarity.index + 1];
    List<GameCard> rewardPool = masterCardList.where((c) => c.rarity == next).toList();
    GameCard reward = rewardPool[rng.nextInt(rewardPool.length)];

    _inventory[reward.id] = (_inventory[reward.id] ?? 0) + 1;
    notifyListeners();

    // Returnăm cartea pentru a fi afișată în UI
    return reward;
  }

  void convertDust() {
    if (_dust >= 100) {
      _dust -= 100;
      _gems += 10;
      notifyListeners();
    }
  }

  void addGold() { _gold += 1000; notifyListeners(); }
}

// ============================================================================
// 3. ANIMATION HELPERS
// ============================================================================

void triggerFlyingDustAnimation(BuildContext context, int dustAmount) {
  final overlayState = Overlay.of(context);
  final renderBoxScreen = context.findRenderObject() as RenderBox;
  final startPos = renderBoxScreen.size.center(Offset.zero);

  Provider.of<GameProvider>(context, listen: false).showDustBar();

  final renderBoxTarget = dustTargetKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBoxTarget == null) return;
  final endPos = renderBoxTarget.localToGlobal(Offset.zero);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return _FlyingParticleWidget(
        startPos: startPos,
        endPos: endPos,
        onAnimationComplete: () {
          Provider.of<GameProvider>(context, listen: false).collectFlyingDust(dustAmount);
          overlayEntry.remove();
        },
      );
    },
  );

  overlayState.insert(overlayEntry);
}

class _FlyingParticleWidget extends StatefulWidget {
  final Offset startPos;
  final Offset endPos;
  final VoidCallback onAnimationComplete;

  const _FlyingParticleWidget({required this.startPos, required this.endPos, required this.onAnimationComplete});

  @override
  State<_FlyingParticleWidget> createState() => _FlyingParticleWidgetState();
}

class _FlyingParticleWidgetState extends State<_FlyingParticleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _positionAnimation = Tween<Offset>(begin: widget.startPos, end: widget.endPos)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
    _scaleAnimation = Tween<double>(begin: 1.5, end: 0.5)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onAnimationComplete();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: const Material(color: Colors.transparent, child: Icon(Icons.auto_fix_high, color: Colors.purpleAccent, size: 30)),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 4. MAIN & SCREENS
// ============================================================================

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GameProvider())],
      child: const BrainRotApp(),
    ),
  );
}

class BrainRotApp extends StatelessWidget {
  const BrainRotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainRot Collect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF141414),
        primaryColor: const Color(0xFFFFD700),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFF64FFDA),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 1;

  final List<Widget> _screens = [
    const ShopScreen(),
    const ChestOpeningScreen(),
    const CollectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: Colors.amber.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(FontAwesomeIcons.store), label: 'Shop'),
          NavigationDestination(icon: Icon(FontAwesomeIcons.boxOpen), label: 'Open'),
          NavigationDestination(icon: Icon(FontAwesomeIcons.layerGroup), label: 'Cards'),
        ],
      ),
    );
  }
}

// ============================================================================
// SHOP SCREEN (Acum StatefulWidget pentru Confetti)
// ============================================================================

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _handleTrade(Rarity r) {
    final provider = Provider.of<GameProvider>(context, listen: false);
    GameCard? reward = provider.executeTrade(r);

    if (reward != null) {
      // 1. Play Confetti
      _confettiCtrl.play();

      // 2. Show Dialog
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: reward.rarity.color, width: 3),
              boxShadow: [BoxShadow(color: reward.rarity.color.withOpacity(0.6), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("TRADE COMPLETE!",
                    style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 24)
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(reward.imagePath, height: 180, fit: BoxFit.cover),
                ),
                const SizedBox(height: 20),
                Text(reward.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(reward.rarity.label, style: TextStyle(color: reward.rarity.color)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: reward.rarity.color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text("COLLECT", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>();
    return SafeArea(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              const TopBar(title: "Market"),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Dust Converter", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                                Text("Balance: ${state.dust} Dust", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: state.dust >= 100 ? state.convertDust : null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                            child: const Text("100 Dust ➔ 10 Gems"),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Text("TRADE UP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                    const SizedBox(height: 10),

                    _buildTradeRow(context, state, Rarity.common),
                    _buildTradeRow(context, state, Rarity.rare),
                    _buildTradeRow(context, state, Rarity.epic),

                    const SizedBox(height: 40),
                    Center(
                      child: TextButton.icon(
                        onPressed: state.addGold,
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        label: const Text("DEV: Add Gold"),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),

          // Confetti Layer
          ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeRow(BuildContext context, GameProvider state, Rarity r) {
    if (r == Rarity.legendary) return const SizedBox();
    Rarity next = Rarity.values[r.index + 1];
    bool canTrade = state.canTrade(r);

    return Card(
      color: const Color(0xFF1F1F1F),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(side: BorderSide(color: r.color.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: r.color, child: const Icon(Icons.sync, color: Colors.black)),
        title: Text("5x ${r.label}", style: TextStyle(color: r.color, fontWeight: FontWeight.bold)),
        subtitle: Text("Get 1 Random ${next.label}"),
        trailing: ElevatedButton(
          onPressed: canTrade ? () => _handleTrade(r) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canTrade ? Colors.amber : Colors.grey[800],
            foregroundColor: canTrade ? Colors.black : Colors.white38,
            elevation: canTrade ? 2 : 0,
          ),
          child: const Text("TRADE"),
        ),
      ),
    );
  }
}

// ============================================================================
// CHEST OPENING
// ============================================================================

class ChestOpeningScreen extends StatefulWidget {
  const ChestOpeningScreen({super.key});

  @override
  State<ChestOpeningScreen> createState() => _ChestOpeningScreenState();
}

class _ChestOpeningScreenState extends State<ChestOpeningScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiCtrl;
  late AnimationController _shakeCtrl;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _triggerOpen() async {
    if (_isOpening) return;
    final state = Provider.of<GameProvider>(context, listen: false);
    if (!state.canAffordChest) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough Gold!")));
      return;
    }

    setState(() => _isOpening = true);
    _shakeCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 1200));
    _shakeCtrl.stop();
    _shakeCtrl.value = 0;

    GachaResult? result = state.openChest();

    if (result != null) {
      _confettiCtrl.play();
      if (mounted) {
        if (result.isDuplicate) {
          triggerFlyingDustAnimation(context, result.dustGained);
        }
        await _showReward(result);
        setState(() => _isOpening = false);
      }
    } else {
      setState(() => _isOpening = false);
    }
  }

  Future<void> _showReward(GachaResult result) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: result.card.rarity.color, width: 3),
            boxShadow: [BoxShadow(color: result.card.rarity.color.withOpacity(0.6), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(result.isDuplicate ? "DUPLICATE!" : "NEW CARD!",
                  style: GoogleFonts.blackOpsOne(
                      color: result.isDuplicate ? Colors.purpleAccent : Colors.white,
                      fontSize: 24
                  )
              ),
              const SizedBox(height: 20),

              if (result.isDuplicate)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_fix_high, size: 16, color: Colors.purpleAccent),
                      const SizedBox(width: 5),
                      Text("+${result.dustGained} Dust", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(result.card.imagePath, height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text(result.card.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(result.card.rarity.label, style: TextStyle(color: result.card.rarity.color)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: result.card.rarity.color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text("COLLECT", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>();
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              const TopBar(title: "Chest Room"),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (ctx, child) {
                        double dx = sin(_shakeCtrl.value * pi * 4) * 10;
                        return Transform.translate(offset: Offset(dx, 0), child: child);
                      },
                      child: GestureDetector(
                        onTap: _triggerOpen,
                        child: Container(
                          decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 50, spreadRadius: 10)]
                          ),
                          child: Opacity(
                            opacity: _isOpening ? 0.8 : 1.0,
                            child: Image.asset('assets/images/chest_modern.jpg', width: 220),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    IgnorePointer(
                      ignoring: _isOpening,
                      child: ElevatedButton(
                        onPressed: _triggerOpen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.canAffordChest ? (_isOpening ? Colors.grey : Colors.amber) : Colors.grey[800],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isOpening
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Column(
                          children: [
                            const Text("OPEN CHEST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text("500 Gold", style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6))),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COLLECTION SCREEN
// ============================================================================

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>();
    return SafeArea(
      child: Column(
        children: [
          const TopBar(title: "Collection"),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // --- NOU: Text pentru Counter (Ex: 6/12) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Mastery", style: TextStyle(color: Colors.white70)),
                          Text(
                              "Unlocked: ${state.unlockedCards.length} / ${masterCardList.length}",
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: state.progressValue,
                        color: Colors.amber,
                        backgroundColor: Colors.white10,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: masterCardList.length,
                    itemBuilder: (ctx, i) {
                      final card = masterCardList[i];
                      final count = state.getCardCount(card.id);
                      final isUnlocked = count > 0;
                      return Opacity(
                        opacity: isUnlocked ? 1.0 : 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: isUnlocked ? Border.all(color: card.rarity.color, width: 2) : null,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: isUnlocked
                                      ? Image.asset(card.imagePath, fit: BoxFit.cover)
                                      : Container(color: Colors.black26, child: const Icon(Icons.lock)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(isUnlocked ? "x$count" : "Locked", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP BAR
// ============================================================================

class TopBar extends StatelessWidget {
  final String title;
  const TopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1F1F1F),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.blackOpsOne(fontSize: 22, color: Colors.white)),
              Row(
                children: [
                  _resIcon(Icons.monetization_on, "${state.gold}", Colors.amber),
                  const SizedBox(width: 8),
                  _resIcon(Icons.diamond, "${state.gems}", Colors.cyan),
                ],
              )
            ],
          ),

          AnimatedOpacity(
            opacity: state.isDustVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Column(
              children: [
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: state.dust.toDouble()),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    double percentage = (value / 100.0).clamp(0.0, 1.0);
                    bool isReadyToRedeem = value >= 100;

                    return Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: percentage,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: isReadyToRedeem ? Colors.greenAccent : Colors.purpleAccent,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                        color: isReadyToRedeem ? Colors.green.withOpacity(0.5) : Colors.purple.withOpacity(0.5),
                                        blurRadius: 4
                                    )
                                  ]
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                      key: dustTargetKey,
                      child: Text(
                          state.dust >= 100 ? "REDEEM NOW! (${state.dust} Dust)" : "${state.dust} / 100 Dust",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: state.dust >= 100 ? Colors.greenAccent : Colors.purpleAccent
                          )
                      )
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resIcon(IconData icon, String txt, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.4))),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(txt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}