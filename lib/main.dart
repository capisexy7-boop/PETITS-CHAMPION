import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PetitsChampionsApp());

const Color navy = Color(0xFF26345D);
const Color purple = Color(0xFF7357D8);
const Color cream = Color(0xFFFFF9EF);
const MethodChannel speechChannel = MethodChannel('petits_champions/speech');

class PetitsChampionsApp extends StatelessWidget {
  const PetitsChampionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petits Champions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
            seedColor: purple, brightness: Brightness.light),
        fontFamily: 'Arial',
      ),
      home: const IntroPage(),
    );
  }
}

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _mascotScale;
  late final Animation<double> _mascotOpacity;
  late final Animation<double> _greetingOpacity;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _mascotScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _mascotOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _greetingOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.easeIn),
    );
    _controller.forward();
    _navigationTimer = Timer(
      const Duration(milliseconds: 1900),
      _openHome,
    );
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: purple,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _mascotOpacity,
                  child: ScaleTransition(
                    scale: _mascotScale,
                    child: Container(
                      width: 220,
                      height: 220,
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1D1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/images/leo.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _greetingOpacity,
                  child: const Column(
                    children: [
                      Text(
                        'PETIT CHAMPION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Coucou Champion ! 🦁',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ProgressStore {
  static const String _starsKey = 'stars';
  static const String _doneKey = 'lessons_done';
  static const String _nameKey = 'child_name';
  static const String _languageReviewKey = 'language_review_words';
  static const String _speechEnabledKey = 'speech_enabled';
  static const String _dailyChallengesKey = 'daily_challenges_completed';
  static const String _quizCorrectKey = 'quiz_correct';
  static const String _quizWrongKey = 'quiz_wrong';
  static const String _childAgeKey = 'child_age';

  static Future<int> stars() async =>
      (await SharedPreferences.getInstance()).getInt(_starsKey) ?? 0;
  static Future<int> done() async =>
      (await SharedPreferences.getInstance()).getInt(_doneKey) ?? 0;
  static Future<int> childAge() async =>
      (await SharedPreferences.getInstance()).getInt(_childAgeKey) ?? 5;
  static Future<Map<String, int>> quizStats() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = <String, int>{
      'correct': (prefs.getInt(_quizCorrectKey) ?? 0) +
          (prefs.getInt('math_correct') ?? 0),
      'wrong': (prefs.getInt(_quizWrongKey) ?? 0) +
          (prefs.getInt('math_wrong') ?? 0),
    };
    for (final kind in ['letters', 'colors', 'world', 'phrases']) {
      stats['${kind}_correct'] = prefs.getInt('quiz_${kind}_correct') ?? 0;
      stats['${kind}_total'] = prefs.getInt('quiz_${kind}_total') ?? 0;
    }
    stats['math_correct'] = prefs.getInt('math_correct') ?? 0;
    stats['math_total'] = prefs.getInt('math_total') ?? 0;
    return stats;
  }

  static Future<bool> speechEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_speechEnabledKey) ??
      true;
  static Future<Set<int>> completedChallenges() async {
    final values = (await SharedPreferences.getInstance())
            .getStringList(_dailyChallengesKey) ??
        const [];
    return values.map(int.tryParse).whereType<int>().toSet();
  }

  static Future<String> name() async =>
      (await SharedPreferences.getInstance()).getString(_nameKey) ?? 'Champion';

  static Future<void> reward() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStars = prefs.getInt(_starsKey) ?? 0;
    final currentDone = prefs.getInt(_doneKey) ?? 0;
    await prefs.setInt(_starsKey, currentStars + 1);
    await prefs.setInt(_doneKey, currentDone + 1);
  }

  static Future<void> recordQuiz({
    required String kind,
    required int correct,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final wrong = total - correct;
    await prefs.setInt(
        _quizCorrectKey, (prefs.getInt(_quizCorrectKey) ?? 0) + correct);
    await prefs.setInt(
        _quizWrongKey, (prefs.getInt(_quizWrongKey) ?? 0) + wrong);
    final correctKey = 'quiz_${kind}_correct';
    final totalKey = 'quiz_${kind}_total';
    await prefs.setInt(correctKey, (prefs.getInt(correctKey) ?? 0) + correct);
    await prefs.setInt(totalKey, (prefs.getInt(totalKey) ?? 0) + total);
  }

  static Future<void> recordMathAnswer({required bool correct}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = correct ? 'math_correct' : 'math_wrong';
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
    await prefs.setInt('math_total', (prefs.getInt('math_total') ?? 0) + 1);
  }

  static Future<void> setName(String value) async {
    await (await SharedPreferences.getInstance())
        .setString(_nameKey, value.trim().isEmpty ? 'Champion' : value.trim());
  }

  static Future<void> setSpeechEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_speechEnabledKey, value);

  static Future<void> setChildAge(int value) async =>
      (await SharedPreferences.getInstance()).setInt(_childAgeKey, value);

  static Future<void> completeChallenge(int? day) async {
    if (day == null) return;
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_dailyChallengesKey) ?? [];
    final dayKey = day.toString();
    if (!completed.contains(dayKey)) {
      completed.add(dayKey);
      await prefs.setStringList(_dailyChallengesKey, completed);
    }
  }

  static Future<List<String>> languageReviewWords() async =>
      (await SharedPreferences.getInstance())
          .getStringList(_languageReviewKey) ??
      const [];

  static Future<void> setLanguageWordForReview(
      String key, bool shouldReview) async {
    final prefs = await SharedPreferences.getInstance();
    final words = prefs.getStringList(_languageReviewKey) ?? [];
    if (shouldReview && !words.contains(key)) {
      words.add(key);
    } else if (!shouldReview) {
      words.remove(key);
    }
    await prefs.setStringList(_languageReviewKey, words);
  }
}

class DailyChallenge {
  final int day;
  final String kind;
  final String title;
  final String emoji;

  const DailyChallenge({
    required this.day,
    required this.kind,
    required this.title,
    required this.emoji,
  });
}

final List<DailyChallenge> dailyChallenges = List.generate(30, (index) {
  const themes = [
    ('letters', 'Jouer avec les lettres', '🔤'),
    ('colors', 'Découvrir les couleurs', '🎨'),
    ('world', 'Explorer le monde', '🌍'),
  ];
  final (kind, title, emoji) = themes[index % themes.length];
  return DailyChallenge(
    day: index + 1,
    kind: kind,
    title: title,
    emoji: emoji,
  );
});

class _LanguageReviewWord {
  final String topic;
  final String source;
  final String target;
  final int index;

  const _LanguageReviewWord({
    required this.topic,
    required this.source,
    required this.target,
    required this.index,
  });

  String get storageKey => jsonEncode([topic, source, target, index]);

  static _LanguageReviewWord? fromStorageKey(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List &&
          decoded.length == 4 &&
          decoded[0] is String &&
          decoded[1] is String &&
          decoded[2] is String &&
          decoded[3] is int) {
        return _LanguageReviewWord(
          topic: decoded[0] as String,
          source: decoded[1] as String,
          target: decoded[2] as String,
          index: decoded[3] as int,
        );
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int stars = 0;
  int done = 0;
  String childName = 'Champion';
  Set<int> completedChallenges = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final nextStars = await ProgressStore.stars();
    final nextDone = await ProgressStore.done();
    final nextName = await ProgressStore.name();
    final nextChallenges = await ProgressStore.completedChallenges();
    if (!mounted) return;
    setState(() {
      stars = nextStars;
      done = nextDone;
      childName = nextName;
      completedChallenges = nextChallenges;
    });
  }

  Future<void> _openScreen(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await _refresh();
  }

  Future<void> _openParentPage() async {
    final isParent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ParentAccessDialog(),
    );
    if (isParent == true && mounted) {
      await _openScreen(const ParentPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final earnedBadges =
        [1, 5, 10].where((threshold) => stars >= threshold).length;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF1D1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/leo.png'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PETITS CHAMPIONS',
                            style: TextStyle(
                                color: purple,
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w900)),
                        Text('Salut $childName !',
                            style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: navy)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1D1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text('⭐ $stars',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: navy)),
                  ),
                  IconButton(
                    tooltip: 'Espace parents',
                    onPressed: _openParentPage,
                    icon: const Icon(Icons.lock_outline_rounded,
                        size: 25, color: navy),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8068E8),
                            Color(0xFF5A64D8),
                            Color(0xFF36AFC0),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Coucou Champion !',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900)),
                                SizedBox(height: 4),
                                Text('Chaque jour, une découverte !',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.82, end: 1),
                            duration: const Duration(milliseconds: 650),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: Image.asset('assets/images/leo.png',
                                width: 76, height: 76),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 68,
                      top: -18,
                      child: IgnorePointer(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Text('✨', style: TextStyle(fontSize: 21)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Choisis ton aventure',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: navy)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _activityCard(
                        index: 0,
                        width: cardWidth,
                        emoji: '🔢',
                        title: 'Mes nombres',
                        color: const Color(0xFF38B887),
                        onTap: () => _openScreen(const MathHubPage()),
                      ),
                      _activityCard(
                        index: 1,
                        width: cardWidth,
                        emoji: '🔤',
                        title: 'Mes lettres',
                        color: const Color(0xFFFFA64D),
                        onTap: () =>
                            _openScreen(const QuizHubPage(kind: 'letters')),
                      ),
                      _activityCard(
                        index: 2,
                        width: cardWidth,
                        emoji: '🎨',
                        title: 'Mes couleurs',
                        color: const Color(0xFFAD7BE8),
                        onTap: () =>
                            _openScreen(const QuizHubPage(kind: 'colors')),
                      ),
                      _activityCard(
                        index: 3,
                        width: cardWidth,
                        emoji: '🌍',
                        title: 'Mes découvertes',
                        color: const Color(0xFF40B8B0),
                        onTap: () =>
                            _openScreen(const QuizHubPage(kind: 'world')),
                      ),
                      _activityCard(
                        index: 4,
                        width: cardWidth,
                        emoji: '🗣️',
                        title: 'Mes mots',
                        color: const Color(0xFF4D9DE0),
                        onTap: () => _openScreen(const LanguageHubPage()),
                      ),
                      _activityCard(
                        index: 5,
                        width: cardWidth,
                        emoji: '🐾',
                        title: 'Mes défis',
                        color: const Color(0xFFFFB85C),
                        progress: '${completedChallenges.length}/30',
                        onTap: () => _openScreen(const DailyChallengePage()),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Color(0xFFE0A52B), size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Badges de champion',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, color: navy)),
                      ),
                      Text('$earnedBadges / 3',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, color: navy)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) _openScreen(const DailyChallengePage());
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.toys_rounded),
            label: 'Jouer',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_rounded),
            label: 'Parcours',
          ),
        ],
      ),
    );
  }

  Widget _activityCard({
    required int index,
    required double width,
    required String emoji,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? progress,
  }) =>
      _HomeActivityCard(
        index: index,
        width: width,
        emoji: emoji,
        title: title,
        color: color,
        onTap: onTap,
        progress: progress,
      );
}

