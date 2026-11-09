# Petits Champions 🦁

Application Flutter éducative destinée aux jeunes enfants de 1 à 5 ans.

## Version 1.1 — refonte initiale

- Accueil coloré : message de bienvenue avec Léo, compteur d'étoiles, cartes illustrées aux couleurs distinctes, apparition animée et retour tactile doux, avec navigation directe vers les activités, le parcours et l'espace parent.
- Icône Android originale de Petit Champion et écran de démarrage aux couleurs de l'application.
- Illustration originale du lion Léo, réutilisée sur l'accueil et dans l'icône.
- À l'ouverture, courte introduction animée de Léo avec transition vers l'accueil.
- Mathématiques : leçons illustrées d'addition et de soustraction, défis de 30 exercices progressifs, comptage, reconnaissance des chiffres, comparaison des quantités, formes et suites logiques. Les réponses sont enregistrées et une erreur permet de réessayer.
- Profil parent : choix de l'âge de 1 à 5 ans ; les exercices de comptage, de chiffres, d'addition et de soustraction adaptent leur plage de nombres à l'âge.
- Atelier de langues : vocabulaire en français, anglais, espagnol et allemand, plus 15 petites phrases alignées en français, anglais et espagnol. Les phrases proposent une activité d'écoute, un jeu de compréhension par image et un quiz de traduction, avec résultats enregistrés dans le suivi parental.
- Vocabulaire thématique : animaux, aliments, salutations et couleurs.
- Prononciation par le moteur de synthèse vocale Android. La disponibilité, le fonctionnement hors connexion et la qualité dépendent des voix installées sur le téléphone.
- Sauvegarde locale du prénom, des étoiles, des activités et des mots à revoir (`shared_preferences`). Pas de compte ni de serveur requis.
- Espace parent protégé par une question de vérification, avec réglage persistant de la prononciation audio et statistiques de réussite globales, par quiz et pour les mathématiques.
- Parcours hors ligne de 30 défis : cinq questions par séance, reprise libre dans l’ordre choisi et progression conservée sur l’appareil.
- Badges de progression débloqués après 1, 5 et 10 étoiles.
- Révision des mots marqués « À revoir » dans l'atelier des langues, conservée entre les séances.
- Quiz alphabet, couleurs et découverte : 30 questions par thème, ordre mélangé,
  score de séance, retour visuel bienveillant et passage automatique à la suite.
- Une étoile et une activité sont enregistrées localement à la fin de chaque quiz.

## Lancer le projet

1. Installer Flutter et vérifier l'environnement : `flutter doctor`.
2. Depuis ce dossier, exécuter `flutter pub get`.
3. Brancher un téléphone Android ou démarrer un émulateur.
4. Exécuter `flutter run`.

## Build Android de production

Les builds release exigent une clé de signature appartenant au propriétaire du projet ; aucune clé debug ou temporaire n'est utilisée. Configurer les variables d'environnement `PETITS_CHAMPIONS_STORE_FILE`, `PETITS_CHAMPIONS_STORE_PASSWORD`, `PETITS_CHAMPIONS_KEY_ALIAS` et `PETITS_CHAMPIONS_KEY_PASSWORD` dans l'environnement de build sécurisé, puis lancer `flutter build appbundle --release`. Ne pas placer le fichier de clé ni ses mots de passe dans le dépôt. La clé doit être sauvegardée de manière sécurisée : sa perte peut empêcher les mises à jour de l'application.

Dépendances Flutter :
- `shared_preferences` : sauvegarde locale.
- La prononciation Android utilise le moteur natif Text-to-Speech ; aucune voix préenregistrée n'est incluse.

## Direction artistique

- Mascotte : Léo, un petit lion joyeux et rassurant.
- Palette : violet principal `#7357D8`, bleu nuit `#26345D`, fond crème `#FFF9EF`, accents vert, bleu, orange et turquoise.
- Formes : cartes arrondies, grandes zones tactiles, textes lisibles, peu de texte par écran.
- Ton pédagogique : encourager l'effort, ne jamais humilier l'enfant après une erreur.
- L'illustration source de Léo est `assets/images/leo.png`. Les icônes Android adaptatives et les icônes bitmap de compatibilité sont dans `android/app/src/main/res`.

## Limites connues de cette première refonte

Cette version reste à tester avec des familles avant diffusion. Le parcours de 30 jours varie entre des quiz de lettres, de couleurs et de découverte ; il ne s'agit pas encore de leçons progressives spécifiques à chaque journée. La vérification de l'espace parent est une barrière simple, et non une protection forte contre un enfant qui connaît la réponse. Les activités mathématiques couvrent les opérations, le comptage, la comparaison, les chiffres, les formes et les suites ; leur contenu reste introductif. Les catégories de vocabulaire restent limitées et doivent être enrichies. Les phrases et le vocabulaire doivent être relus par des locuteurs compétents avant diffusion publique. L'audio dépend des voix présentes sur l'appareil. Les statistiques restent locales à l'appareil.

La publication Google Play n'est pas encore préparée : l'identifiant Android `com.example.petits_champions` est un identifiant provisoire, aucune clé de production ni politique de confidentialité n'est fournie, et la fiche Play, les déclarations Families/Data safety et les tests fermés restent à faire. Le projet refuse maintenant de produire un build release sans la signature de production configurée.

## Prochaines étapes recommandées

1. Tester sur téléphone : navigation, affichage petit écran, voix TTS et sauvegarde après fermeture.
2. Ajouter des illustrations originales de la mascotte et des objets, plutôt que dépendre uniquement des emojis.
3. Faire tester l'application par les enfants et ajuster la difficulté selon leur âge et leur niveau.
4. Ajouter un contrôle parental simple avant les paramètres sensibles et limiter les données personnelles collectées.

## Pédagogie et sécurité

- Une séance courte vaut mieux qu'une longue session imposée.
- Aucun classement public ni pénalité pour une mauvaise réponse.
- Pas de publicité ni de lien externe accessible directement aux enfants.
- Prévoir un mode hors connexion pour les contenus de base.
