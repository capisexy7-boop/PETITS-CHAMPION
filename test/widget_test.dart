import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petits_champions/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> launchApp(WidgetTester tester) async {
    await tester.pumpWidget(const PetitsChampionsApp());
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();
  }

  testWidgets('intro greets the child then opens the home page',
      (tester) async {
    await tester.pumpWidget(const PetitsChampionsApp());
    expect(find.text('Coucou Champion ! 🦁'), findsOneWidget);
    expect(find.text('Choisis ton aventure'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();
    expect(find.text('Choisis ton aventure'), findsOneWidget);
  });

  testWidgets('app loads on the home screen', (tester) async {
    await launchApp(tester);

    expect(find.text('PETITS CHAMPIONS'), findsOneWidget);
    expect(find.text('Choisis ton aventure'), findsOneWidget);
    expect(find.text('Mes nombres'), findsOneWidget);
    expect(find.text('Mes lettres'), findsOneWidget);
    expect(find.text('Mes couleurs'), findsOneWidget);
  });

  testWidgets('colorful home cards fit a narrow phone and animate in',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Choisis ton aventure'), findsOneWidget);
    expect(find.text('Mes découvertes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child activity cards and bottom journey navigation work',
      (tester) async {
    await launchApp(tester);
    await tester.tap(find.text('Mes nombres'));
    await tester.pumpAndSettle();
    expect(find.text('Leçon +'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parcours'));
    await tester.pumpAndSettle();
    expect(find.text('Parcours de 30 jours'), findsOneWidget);
  });

  testWidgets('parent can save the child name and see it on home',
      (tester) async {
    await launchApp(tester);

    await tester.tap(find.byIcon(Icons.lock_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Espace réservé aux parents'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '15');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    final speechSwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(speechSwitch.value, isTrue);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool('speech_enabled'),
      isFalse,
    );

    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('child_name'), 'Alex');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Salut Alex !'), findsOneWidget);
  });

  testWidgets('parent access stays blocked after an incorrect answer',
      (tester) async {
    await launchApp(tester);
    await tester.tap(find.byIcon(Icons.lock_outline_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Espace réservé aux parents'), findsOneWidget);
    expect(find.text('Réponse incorrecte. Réessaie ou ferme cette fenêtre.'),
        findsOneWidget);
  });

  testWidgets('parent can choose and save the child age', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ParentPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 ans').last);
    await tester.pumpAndSettle();

    expect(
      (await SharedPreferences.getInstance()).getInt('child_age'),
      2,
    );
    expect(find.text('2 ans'), findsOneWidget);
  });

  testWidgets('star milestones display earned progress badges', (tester) async {
    SharedPreferences.setMockInitialValues({'stars': 5});
    await launchApp(tester);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Badges de champion'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('parent dashboard shows stored activity totals and progress',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'quiz_correct': 7,
      'quiz_wrong': 3,
      'quiz_letters_correct': 4,
      'quiz_letters_total': 5,
      'math_correct': 2,
      'math_wrong': 1,
      'math_total': 3,
    });
    await tester.pumpWidget(const MaterialApp(home: ParentPage()));
    await tester.pumpAndSettle();

    expect(find.text('Résultats des activités'), findsOneWidget);
    expect(find.text('9 bonnes • 4 à retravailler'), findsOneWidget);
    expect(find.text('Réussite : 69 %'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Alphabet'), findsOneWidget);
    expect(find.text('4 / 5'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Mathématiques'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('language words can be reviewed and then removed',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LanguageHubPage()));

    await tester.tap(find.text('Animaux'));
    await tester.pumpAndSettle();
    expect(find.text('chat'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('language_review_words'), hasLength(1));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Mots à revoir (1)'), 250);
    expect(find.text('Mots à revoir (1)'), findsOneWidget);
    await tester.tap(find.text('cat'));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('language_review_words'), isEmpty);
  });

  test('phrase bank has 15 unique translations in three languages', () {
    expect(learningPhrases, hasLength(15));
    expect(learningPhrases.map((phrase) => phrase.id).toSet(), hasLength(15));
    for (final language in ['Français', 'English', 'Español']) {
      final sentences =
          learningPhrases.map((phrase) => phrase.inLanguage(language)).toList();
      expect(sentences.toSet(), hasLength(15));
      expect(sentences.every((sentence) => sentence.isNotEmpty), isTrue);
    }
    expect(
      learningPhrases.first.inLanguage('English'),
      'Hello, how are you?',
    );
    expect(
      learningPhrases.first.inLanguage('Español'),
      'Hola, ¿cómo estás?',
    );
  });

  testWidgets('phrase translation has 15 distinct questions and records score',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PhrasePracticePage(
        source: 'Français',
        target: 'English',
        mode: PhrasePracticeMode.translate,
      ),
    ));
    await tester.pumpAndSettle();

    final seenPrompts = <String>{};
    for (var round = 1; round <= learningPhrases.length; round++) {
      seenPrompts.add(
        tester.widget<Text>(find.byKey(const ValueKey('phrase-prompt'))).data!,
      );
      expect(
          find.byKey(const ValueKey('phrase-correct-answer')), findsOneWidget);
      expect(find.byKey(const ValueKey('phrase-play-audio')), findsOneWidget);
      await tester
          .ensureVisible(find.byKey(const ValueKey('phrase-correct-answer')));
      await tester.tap(find.byKey(const ValueKey('phrase-correct-answer')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('phrase-next')))
            .onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('phrase-next')));
      await tester.tap(find.byKey(const ValueKey('phrase-next')));
      await tester.pumpAndSettle();
      if (round < learningPhrases.length) {
        expect(
            find.text('Phrase ${round + 1}/15  ·  ⭐ $round'), findsOneWidget);
      }
    }

    expect(seenPrompts, hasLength(learningPhrases.length));
    expect(find.text('Bravo, tu as terminé !'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('quiz_phrases_correct'), learningPhrases.length);
    expect(prefs.getInt('quiz_phrases_total'), learningPhrases.length);
    expect(prefs.getInt('stars'), 1);
  });

  testWidgets('phrase comprehension lets the child retry a wrong picture',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PhrasePracticePage(
        source: 'Français',
        target: 'Español',
        mode: PhrasePracticeMode.understand,
      ),
    ));
    await tester.pumpAndSettle();

    final wrongOption = find
        .byType(FilledButton)
        .evaluate()
        .map((element) => element.widget as FilledButton)
        .firstWhere((button) =>
            button.key != const ValueKey('phrase-correct-answer') &&
            button.key != const ValueKey('phrase-next') &&
            button.key != null);
    await tester.ensureVisible(find.byWidget(wrongOption));
    await tester.tap(find.byWidget(wrongOption));
    await tester.pumpAndSettle();
    expect(find.text('Essaie encore, tu vas y arriver !'), findsOneWidget);
    expect(find.byKey(const ValueKey('phrase-correct-answer')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('phrase-correct-answer')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('phrase-next')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('phrase listening activity completes all sentences',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: PhrasePracticePage(
        source: 'Français',
        target: 'Español',
        mode: PhrasePracticeMode.listen,
      ),
    ));
    await tester.pumpAndSettle();

    for (var round = 1; round <= learningPhrases.length; round++) {
      expect(find.byKey(const ValueKey('phrase-play-audio')), findsOneWidget);
      expect(find.byKey(const ValueKey('phrase-correct-answer')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('phrase-next')));
      await tester.pumpAndSettle();
      if (round < learningPhrases.length) {
        expect(find.text('Phrase ${round + 1}/15  ·  ⭐ 0'), findsOneWidget);
      }
    }

    expect(find.text('Tu as écouté 15 petites phrases.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('stars'), 1);
    expect(prefs.getInt('quiz_phrases_total'), isNull);
  });

  testWidgets('language hub opens the three phrase learning modes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LanguageHubPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Les petites phrases'), 250);
    await tester.tap(find.text('Les petites phrases'));
    await tester.pumpAndSettle();
    expect(find.text('J’écoute et je répète'), findsOneWidget);
    expect(find.text('Je comprends'), findsOneWidget);
    expect(find.text('Je trouve la traduction'), findsOneWidget);
  });

  testWidgets('math lesson explains visually and opens its focused game',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MathLessonPage(isAddition: false),
    ));

    expect(find.text('On en enlève !'), findsOneWidget);
    expect(find.text('5 − 2 = 3 🍌'), findsOneWidget);
    expect(find.text('Soustraire, c’est enlever des objets.'), findsOneWidget);
    await tester.tap(find.text('À toi de jouer !'));
    await tester.pumpAndSettle();
    expect(find.text('Défi 1/30  ·  ⭐ 0'), findsOneWidget);
    expect(find.text('Combien en reste-t-il ?'), findsOneWidget);
  });

  testWidgets('math challenge retries wrong answers and completes 30 rounds',
      (tester) async {
    SharedPreferences.setMockInitialValues({'child_age': 5});
    await tester.pumpWidget(const MaterialApp(
      home: MathGamePage(isAdditionOnly: true, questionLimit: 30),
    ));
    await tester.pump();

    expect(find.text('Défi 1/30  ·  ⭐ 0'), findsOneWidget);
    expect(find.text('Combien y a-t-il en tout ?'), findsOneWidget);
    expect(find.byType(Stack), findsWidgets);
    expect(find.byType(FilledButton), findsNWidgets(4));

    final wrongAnswer = find
        .byType(FilledButton)
        .evaluate()
        .map((element) => element.widget as FilledButton)
        .firstWhere(
            (button) => button.key != const ValueKey('math-correct-answer'));
    await tester.tap(find.byWidget(wrongAnswer));
    await tester.pump();
    expect(find.text('Essaie encore ! Compte les objets.'), findsOneWidget);
    expect(find.text('Défi 1/30  ·  ⭐ 0'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
              find.byKey(const ValueKey('math-correct-answer')))
          .onPressed,
      isNotNull,
    );

    for (var round = 1; round <= 30; round++) {
      await tester.tap(find.byKey(const ValueKey('math-correct-answer')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      if (round < 30) {
        expect(find.text('Défi ${round + 1}/30  ·  ⭐ $round'), findsOneWidget);
      }
    }

    expect(find.text('Bravo, défi terminé !'), findsOneWidget);
    expect(find.text('Tu as réussi 30 exercices.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('math_total'), 31);
    expect(prefs.getInt('math_correct'), 30);
    expect(prefs.getInt('math_wrong'), 1);
    expect(prefs.getInt('stars'), 30);
  });

  testWidgets('counting and number recognition each complete 30 rounds',
      (tester) async {
    for (final mode in [MathGameMode.counting, MathGameMode.numbers]) {
      await tester.pumpWidget(MaterialApp(
        home: MathGamePage(mode: mode, questionLimit: 30),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Défi 1/30  ·  ⭐ 0'), findsOneWidget);
      expect(
        find.text(mode == MathGameMode.counting
            ? 'Combien en vois-tu ?'
            : 'Trouve la quantité qui correspond !'),
        findsOneWidget,
      );
      if (mode == MathGameMode.numbers) {
        expect(find.byType(Stack), findsWidgets);
        expect(
          tester
              .widget<FilledButton>(
                  find.byKey(const ValueKey('math-correct-answer')))
              .child,
          isA<Wrap>(),
        );
      }

      for (var round = 1; round <= 30; round++) {
        await tester
            .ensureVisible(find.byKey(const ValueKey('math-correct-answer')));
        await tester.tap(find.byKey(const ValueKey('math-correct-answer')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();
      }
      expect(find.text('Bravo, défi terminé !'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('math_total'), 60);
    expect(prefs.getInt('math_correct'), 60);
  });

  testWidgets('math counting adapts answer range to saved child age',
      (tester) async {
    SharedPreferences.setMockInitialValues({'child_age': 2});
    await tester.pumpWidget(const MaterialApp(
      home: MathGamePage(
        mode: MathGameMode.counting,
        questionLimit: 30,
      ),
    ));
    await tester.pumpAndSettle();

    final answers = tester
        .widgetList<FilledButton>(find.byType(FilledButton))
        .map((button) => (button.child as Text).data!)
        .map(int.parse)
        .toList();
    expect(answers, hasLength(3));
    expect(answers.every((answer) => answer >= 1 && answer <= 3), isTrue);
  });

  testWidgets('math hub offers count and number activities', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MathHubPage()));

    await tester.tap(find.text('Je compte'));
    await tester.pumpAndSettle();
    expect(find.text('Combien en vois-tu ?'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Je reconnais les chiffres'));
    await tester.pumpAndSettle();
    expect(find.text('Trouve la quantité qui correspond !'), findsOneWidget);
  });

  testWidgets('comparison, shape, and pattern games complete 30 questions',
      (tester) async {
    final modes = [
      MathConceptMode.compare,
      MathConceptMode.shapes,
      MathConceptMode.patterns,
    ];
    for (final mode in modes) {
      await tester.pumpWidget(MaterialApp(
        home: MathConceptGamePage(mode: mode),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Défi 1/30  ·  ⭐ 0'), findsOneWidget);
      for (var round = 1; round <= 30; round++) {
        await tester.ensureVisible(
            find.byKey(const ValueKey('concept-correct-answer')));
        await tester.tap(find.byKey(const ValueKey('concept-correct-answer')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();
      }
      expect(find.text('Bravo, tu as terminé !'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('math_total'), 90);
    expect(prefs.getInt('math_correct'), 90);
  });

  testWidgets('math hub opens comparison, shape, and pattern activities',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MathHubPage()));

    for (final entry in [
      ('Je compare', 'Quel groupe en a le plus ?'),
      ('Je découvre les formes', 'Trouve la forme : triangle !'),
      ('Je continue les suites', 'Que faut-il mettre après ?'),
    ]) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      expect(find.text('Défi 1/30  ·  ⭐ 0'), findsOneWidget);
      expect(find.text(entry.$2), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('quiz gives visual feedback and advances automatically',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: QuizHubPage(kind: 'letters'),
    ));

    expect(find.text('Question 1 / 30'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(
      find.text('Bravo, tu as trouvé !').evaluate().isNotEmpty ||
          find.text('Ce n’est pas grave, continue !').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.textContaining('La bonne réponse est'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.text('Question 2 / 30'), findsOneWidget);
  });

  testWidgets('color and discovery quizzes each have 30 questions',
      (tester) async {
    for (final kind in ['colors', 'world']) {
      await tester.pumpWidget(MaterialApp(home: QuizHubPage(kind: kind)));
      expect(find.text('Question 1 / 30'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('daily challenges can be completed out of order and saved',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DailyChallengePage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 / 30 défis terminés'), findsOneWidget);

    await tester.tap(find.text('Jour 2'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 / 5'), findsOneWidget);

    for (var question = 0; question < 5; question++) {
      await tester.ensureVisible(find.byType(FilledButton).first);
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
    }

    expect(find.text('Quiz terminé !'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('daily_challenges_completed'), ['2']);
    expect(prefs.getInt('quiz_colors_total'), 5);
    expect(
        prefs.getInt('quiz_colors_correct')! + prefs.getInt('quiz_wrong')!, 5);
    expect(find.text('1 / 30 défis terminés'), findsOneWidget);
    expect(find.text('Jour 1'), findsOneWidget);
  });
}