class _HomeActivityCard extends StatefulWidget {
  const _HomeActivityCard({
    required this.index,
    required this.width,
    required this.emoji,
    required this.title,
    required this.color,
    required this.onTap,
    this.progress,
  });

  final int index;
  final double width;
  final String emoji;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? progress;

  @override
  State<_HomeActivityCard> createState() => _HomeActivityCardState();
}

class _HomeActivityCardState extends State<_HomeActivityCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: Duration(milliseconds: 350 + widget.index * 55),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: widget.width,
            height: 140,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      widget.color.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: widget.color.withValues(alpha: 0.40), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.13),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: widget.onTap,
                  onHighlightChanged: (pressed) {
                    if (_pressed != pressed) {
                      setState(() => _pressed = pressed);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.28),
                                widget.color.withValues(alpha: 0.10),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(widget.emoji,
                              style: const TextStyle(fontSize: 36)),
                        ),
                        const SizedBox(height: 6),
                        Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: navy)),
                        if (widget.progress != null)
                          Text(widget.progress!,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class ParentAccessDialog extends StatefulWidget {
  const ParentAccessDialog({super.key});

  @override
  State<ParentAccessDialog> createState() => _ParentAccessDialogState();
}

class _ParentAccessDialogState extends State<ParentAccessDialog> {
  final TextEditingController _answerController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (int.tryParse(_answerController.text.trim()) == 15) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _error = 'Réponse incorrecte. Réessaie ou ferme cette fenêtre.';
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Espace réservé aux parents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pour continuer, combien font 8 + 7 ?'),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Ta réponse',
                errorText: _error,
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _checkAnswer,
            child: const Text('Continuer'),
          ),
        ],
      );
}

class ParentPage extends StatefulWidget {
  const ParentPage({super.key});

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  final TextEditingController _controller = TextEditingController();
  int stars = 0;
  int done = 0;
  int childAge = 5;
  bool speechEnabled = true;
  Map<String, int> quizStatistics = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await ProgressStore.name();
    final nextStars = await ProgressStore.stars();
    final nextDone = await ProgressStore.done();
    final nextSpeechEnabled = await ProgressStore.speechEnabled();
    final nextQuizStatistics = await ProgressStore.quizStats();
    final nextChildAge = await ProgressStore.childAge();
    if (!mounted) return;
    _controller.text = name;
    setState(() {
      stars = nextStars;
      done = nextDone;
      childAge = nextChildAge;
      speechEnabled = nextSpeechEnabled;
      quizStatistics = nextQuizStatistics;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace parent')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Petit suivi familial',
              style: TextStyle(
                  fontSize: 23, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 10),
          const Text('Les progrès restent enregistrés sur cet appareil.'),
          const SizedBox(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prononciation audio'),
            subtitle: const Text('Autoriser la lecture des mots à voix haute'),
            value: speechEnabled,
            onChanged: (value) async {
              await ProgressStore.setSpeechEnabled(value);
              if (!mounted) return;
              setState(() => speechEnabled = value);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: childAge,
            decoration: const InputDecoration(
              labelText: 'Âge de l’enfant',
              border: OutlineInputBorder(),
            ),
            items: [1, 2, 3, 4, 5]
                .map((age) => DropdownMenuItem(
                      value: age,
                      child: Text('$age ${age == 1 ? 'an' : 'ans'}'),
                    ))
                .toList(),
            onChanged: (value) async {
              if (value == null) return;
              await ProgressStore.setChildAge(value);
              if (!mounted) return;
              setState(() => childAge = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Prénom de l’enfant',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final value = _controller.text;
              await ProgressStore.setName(value);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prénom enregistré !')),
              );
            },
            child: const Text('Enregistrer'),
          ),
          const SizedBox(height: 24),
          Text('⭐ $stars étoiles gagnées'),
          const SizedBox(height: 8),
          Text('🏅 $done activités terminées'),
          const SizedBox(height: 20),
          const Text('Résultats des activités',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 8),
          _quizSummary(),
          const SizedBox(height: 14),
          ...[
            ('letters', 'Alphabet', const Color(0xFFFFA64D)),
            ('colors', 'Couleurs', const Color(0xFFAD7BE8)),
            ('world', 'Découverte', const Color(0xFF40B8B0)),
            ('phrases', 'Petites phrases', const Color(0xFF4D9DE0)),
            ('math', 'Mathématiques', const Color(0xFF38B887)),
          ].map(
            (subject) => _subjectProgress(
              subject.$1,
              subject.$2,
              subject.$3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
              'Conseil : des pauses courtes et des félicitations régulières motivent encore plus.',
              style: TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Widget _quizSummary() {
    final correct = quizStatistics['correct'] ?? 0;
    final wrong = quizStatistics['wrong'] ?? 0;
    final total = correct + wrong;
    final percentage = total == 0 ? 0 : (100 * correct / total).round();
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$correct bonnes • $wrong à retravailler',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, color: navy)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total == 0 ? 0 : correct / total,
              minHeight: 9,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF38B887),
              backgroundColor: const Color(0xFF38B887).withValues(alpha: 0.15),
            ),
            const SizedBox(height: 6),
            Text(total == 0
                ? 'Le taux de réussite apparaîtra après un quiz.'
                : 'Réussite : $percentage %'),
          ],
        ),
      ),
    );
  }

  Widget _subjectProgress(String kind, String title, Color color) {
    final total = quizStatistics['${kind}_total'] ?? 0;
    final correct = quizStatistics['${kind}_correct'] ?? 0;
    return Card(
      color: Colors.white,
      child: ListTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : correct / total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        trailing: Text('$correct / $total'),
      ),
    );
  }
}

class DailyChallengePage extends StatefulWidget {
  const DailyChallengePage({super.key});

  @override
  State<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends State<DailyChallengePage> {
  Set<int> _completed = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await ProgressStore.completedChallenges();
    if (!mounted) return;
    setState(() {
      _completed = completed;
      _isLoading = false;
    });
  }

  Future<void> _startChallenge(DailyChallenge challenge) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizHubPage(
          kind: challenge.kind,
          questionLimit: 5,
          challengeDay: challenge.day,
        ),
      ),
    );
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parcours de 30 jours')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${_completed.length} / 30 défis terminés',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: navy),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choisis un défi. Tu peux reprendre n’importe quel jour, à ton rythme.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: _completed.length / dailyChallenges.length,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                  color: purple,
                  backgroundColor: purple.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 16),
                ...dailyChallenges.map((challenge) {
                  final isComplete = _completed.contains(challenge.day);
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 9),
                    child: ListTile(
                      leading: Text(challenge.emoji,
                          style: const TextStyle(fontSize: 28)),
                      title: Text('Jour ${challenge.day}'),
                      subtitle: Text(challenge.title),
                      trailing: isComplete
                          ? const Icon(Icons.check_circle_rounded,
                              color: Colors.green)
                          : const Icon(Icons.play_circle_fill_rounded,
                              color: purple),
                      onTap: () => _startChallenge(challenge),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class MathHubPage extends StatelessWidget {
  const MathHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔢 Mathématiques')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('On apprend doucement !',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 10),
          const Text(
              'Addition et soustraction, sans pression, avec de petits nombres.'),
          const SizedBox(height: 20),
          _mathTile(context, '📘', 'Leçon +', 'Comprendre l’addition',
              () => const MathLessonPage(isAddition: true)),
          _mathTile(context, '📘', 'Leçon −', 'Comprendre la soustraction',
              () => const MathLessonPage(isAddition: false)),
          _mathTile(context, '🍎', 'Je joue', 'Calculs jusqu’à 10',
              () => const MathGamePage()),
          _mathTile(
              context,
              '🐟',
              'Je compte',
              'Compter les objets jusqu’à 10',
              () => const MathGamePage(
                    mode: MathGameMode.counting,
                    questionLimit: 30,
                  )),
          _mathTile(
              context,
              '🔢',
              'Je reconnais les chiffres',
              'Associer les objets au chiffre',
              () => const MathGamePage(
                    mode: MathGameMode.numbers,
                    questionLimit: 30,
                  )),
          _mathTile(
              context,
              '⚖️',
              'Je compare',
              'Trouver plus, moins ou autant',
              () => const MathConceptGamePage(mode: MathConceptMode.compare)),
          _mathTile(
              context,
              '🔺',
              'Je découvre les formes',
              'Reconnaître les formes',
              () => const MathConceptGamePage(mode: MathConceptMode.shapes)),
          _mathTile(
              context,
              '🟠',
              'Je continue les suites',
              'Trouver ce qui vient après',
              () => const MathConceptGamePage(mode: MathConceptMode.patterns)),
        ],
      ),
    );
  }

  Widget _mathTile(BuildContext context, String emoji, String title,
      String subtitle, Widget Function() pageBuilder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => pageBuilder())),
      ),
    );
  }
}

class MathLessonPage extends StatefulWidget {
  final bool isAddition;

  const MathLessonPage({super.key, required this.isAddition});

  @override
  State<MathLessonPage> createState() => _MathLessonPageState();
}

class _MathLessonPageState extends State<MathLessonPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isAddition
              ? 'Apprendre l’addition'
              : 'Apprendre la soustraction')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 126,
                height: 126,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1D1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: widget.isAddition
                    ? const Center(
                        child: Text('🐘', style: TextStyle(fontSize: 76)))
                    : Image.asset('assets/images/leo.png'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isAddition ? 'On rassemble !' : 'On en enlève !',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: navy),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isAddition
                  ? '🐘 a 3 pommes. Il en reçoit 2 de plus !'
                  : 'Léo a 5 bananes. Il en donne 2 !',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, color: navy),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: widget.isAddition
                        ? const [
                            Text('🍎🍎🍎', style: TextStyle(fontSize: 30)),
                            Text('+',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: navy)),
                            Text('🍎🍎', style: TextStyle(fontSize: 30)),
                          ]
                        : const [
                            Text('🍌🍌🍌🍌🍌', style: TextStyle(fontSize: 30)),
                          ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.isAddition ? '3 + 2 = 5 🍎' : '5 − 2 = 3 🍌',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 27, fontWeight: FontWeight.w900, color: navy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.isAddition
                  ? 'Ajouter, c’est réunir les objets.'
                  : 'Soustraire, c’est enlever des objets.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: navy),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MathGamePage(
                      isAdditionOnly: widget.isAddition,
                      questionLimit: 30,
                    ),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: const Text('À toi de jouer !',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MathGamePage extends StatefulWidget {
  final MathGameMode mode;
  final bool? isAdditionOnly;
  final int? questionLimit;

  const MathGamePage({
    super.key,
    this.mode = MathGameMode.operations,
    this.isAdditionOnly,
    this.questionLimit,
  });

  @override
  State<MathGamePage> createState() => _MathGamePageState();
}

enum MathGameMode { operations, counting, numbers }

class _MathGamePageState extends State<MathGamePage> {
  final Random _random = Random();
  static const List<String> _objects = [
    '🍎',
    '🍌',
    '⭐',
    '🐟',
    '🍬',
    '🌸',
    '🚗',
    '🐞',
    '🧸',
    '🍪',
    '⚽',
    '🚀',
    '🐸',
    '🦋',
    '🥕',
    '🍉',
  ];
  int _a = 2;
  int _b = 3;
  int _answer = 5;
  int _score = 0;
  int _questionNumber = 1;
  int _maxValue = 10;
  String _object = '🍎';
  List<int> _choices = [];
  bool _isAddition = true;
  String _message = '';
  bool _locked = false;
  bool _isComplete = false;
  int? _selectedOption;
  final Set<String> _usedQuestions = {};
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAgeAndStart());
  }

  Future<void> _loadAgeAndStart() async {
    final age = await ProgressStore.childAge();
    if (!mounted) return;
    _maxValue = switch (age) {
      <= 2 => 3,
      3 => 5,
      4 => 8,
      _ => 10,
    };
    _newQuestion();
  }

  void _newQuestion() {
    _advanceTimer?.cancel();
    if (widget.questionLimit != null &&
        _questionNumber > widget.questionLimit!) {
      setState(() {
        _isComplete = true;
        _locked = true;
        _message = 'Bravo, tu as terminé !';
      });
      return;
    }

    final difficulty = min(
      _maxValue,
      _questionNumber <= 10 ? 3 : (_questionNumber <= 20 ? 6 : _maxValue),
    );
    if (widget.mode != MathGameMode.operations) {
      _isAddition = true;
      final modeKey = widget.mode == MathGameMode.counting ? 'count' : 'number';
      final available = [
        for (var value = 1; value <= difficulty; value++)
          for (final object in _objects)
            if (!_usedQuestions.contains('$modeKey:$value:$object'))
              (value, object),
      ];
      final selected = available[_random.nextInt(available.length)];
      _a = selected.$1;
      _b = 0;
      _answer = _a;
      _object = selected.$2;
      _usedQuestions.add('$modeKey:$_a:$_object');
      final options = <int>{_answer};
      final optionCount = min(4, _maxValue);
      while (options.length < optionCount) {
        options.add((_answer + _random.nextInt(7) - 3).clamp(1, _maxValue));
      }
      setState(() {
        _choices = options.toList()..shuffle();
        _message = '';
        _locked = false;
        _selectedOption = null;
      });
      return;
    }

    _isAddition = widget.isAdditionOnly ?? _random.nextBool();
    final pairs = <(int, int)>[];
    if (_isAddition) {
      for (var first = 1; first <= difficulty; first++) {
        for (var second = 1; second <= difficulty; second++) {
          if (first + second <= _maxValue) pairs.add((first, second));
        }
      }
    } else {
      for (var first = 2; first <= difficulty; first++) {
        for (var second = 1; second < first; second++) {
          pairs.add((first, second));
        }
      }
    }

    var available = [
      for (final pair in pairs)
        for (final object in _objects)
          if (!_usedQuestions.contains(
              '${_isAddition ? '+' : '-'}:${pair.$1}:${pair.$2}:$object'))
            (pair.$1, pair.$2, object),
    ];
    if (available.isEmpty && widget.questionLimit == null) {
      _usedQuestions.clear();
      available = [
        for (final pair in pairs)
          for (final object in _objects) (pair.$1, pair.$2, object),
      ];
    }
    if (available.isEmpty) {
      final allPairs = <(int, int)>[];
      if (_isAddition) {
        for (var first = 1; first < _maxValue; first++) {
          for (var second = 1; second <= _maxValue - first; second++) {
            allPairs.add((first, second));
          }
        }
      } else {
        for (var first = 2; first <= _maxValue; first++) {
          for (var second = 1; second < first; second++) {
            allPairs.add((first, second));
          }
        }
      }
      available = [
        for (final pair in allPairs)
          for (final object in _objects)
            if (!_usedQuestions.contains(
                '${_isAddition ? '+' : '-'}:${pair.$1}:${pair.$2}:$object'))
              (pair.$1, pair.$2, object),
      ];
    }
    if (available.isEmpty) {
      throw StateError('No unique math questions remain for this session.');
    }

    final selected = available[_random.nextInt(available.length)];
    _a = selected.$1;
    _b = selected.$2;
    _object = selected.$3;
    _answer = _isAddition ? _a + _b : _a - _b;
    _usedQuestions.add('${_isAddition ? '+' : '-'}:$_a:$_b:$_object');
    final options = <int>{_answer};
    final otherOptions = [
      for (var value = 0; value <= _maxValue; value++)
        if (value != _answer) value,
    ]..shuffle(_random);
    options.addAll(otherOptions.take(min(4, _maxValue + 1) - 1));

    setState(() {
      _choices = options.toList()..shuffle();
      _message = '';
      _locked = false;
      _selectedOption = null;
    });
  }

  Future<void> _checkAnswer(int choice) async {
    if (_locked) return;

    final isCorrect = choice == _answer;
    setState(() {
      _selectedOption = choice;
      _locked = isCorrect;
      if (isCorrect) {
        _score += 1;
        _message = 'Bravo, tu as trouvé ! 🌟';
      } else {
        _message = 'Essaie encore ! Compte les objets.';
      }
    });

    await ProgressStore.recordMathAnswer(correct: isCorrect);
    if (isCorrect) {
      await ProgressStore.reward();
      _advanceTimer = Timer(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() => _questionNumber++);
        _newQuestion();
      });
    }
  }

  Widget _objectGroup(int count, {int crossedOut = 0}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 0,
      children: List.generate(count, (index) {
        final removed = index >= count - crossedOut;
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: removed ? 0.4 : 1,
              child: Text(_object, style: const TextStyle(fontSize: 33)),
            ),
            if (removed)
              const Icon(Icons.close_rounded,
                  size: 31, color: Colors.deepOrange),
          ],
        );
      }),
    );
  }

  Widget _visualOperation() {
    if (widget.mode == MathGameMode.counting) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _objectGroup(_a),
      );
    }
    if (widget.mode == MathGameMode.numbers) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text('$_a',
                style: const TextStyle(
                    fontSize: 78, fontWeight: FontWeight.w900, color: purple)),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          _objectGroup(_a),
          Text(_isAddition ? '+' : '−',
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900, color: navy)),
          _objectGroup(_b, crossedOut: _isAddition ? 0 : _b),
          const Text('=',
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900, color: navy)),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE2A8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('?',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: navy)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Petit défi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Text(
                      widget.questionLimit == null
                          ? '⭐ $_score'
                          : 'Défi $_questionNumber/${widget.questionLimit}  ·  ⭐ $_score',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  if (_isComplete) ...[
                    const SizedBox(height: 32),
                    const Text('🏆', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 12),
                    const Text('Bravo, défi terminé !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: navy)),
                    const SizedBox(height: 12),
                    Text('Tu as réussi $_score exercices.',
                        style: const TextStyle(fontSize: 20, color: navy)),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Terminer'),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    _visualOperation(),
                    const SizedBox(height: 16),
                    Text(
                      switch (widget.mode) {
                        MathGameMode.counting => 'Combien en vois-tu ?',
                        MathGameMode.numbers =>
                          'Trouve la quantité qui correspond !',
                        MathGameMode.operations => _isAddition
                            ? 'Combien y a-t-il en tout ?'
                            : 'Combien en reste-t-il ?',
                      },
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: navy),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio:
                          widget.mode == MathGameMode.numbers ? 1.45 : 2.2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _choices
                          .map(
                            (value) => FilledButton(
                              key: ValueKey(
                                value == _answer
                                    ? 'math-correct-answer'
                                    : 'math-choice-$value',
                              ),
                              onPressed:
                                  _locked ? null : () => _checkAnswer(value),
                              style: FilledButton.styleFrom(
                                backgroundColor: _selectedOption == value
                                    ? value == _answer
                                        ? Colors.green.shade600
                                        : Colors.deepOrange.shade300
                                    : null,
                              ),
                              child: widget.mode == MathGameMode.numbers
                                  ? _objectGroup(value)
                                  : Text('$value',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        _message,
                        key: ValueKey(_message),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: purple),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Terminer')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum MathConceptMode { compare, shapes, patterns }

class _MathConceptQuestion {
  final String picture;
  final String prompt;
  final String correct;
  final List<String> options;

  const _MathConceptQuestion({
    required this.picture,
    required this.prompt,
    required this.correct,
    required this.options,
  });
}

List<_MathConceptQuestion> _mathConceptQuestions(MathConceptMode mode) {
  if (mode == MathConceptMode.compare) {
    const objects = ['🍎', '⭐', '🐟', '🚗', '🌸', '🍌'];
    const answers = ['À gauche', 'À droite', 'Autant'];
    return List.generate(30, (index) {
      final object = objects[index % objects.length];
      final left = index % 5 + 1;
      final right = (index * 2 + 1) % 5 + 1;
      final correct = left > right
          ? 'À gauche'
          : left < right
              ? 'À droite'
              : 'Autant';
      return _MathConceptQuestion(
        picture:
            '${List.filled(left, object).join()}     ${List.filled(right, object).join()}',
        prompt: 'Quel groupe en a le plus ?',
        correct: correct,
        options: answers,
      );
    });
  }

  if (mode == MathConceptMode.shapes) {
    const shapes = [
      ('🔺', 'triangle', '3 côtés'),
      ('🟦', 'carré', '4 côtés égaux'),
      ('🟧', 'rectangle', '4 côtés'),
      ('⚪', 'cercle', 'aucun coin'),
      ('⭐', 'étoile', '5 pointes'),
      ('💎', 'losange', '4 côtés'),
    ];
    const prompts = [
      'Trouve la forme',
      'Montre cette forme',
      'Cherche la forme',
      'Regarde bien la forme',
      'Retrouve cette forme',
    ];
    return List.generate(30, (index) {
      final shape = shapes[index % shapes.length];
      final phrase = prompts[index ~/ shapes.length];
      return _MathConceptQuestion(
        picture: '🧩',
        prompt: '$phrase : ${shape.$2} !',
        correct: '${shape.$1} ${shape.$2}',
        options: shapes.map((item) => '${item.$1} ${item.$2}').toList(),
      );
    });
  }

  const pairs = [
    ('🔴', '🔵'),
    ('🟡', '🟢'),
    ('🍎', '🍌'),
    ('🐱', '🐶'),
    ('⭐', '🌙'),
    ('🚗', '🚌'),
    ('🌸', '🌼'),
    ('🟣', '🟠'),
    ('🐟', '🐠'),
    ('⚽', '🏀'),
  ];
  return List.generate(30, (index) {
    final pair = pairs[index ~/ 3];
    final pattern = switch (index % 3) {
      0 => '${pair.$1} ${pair.$2} ${pair.$1} ${pair.$2} ?',
      1 => '${pair.$1} ${pair.$1} ${pair.$2} ${pair.$1} ${pair.$1} ?',
      _ =>
        '${pair.$1} ${pair.$2} ${pair.$2} ${pair.$1} ${pair.$2} ${pair.$2} ?',
    };
    return _MathConceptQuestion(
      picture: pattern,
      prompt: 'Que faut-il mettre après ?',
      correct: switch (index % 3) {
        0 => pair.$1,
        1 => pair.$2,
        _ => pair.$1,
      },
      options: {
        pair.$1,
        pair.$2,
        '⭐',
        '🍎',
        '🟢',
        '🐟',
      }.take(4).toList(),
    );
  });
}

class MathConceptGamePage extends StatefulWidget {
  final MathConceptMode mode;

  const MathConceptGamePage({super.key, required this.mode});

  @override
  State<MathConceptGamePage> createState() => _MathConceptGamePageState();
}

class _MathConceptGamePageState extends State<MathConceptGamePage> {
  late final List<_MathConceptQuestion> _questions =
      _mathConceptQuestions(widget.mode);
  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _complete = false;
  Timer? _advanceTimer;

  _MathConceptQuestion get _question => _questions[_index];

  String get _title => switch (widget.mode) {
        MathConceptMode.compare => 'Je compare',
        MathConceptMode.shapes => 'Les formes',
        MathConceptMode.patterns => 'Les suites',
      };

  Future<void> _answer(String choice) async {
    if (_selected != null) return;
    final correct = choice == _question.correct;
    setState(() {
      _selected = choice;
      if (correct) _score++;
    });
    await ProgressStore.recordMathAnswer(correct: correct);
    if (!correct) return;
    await ProgressStore.reward();
    _advanceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_index == _questions.length - 1) {
        setState(() => _complete = true);
      } else {
        setState(() {
          _index++;
          _selected = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_complete) ...[
                const SizedBox(height: 60),
                const Text('🏆',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 80)),
                const SizedBox(height: 12),
                const Text('Bravo, tu as terminé !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: navy)),
                Text('$_score étoiles gagnées',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Terminer')),
              ] else ...[
                Text('Défi ${_index + 1}/30  ·  ⭐ $_score',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: navy)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_index + 1) / _questions.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: purple,
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(_question.picture,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 20),
                Text(_question.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: navy)),
                const SizedBox(height: 20),
                ..._question.options.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        height: 58,
                        child: FilledButton.tonal(
                          key: ValueKey(option == _question.correct
                              ? 'concept-correct-answer'
                              : 'concept-$option'),
                          onPressed:
                              _selected == null ? () => _answer(option) : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _selected == option
                                ? option == _question.correct
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100
                                : null,
                          ),
                          child: Text(option,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    )),
                if (_selected != null)
                  Text(
                    _selected == _question.correct
                        ? 'Bravo, tu as trouvé ! 🌟'
                        : 'Essaie encore, tu vas y arriver !',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: purple),
                  ),
              ],
            ],
          ),
        ),
      );
}

const Map<String, String> languages = {
  'Français': 'fr-FR',
  'English': 'en-US',
  'Español': 'es-ES',
  'Deutsch': 'de-DE',
};

class LearningPhrase {
  const LearningPhrase({
    required this.id,
    required this.emoji,
    required this.fr,
    required this.en,
    required this.es,
  });

  final String id;
  final String emoji;
  final String fr;
  final String en;
  final String es;

  String inLanguage(String language) => switch (language) {
        'Français' => fr,
        'English' => en,
        'Español' => es,
        _ => throw ArgumentError.value(language, 'language'),
      };
}

const List<LearningPhrase> learningPhrases = [
  LearningPhrase(
    id: 'greeting',
    emoji: '👋',
    fr: 'Bonjour, comment ça va ?',
    en: 'Hello, how are you?',
    es: 'Hola, ¿cómo estás?',
  ),
  LearningPhrase(
    id: 'name',
    emoji: '🦁',
    fr: 'Je m’appelle Léo.',
    en: 'My name is Leo.',
    es: 'Me llamo Leo.',
  ),
  LearningPhrase(
    id: 'apples',
    emoji: '🍎',
    fr: 'J’aime les pommes.',
    en: 'I like apples.',
    es: 'Me gustan las manzanas.',
  ),
  LearningPhrase(
    id: 'small-cat',
    emoji: '🐱',
    fr: 'Le chat est petit.',
    en: 'The cat is small.',
    es: 'El gato es pequeño.',
  ),
  LearningPhrase(
    id: 'ball',
    emoji: '⚽',
    fr: 'Où est mon ballon ?',
    en: 'Where is my ball?',
    es: '¿Dónde está mi pelota?',
  ),
  LearningPhrase(
    id: 'play',
    emoji: '🧸',
    fr: 'Je veux jouer.',
    en: 'I want to play.',
    es: 'Quiero jugar.',
  ),
  LearningPhrase(
    id: 'sun',
    emoji: '☀️',
    fr: 'Le soleil brille.',
    en: 'The sun is shining.',
    es: 'El sol brilla.',
  ),
  LearningPhrase(
    id: 'school',
    emoji: '🏫',
    fr: 'Je vais à l’école.',
    en: 'I go to school.',
    es: 'Voy a la escuela.',
  ),
  LearningPhrase(
    id: 'running-dog',
    emoji: '🐕',
    fr: 'Le chien court.',
    en: 'The dog is running.',
    es: 'El perro corre.',
  ),
  LearningPhrase(
    id: 'family',
    emoji: '👨‍👩‍👧‍👦',
    fr: 'J’aime ma famille.',
    en: 'I love my family.',
    es: 'Amo a mi familia.',
  ),
  LearningPhrase(
    id: 'moon',
    emoji: '🌙',
    fr: 'La lune est belle.',
    en: 'The moon is beautiful.',
    es: 'La luna es bonita.',
  ),
  LearningPhrase(
    id: 'water',
    emoji: '💧',
    fr: 'Je bois de l’eau.',
    en: 'I drink water.',
    es: 'Bebo agua.',
  ),
  LearningPhrase(
    id: 'flower',
    emoji: '🌹',
    fr: 'La fleur est rouge.',
    en: 'The flower is red.',
    es: 'La flor es roja.',
  ),
  LearningPhrase(
    id: 'help',
    emoji: '🤝',
    fr: 'Je peux t’aider.',
    en: 'I can help you.',
    es: 'Puedo ayudarte.',
  ),
  LearningPhrase(
    id: 'goodnight',
    emoji: '🌟',
    fr: 'Bonne nuit, petit lion.',
    en: 'Good night, little lion.',
    es: 'Buenas noches, pequeño león.',
  ),
];

enum PhrasePracticeMode { listen, understand, translate }

class PhrasePracticeMenuPage extends StatelessWidget {
  const PhrasePracticeMenuPage({
    super.key,
    required this.source,
    required this.target,
  });

  final String source;
  final String target;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('💬 Les petites phrases')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Écoute, comprends et découvre 15 phrases !',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: navy),
            ),
            const SizedBox(height: 8),
            Text('$source → $target',
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 18),
            _phraseModeCard(
              context,
              emoji: '🔊',
              title: 'J’écoute et je répète',
              subtitle: 'Écoute chaque phrase avec Léo.',
              mode: PhrasePracticeMode.listen,
              color: const Color(0xFF4D9DE0),
            ),
            _phraseModeCard(
              context,
              emoji: '👀',
              title: 'Je comprends',
              subtitle: 'Choisis l’image qui correspond à la phrase.',
              mode: PhrasePracticeMode.understand,
              color: const Color(0xFF38B887),
            ),
            _phraseModeCard(
              context,
              emoji: '🌍',
              title: 'Je trouve la traduction',
              subtitle: 'Relie les phrases dans les deux langues.',
              mode: PhrasePracticeMode.translate,
              color: const Color(0xFFAD7BE8),
            ),
          ],
        ),
      );

  Widget _phraseModeCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required PhrasePracticeMode mode,
    required Color color,
  }) =>
      Card(
        color: color.withValues(alpha: 0.12),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: Text(emoji, style: const TextStyle(fontSize: 32)),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w900, color: navy)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhrasePracticePage(
                source: source,
                target: target,
                mode: mode,
              ),
            ),
          ),
        ),
      );
}

class PhrasePracticePage extends StatefulWidget {
  const PhrasePracticePage({
    super.key,
    required this.source,
    required this.target,
    required this.mode,
  });

  final String source;
  final String target;
  final PhrasePracticeMode mode;

  @override
  State<PhrasePracticePage> createState() => _PhrasePracticePageState();
}

class _PhrasePracticePageState extends State<PhrasePracticePage> {
  final ScrollController _scrollController = ScrollController();
  late final List<LearningPhrase> _phrases = [...learningPhrases]..shuffle();
  late List<LearningPhrase> _options = _buildOptions();
  int _index = 0;
  int _score = 0;
  bool _answeredCorrectly = false;
  bool _finished = false;
  bool _completionSaved = false;
  bool _hadWrongAnswer = false;

  LearningPhrase get _current => _phrases[_index];

  List<LearningPhrase> _buildOptions() {
    final alternatives = _phrases.where((phrase) => phrase != _current).toList()
      ..shuffle();
    return [_current, ...alternatives.take(3)]..shuffle();
  }

  Future<void> _speak(String text, String language) async {
    if (!await ProgressStore.speechEnabled()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La prononciation est désactivée.')),
      );
      return;
    }
    try {
      await speechChannel.invokeMethod<void>('speak', {
        'text': text,
        'language': languages[language] ?? 'fr-FR',
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.code == 'tts_language_unavailable'
          ? 'La voix de cette langue n’est pas installée sur cet appareil.'
          : 'La synthèse vocale n’est pas prête. Réessaie dans un instant.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La synthèse vocale est disponible sur Android.')),
      );
    }
  }

  Future<void> _answer(bool isCorrect) async {
    if (_answeredCorrectly) return;
    if (!isCorrect) {
      setState(() => _hadWrongAnswer = true);
      return;
    }
    setState(() {
      _answeredCorrectly = true;
      _score++;
    });
  }

  Future<void> _next() async {
    unawaited(_stopSpeaking());
    if (_index == _phrases.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _answeredCorrectly = false;
      _hadWrongAnswer = false;
      _options = _buildOptions();
    });
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await speechChannel.invokeMethod<void>('stop');
    } on PlatformException {
      // The audio engine may already be shutting down.
    } on MissingPluginException {
      // Widget tests and non-Android platforms have no native speech channel.
    }
  }

  @override
  void dispose() {
    unawaited(_stopSpeaking());
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_completionSaved) {
      _completionSaved = true;
      if (widget.mode != PhrasePracticeMode.listen) {
        await ProgressStore.recordQuiz(
          kind: 'phrases',
          correct: _score,
          total: _phrases.length,
        );
      }
      await ProgressStore.reward();
    }
    if (!mounted) return;
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      PhrasePracticeMode.listen => 'J’écoute et je répète',
      PhrasePracticeMode.understand => 'Je comprends',
      PhrasePracticeMode.translate => 'Je trouve la traduction',
    };
    final phrase = _current;
    final isListen = widget.mode == PhrasePracticeMode.listen;
    final isUnderstand = widget.mode == PhrasePracticeMode.understand;
    final prompt = isUnderstand
        ? phrase.inLanguage(widget.target)
        : phrase.inLanguage(isListen ? widget.target : widget.source);
    final options = _options;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: _finished
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                key: const ValueKey('phrase-next'),
                onPressed: isListen
                    ? _next
                    : _answeredCorrectly
                        ? _next
                        : null,
                child: Text(
                  _index == _phrases.length - 1
                      ? 'Terminer le jeu'
                      : 'Phrase suivante ➜',
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_finished) ...[
                  const SizedBox(height: 40),
                  const Text('🏆',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 76)),
                  const SizedBox(height: 12),
                  const Text('Bravo, tu as terminé !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: navy)),
                  Text(
                    isListen
                        ? 'Tu as écouté ${_phrases.length} petites phrases.'
                        : 'Tu as trouvé $_score phrase(s) sur ${_phrases.length}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Terminer'),
                  ),
                ] else ...[
                  Text(
                    'Phrase ${_index + 1}/${_phrases.length}  ·  ⭐ $_score',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, color: navy),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (_index + 1) / _phrases.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: purple,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8068E8).withValues(alpha: 0.14),
                          const Color(0xFF36AFC0).withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(phrase.emoji,
                            style: const TextStyle(fontSize: 54)),
                        const SizedBox(height: 12),
                        Text(prompt,
                            key: const ValueKey('phrase-prompt'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: navy)),
                        if (widget.mode == PhrasePracticeMode.translate) ...[
                          const SizedBox(height: 6),
                          Text(widget.source,
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const ValueKey('phrase-play-audio'),
                    onPressed: () => _speak(
                      phrase.inLanguage(widget.target),
                      widget.target,
                    ),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(isListen ? 'Écouter la phrase' : 'Écouter Léo'),
                  ),
                  if (!isListen) ...[
                    const SizedBox(height: 14),
                    ...options.map((option) {
                      final isCorrectOption = option == phrase;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton.tonal(
                            key: ValueKey(isCorrectOption
                                ? 'phrase-correct-answer'
                                : 'phrase-option-${option.id}'),
                            onPressed: _answeredCorrectly
                                ? null
                                : () => _answer(isCorrectOption),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _answeredCorrectly && isCorrectOption
                                      ? Colors.green.shade100
                                      : null,
                            ),
                            child: Text(
                              isUnderstand
                                  ? option.emoji
                                  : option.inLanguage(widget.target),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isUnderstand ? 34 : 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_hadWrongAnswer && !_answeredCorrectly)
                      const Text(
                        'Essaie encore, tu vas y arriver !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: purple, fontWeight: FontWeight.w800),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const Map<String, Map<String, List<Map<String, String>>>> vocabulary = {
  'Animaux': {
    'Français': [
      {'emoji': '🐱', 'word': 'chat'},
      {'emoji': '🐶', 'word': 'chien'},
      {'emoji': '🐟', 'word': 'poisson'},
      {'emoji': '🐦', 'word': 'oiseau'},
    ],
    'English': [
      {'emoji': '🐱', 'word': 'cat'},
      {'emoji': '🐶', 'word': 'dog'},
      {'emoji': '🐟', 'word': 'fish'},
      {'emoji': '🐦', 'word': 'bird'},
    ],
    'Español': [
      {'emoji': '🐱', 'word': 'gato'},
      {'emoji': '🐶', 'word': 'perro'},
      {'emoji': '🐟', 'word': 'pez'},
      {'emoji': '🐦', 'word': 'pájaro'},
    ],
    'Deutsch': [
      {'emoji': '🐱', 'word': 'Katze'},
      {'emoji': '🐶', 'word': 'Hund'},
      {'emoji': '🐟', 'word': 'Fisch'},
      {'emoji': '🐦', 'word': 'Vogel'},
    ],
  },
  'Aliments': {
    'Français': [
      {'emoji': '🍎', 'word': 'pomme'},
      {'emoji': '🍌', 'word': 'banane'},
      {'emoji': '🍞', 'word': 'pain'},
      {'emoji': '💧', 'word': 'eau'},
    ],
    'English': [
      {'emoji': '🍎', 'word': 'apple'},
      {'emoji': '🍌', 'word': 'banana'},
      {'emoji': '🍞', 'word': 'bread'},
      {'emoji': '💧', 'word': 'water'},
    ],
    'Español': [
      {'emoji': '🍎', 'word': 'manzana'},
      {'emoji': '🍌', 'word': 'plátano'},
      {'emoji': '🍞', 'word': 'pan'},
      {'emoji': '💧', 'word': 'agua'},
    ],
    'Deutsch': [
      {'emoji': '🍎', 'word': 'Apfel'},
      {'emoji': '🍌', 'word': 'Banane'},
      {'emoji': '🍞', 'word': 'Brot'},
      {'emoji': '💧', 'word': 'Wasser'},
    ],
  },
};

class LanguageHubPage extends StatefulWidget {
  const LanguageHubPage({super.key});

  @override
  State<LanguageHubPage> createState() => _LanguageHubPageState();
}

class _LanguageHubPageState extends State<LanguageHubPage> {
  String source = 'Français';
  String target = 'English';
  List<_LanguageReviewWord> reviewWords = [];

  @override
  void initState() {
    super.initState();
    _loadReviewWords();
  }

  Future<void> _loadReviewWords() async {
    final savedKeys = await ProgressStore.languageReviewWords();
    final loadedWords = savedKeys
        .map(_LanguageReviewWord.fromStorageKey)
        .whereType<_LanguageReviewWord>()
        .where((word) {
      final sourceWords = vocabulary[word.topic]?[word.source];
      final targetWords = vocabulary[word.topic]?[word.target];
      return sourceWords != null &&
          targetWords != null &&
          word.index >= 0 &&
          word.index < sourceWords.length &&
          word.index < targetWords.length;
    }).toList();
    if (!mounted) return;
    setState(() => reviewWords = loadedWords);
  }

  Future<void> _openLesson(_LanguageReviewWord word) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LanguageLessonPage(
          topic: word.topic,
          source: word.source,
          target: word.target,
          initialIndex: word.index,
        ),
      ),
    );
    await _loadReviewWords();
  }

  void _openPhrasePractice() {
    if (source == 'Deutsch' || target == 'Deutsch') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Les petites phrases sont disponibles en français, anglais et espagnol.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhrasePracticeMenuPage(source: source, target: target),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌍 Atelier des langues')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Choisis tes langues',
              style: TextStyle(
                  fontSize: 23, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: source,
            decoration: const InputDecoration(
                labelText: 'Je connais déjà', border: OutlineInputBorder()),
            items: languages.keys
                .map((language) =>
                    DropdownMenuItem(value: language, child: Text(language)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                source = value;
                if (target == source) {
                  target = languages.keys.firstWhere((language) =>
                      language != source && language != 'Deutsch');
                }
              });
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: IconButton(
              onPressed: () {
                setState(() {
                  final temp = source;
                  source = target;
                  target = temp;
                });
              },
              icon: const Icon(Icons.swap_vert_circle_rounded,
                  size: 36, color: purple),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: target,
            decoration: const InputDecoration(
                labelText: 'Je veux apprendre', border: OutlineInputBorder()),
            items: languages.keys
                .where((language) => language != source)
                .map((language) =>
                    DropdownMenuItem(value: language, child: Text(language)))
                .toList(),
            onChanged: (value) => setState(() => target = value ?? target),
          ),
          const SizedBox(height: 22),
          const Text('Choisis un thème',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFAD7BE8).withValues(alpha: 0.12),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: const Text('💬', style: TextStyle(fontSize: 30)),
              title: const Text('Les petites phrases',
                  style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
              subtitle: const Text('Écouter • comprendre • traduire'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openPhrasePractice,
            ),
          ),
          const SizedBox(height: 8),
          ...vocabulary.keys.map(
            (topic) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.menu_book_rounded, color: purple),
                title: Text(topic),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLesson(_LanguageReviewWord(
                    topic: topic, source: source, target: target, index: 0)),
              ),
            ),
          ),
          if (reviewWords.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Mots à revoir (${reviewWords.length})',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
            const SizedBox(height: 8),
            ...reviewWords.map((word) {
              final entry = vocabulary[word.topic]![word.target]![word.index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(entry['emoji'] ?? '✨',
                      style: const TextStyle(fontSize: 26)),
                  title: Text(entry['word'] ?? ''),
                  subtitle: Text('${word.topic} • ${word.target}'),
                  trailing: const Icon(Icons.replay_rounded),
                  onTap: () => _openLesson(word),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class LanguageLessonPage extends StatefulWidget {
  final String topic;
  final String source;
  final String target;
  final int initialIndex;

  const LanguageLessonPage(
      {super.key,
      required this.topic,
      required this.source,
      required this.target,
      this.initialIndex = 0});

  @override
  State<LanguageLessonPage> createState() => _LanguageLessonPageState();
}

class _LanguageLessonPageState extends State<LanguageLessonPage> {
  int index = 0;
  bool isMarkedForReview = false;
  late final List<Map<String, String>> _entries;
  late final List<Map<String, String>> _targetEntries;

  @override
  void initState() {
    super.initState();
    _entries = vocabulary[widget.topic]?[widget.source] ?? const [];
    _targetEntries = vocabulary[widget.topic]?[widget.target] ?? const [];
    index = _entries.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _entries.length - 1);
    _loadReviewStatus();
  }

  String get _currentReviewKey => _LanguageReviewWord(
        topic: widget.topic,
        source: widget.source,
        target: widget.target,
        index: index,
      ).storageKey;

  Future<void> _loadReviewStatus() async {
    final savedWords = await ProgressStore.languageReviewWords();
    if (!mounted) return;
    setState(() => isMarkedForReview = savedWords.contains(_currentReviewKey));
  }

  Future<void> _setReviewStatus(bool value) async {
    await ProgressStore.setLanguageWordForReview(_currentReviewKey, value);
    if (!mounted) return;
    setState(() => isMarkedForReview = value);
  }

  Future<void> _speak(String word, String language) async {
    if (!await ProgressStore.speechEnabled()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La prononciation est désactivée.')),
      );
      return;
    }
    try {
      await speechChannel.invokeMethod<void>('speak', {
        'text': word,
        'language': languages[language] ?? 'fr-FR',
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.code == 'tts_language_unavailable'
          ? 'La voix de cette langue n’est pas installée sur cet appareil.'
          : 'La synthèse vocale n’est pas prête. Réessaie dans un instant.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La synthèse vocale est disponible sur Android.')),
      );
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await speechChannel.invokeMethod<void>('stop');
    } on PlatformException {
      // The audio engine may already be shutting down.
    } on MissingPluginException {
      // Widget tests and non-Android platforms have no native speech channel.
    }
  }

  @override
  void dispose() {
    unawaited(_stopSpeaking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _entries[index % _entries.length];
    final targetWord = _targetEntries[index % _targetEntries.length];

    return Scaffold(
      appBar: AppBar(
          title: Text('${widget.topic} • ${index + 1}/${_entries.length}')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(current['emoji'] ?? '✨',
                    style: const TextStyle(fontSize: 92)),
                const SizedBox(height: 10),
                Text(current['word'] ?? '',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: navy)),
                Text(widget.source,
                    style: const TextStyle(color: Colors.black54)),
                IconButton(
                  onPressed: () => _speak(current['word'] ?? '', widget.source),
                  icon: const Icon(Icons.volume_up_rounded,
                      size: 32, color: purple),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                Text(targetWord['word'] ?? '',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: purple)),
                Text(widget.target,
                    style: const TextStyle(color: Colors.black54)),
                IconButton(
                  onPressed: () =>
                      _speak(targetWord['word'] ?? '', widget.target),
                  icon: const Icon(Icons.volume_up_rounded,
                      size: 32, color: purple),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isMarkedForReview,
                  onChanged: (value) => _setReviewStatus(value ?? false),
                  title: const Text('À revoir plus tard'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (index < _entries.length - 1) {
                      setState(() {
                        index += 1;
                        isMarkedForReview = false;
                      });
                      _loadReviewStatus();
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Bravo ! 🎉'),
                          content: const Text('Tu as découvert tout le thème.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Super !')),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text(index == _entries.length - 1
                      ? 'Terminer'
                      : 'Mot suivant ➜'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizHubPage extends StatefulWidget {
  final String kind;
  final int questionLimit;
  final int? challengeDay;

  const QuizHubPage({
    super.key,
    required this.kind,
    this.questionLimit = 30,
    this.challengeDay,
  });

  @override
  State<QuizHubPage> createState() => _QuizHubPageState();
}

List<String> _quizOptions(String answer, List<String> choices) {
  final options = <String>[answer];
  for (final choice in choices) {
    if (choice != answer && !options.contains(choice)) {
      options.add(choice);
    }
    if (options.length == 4) break;
  }
  return options..shuffle();
}

List<_QuizQuestion> _quizQuestions(String kind) {
  if (kind == 'letters') {
    final alphabet =
        List.generate(26, (index) => String.fromCharCode(65 + index));
    final questions = List.generate(26, (index) {
      final letter = alphabet[index];
      return _QuizQuestion(
        letter,
        'Quelle lettre vois-tu ?',
        letter,
        _quizOptions(letter, alphabet),
      );
    });
    for (final letter in ['A', 'E', 'M', 'S']) {
      final answer = letter.toLowerCase();
      questions.add(_QuizQuestion(
        letter,
        'Trouve la minuscule de $letter.',
        answer,
        _quizOptions(
            answer, alphabet.map((value) => value.toLowerCase()).toList()),
      ));
    }
    return questions;
  }

  if (kind == 'colors') {
    const palette = [
      'Rouge',
      'Bleu',
      'Jaune',
      'Vert',
      'Orange',
      'Violet',
      'Rose',
      'Marron',
      'Noir',
      'Blanc',
    ];
    const objects = [
      ('🍎', 'pomme', 'Rouge'),
      ('🍓', 'fraise', 'Rouge'),
      ('🚒', 'camion de pompier', 'Rouge'),
      ('🐠', 'poisson', 'Orange'),
      ('🥕', 'carotte', 'Orange'),
      ('🍊', 'orange', 'Orange'),
      ('🍋', 'citron', 'Jaune'),
      ('🌟', 'étoile', 'Jaune'),
      ('🌽', 'épi de maïs', 'Jaune'),
      ('🐸', 'grenouille', 'Vert'),
      ('🥦', 'brocoli', 'Vert'),
      ('🍐', 'poire', 'Vert'),
      ('🌊', 'vague', 'Bleu'),
      ('🫐', 'myrtille', 'Bleu'),
      ('🐳', 'baleine', 'Bleu'),
      ('🍇', 'grappe de raisin', 'Violet'),
      ('🪻', 'fleur', 'Violet'),
      ('🍆', 'aubergine', 'Violet'),
      ('🌸', 'fleur', 'Rose'),
      ('🦩', 'flamant', 'Rose'),
      ('🎀', 'ruban', 'Rose'),
      ('🐻', 'ours', 'Marron'),
      ('🥥', 'noix de coco', 'Marron'),
      ('🪵', 'morceau de bois', 'Marron'),
      ('🐈‍⬛', 'chat', 'Noir'),
      ('🖤', 'cœur', 'Noir'),
      ('🐜', 'fourmi', 'Noir'),
      ('🥛', 'verre de lait', 'Blanc'),
      ('☁️', 'nuage', 'Blanc'),
      ('🐑', 'mouton', 'Blanc'),
    ];
    return List.generate(objects.length, (index) {
      final (emoji, name, answer) = objects[index];
      final prompt = switch (index % 3) {
        0 => 'De quelle couleur est $name ?',
        1 => 'Trouve la couleur de $name.',
        _ => 'Quelle couleur vois-tu sur $name ?',
      };
      return _QuizQuestion(
        emoji,
        prompt,
        answer,
        _quizOptions(answer, palette),
      );
    });
  }

  const world = [
    (
      '🐟',
      'Où vit le poisson ?',
      'Dans l’eau',
      ['Dans le ciel', 'Dans le désert', 'Dans un arbre']
    ),
    (
      '🦁',
      'Où vit le lion ?',
      'Dans la savane',
      ['Dans la mer', 'Dans la neige', 'Dans une maison']
    ),
    (
      '🐫',
      'Où le chameau est-il bien adapté ?',
      'Dans le désert',
      ['Dans la mer', 'Dans la forêt', 'Dans la glace']
    ),
    (
      '🐒',
      'Où le singe aime-t-il vivre ?',
      'Dans la forêt',
      ['Dans la mer', 'Dans le désert', 'Dans une voiture']
    ),
    (
      '🐦',
      'Que sait faire l’oiseau ?',
      'Voler',
      ['Nager sous l’eau', 'Conduire', 'Faire du vélo']
    ),
    (
      '🐸',
      'Où la grenouille aime-t-elle sauter ?',
      'Près de l’eau',
      ['Dans le désert', 'Dans le ciel', 'Sur la lune']
    ),
    (
      '🐬',
      'Où nage le dauphin ?',
      'Dans la mer',
      ['Dans les arbres', 'Dans le désert', 'Dans une grotte']
    ),
    (
      '🐝',
      'Que fabrique l’abeille ?',
      'Du miel',
      ['Du pain', 'Du fromage', 'Du jus de pomme']
    ),
    (
      '🐰',
      'Que mange souvent le lapin ?',
      'Une carotte',
      ['Un poisson', 'Une chaussure', 'Une pierre']
    ),
    (
      '🐄',
      'Quel animal donne du lait ?',
      'La vache',
      ['Le papillon', 'La tortue', 'Le poisson']
    ),
    (
      '🐶',
      'Quel animal aboie ?',
      'Le chien',
      ['Le chat', 'La vache', 'Le canard']
    ),
    (
      '🐱',
      'Quel animal miaule ?',
      'Le chat',
      ['Le cheval', 'Le mouton', 'Le poisson']
    ),
    (
      '🦋',
      'Que devient la chenille ?',
      'Un papillon',
      ['Une grenouille', 'Une fleur', 'Un oiseau']
    ),
    (
      '🦆',
      'Quel animal a des plumes et un bec ?',
      'Le canard',
      ['Le chat', 'Le cheval', 'Le lapin']
    ),
    (
      '🍌',
      'La banane est…',
      'Un fruit',
      ['Un jouet', 'Un vêtement', 'Un meuble']
    ),
    (
      '🥦',
      'Le brocoli est…',
      'Un légume',
      ['Un animal', 'Un jouet', 'Un moyen de transport']
    ),
    (
      '👀',
      'Avec quelle partie du corps voit-on ?',
      'Les yeux',
      ['Les oreilles', 'Le nez', 'Les genoux']
    ),
    (
      '👂',
      'Avec quelle partie du corps entend-on ?',
      'Les oreilles',
      ['Les mains', 'Les pieds', 'Les cheveux']
    ),
    (
      '👃',
      'Avec quelle partie du corps sent-on les fleurs ?',
      'Le nez',
      ['Les coudes', 'Les oreilles', 'Les pieds']
    ),
    (
      '🦷',
      'Avec quoi mâche-t-on les aliments ?',
      'Les dents',
      ['Les cheveux', 'Les doigts', 'Les oreilles']
    ),
    (
      '☀️',
      'Qu’est-ce qui brille dans le ciel le jour ?',
      'Le soleil',
      ['La chaussure', 'La table', 'Le poisson']
    ),
    (
      '🌧️',
      'Que tombe-t-il d’un nuage de pluie ?',
      'De l’eau',
      ['Du sable', 'Des feuilles', 'Du lait']
    ),
    (
      '🌳',
      'Qu’est-ce qui pousse sur un arbre ?',
      'Des feuilles',
      ['Des chaussures', 'Des assiettes', 'Des voitures']
    ),
    (
      '🏠',
      'Dans quel endroit habite-t-on ?',
      'Une maison',
      ['Une casserole', 'Un ballon', 'Un livre']
    ),
    (
      '🏫',
      'Où va-t-on pour apprendre avec la maîtresse ?',
      'À l’école',
      ['À la plage', 'Au garage', 'À la boulangerie']
    ),
    (
      '🚗',
      'Quel objet nous emmène sur la route ?',
      'Une voiture',
      ['Une chaise', 'Une fleur', 'Une assiette']
    ),
    (
      '🪑',
      'Sur quel objet peut-on s’asseoir ?',
      'Une chaise',
      ['Une fenêtre', 'Un nuage', 'Une banane']
    ),
    (
      '👩‍⚕️',
      'Qui soigne les personnes malades ?',
      'Le médecin',
      ['Le jardinier', 'Le musicien', 'Le boulanger']
    ),
    (
      '👩‍🏫',
      'Qui aide les enfants à apprendre à l’école ?',
      'L’enseignant',
      ['Le pompier', 'Le pilote', 'Le fermier']
    ),
    (
      '🚒',
      'Qui aide à éteindre les incendies ?',
      'Le pompier',
      ['Le facteur', 'Le cuisinier', 'Le peintre']
    ),
  ];
  return world
      .map((item) => _QuizQuestion(
            item.$1,
            item.$2,
            item.$3,
            _quizOptions(item.$3, item.$4),
          ))
      .toList();
}

class _QuizHubPageState extends State<QuizHubPage> {
  late final List<_QuizQuestion> questions = (_quizQuestions(widget.kind)
        ..shuffle())
      .take(widget.questionLimit)
      .toList();

  int questionIndex = 0;
  int correctCount = 0;
  String? selectedOption;
  bool isComplete = false;
  bool isReviewing = false;
  final List<_QuizQuestion> missedQuestions = [];
  Timer? _advanceTimer;

  _QuizQuestion get currentQuestion => questions[questionIndex];

  void _answer(String option) {
    if (selectedOption != null) return;
    setState(() {
      selectedOption = option;
      if (option == currentQuestion.correct) {
        correctCount++;
      } else {
        missedQuestions.add(currentQuestion);
      }
    });
    _advanceTimer = Timer(const Duration(milliseconds: 1100), _continue);
  }

  Future<void> _continue() async {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        selectedOption = null;
      });
      return;
    }

    await ProgressStore.recordQuiz(
      kind: widget.kind,
      correct: correctCount,
      total: questions.length,
    );
    await ProgressStore.reward();
    await ProgressStore.completeChallenge(widget.challengeDay);
    if (mounted) setState(() => isComplete = true);
  }

  void _restart() {
    _advanceTimer?.cancel();
    setState(() {
      questions.shuffle();
      questionIndex = 0;
      correctCount = 0;
      selectedOption = null;
      isComplete = false;
      isReviewing = false;
      missedQuestions.clear();
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.kind == 'letters'
        ? 'Alphabet'
        : widget.kind == 'colors'
            ? 'Couleurs'
            : 'Découverte';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (isComplete) ..._buildResults() else ..._buildQuestion(),
        ],
      ),
    );
  }

  List<Widget> _buildQuestion() => [
        Text('Question ${questionIndex + 1} / ${questions.length}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (questionIndex + 1) / questions.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: purple,
          backgroundColor: purple.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 24),
        Center(
            child: Text(currentQuestion.emoji,
                style: const TextStyle(fontSize: 72))),
        const SizedBox(height: 16),
        Text(currentQuestion.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 20),
        ...currentQuestion.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed:
                    selectedOption == null ? () => _answer(option) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: selectedOption == option
                      ? option == currentQuestion.correct
                          ? Colors.green.shade100
                          : Colors.orange.shade100
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selectedOption == option) ...[
                      Icon(
                        option == currentQuestion.correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: option == currentQuestion.correct
                            ? Colors.green.shade700
                            : Colors.deepOrange.shade700,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(option),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (selectedOption != null) ...[
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(selectedOption == currentQuestion.correct),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selectedOption == currentQuestion.correct
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    selectedOption == currentQuestion.correct
                        ? Icons.celebration_rounded
                        : Icons.favorite_rounded,
                    size: 40,
                    color: selectedOption == currentQuestion.correct
                        ? Colors.green.shade700
                        : Colors.deepOrange.shade400,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedOption == currentQuestion.correct
                        ? 'Bravo, tu as trouvé !'
                        : 'Ce n’est pas grave, continue !',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: navy),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('La prochaine question arrive…',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
        ],
      ];

  List<Widget> _buildResults() {
    if (isReviewing) {
      return [
        const Text('À revoir',
            style: TextStyle(
                fontSize: 23, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 12),
        ...missedQuestions.map(
          (question) => Card(
            color: Colors.white,
            child: ListTile(
              leading:
                  Text(question.emoji, style: const TextStyle(fontSize: 30)),
              title: Text(question.question),
              subtitle: Text('Bonne réponse : ${question.correct}'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => isReviewing = false),
          child: const Text('Retour au résultat'),
        ),
      ];
    }

    return [
      const Center(child: Text('🏅', style: TextStyle(fontSize: 68))),
      const SizedBox(height: 12),
      const Text('Quiz terminé !',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.w900, color: navy)),
      const SizedBox(height: 8),
      Text('$correctCount / ${questions.length} bonnes réponses',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, color: navy)),
      const SizedBox(height: 8),
      const Text('Une étoile a été ajoutée à tes progrès.',
          textAlign: TextAlign.center),
      if (missedQuestions.isNotEmpty) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() => isReviewing = true),
          icon: const Icon(Icons.replay_rounded),
          label: Text('Revoir ${missedQuestions.length} réponse(s)'),
        ),
      ] else ...[
        const SizedBox(height: 16),
        const Text('Tout juste, bravo !',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
      ],
      const SizedBox(height: 12),
      FilledButton(onPressed: _restart, child: const Text('Rejouer')),
    ];
  }
}

class _QuizQuestion {
  final String emoji;
  final String question;
  final String correct;
  final List<String> options;

  const _QuizQuestion(this.emoji, this.question, this.correct, this.options);
}
