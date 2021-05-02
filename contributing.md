# Contribuer au wiki

## Avant toute contribution, la lecture de ce document est obligatoire

- Veuillez employer un français correct. Notre langue n'est pas des plus simples, mais son bon emploi standard nous permet de nous comprendre mutuellement de façon claire, d'autant plus dans un domaine aussi spécifique que le développement de systèmes d'exploitation.
- Les langages de programmation principalement utilisés dans les exemples sont le C, le C++ et l'assembleur x86, avec une syntaxe Intel. En effet, ce sont des langages couramment utilisé lorsque l'on programme un noyau, un OS, ou un pilote.
- Veuillez produire votre propre contenu. Les copier-collers sont contre-productifs pour vous. C'est en réfléchissant par soi-même et en interprétant soi-même ce que l'on évolue.
- Nous évitons d'utiliser les architectures en 32 bits car elles ne sont plus forcément d'actualité.

## La structure suivante est de rigueur pour l'ensemble des documents

- La partie "haute" du document regroupe le sommaire de l'article, ainsi que les liens qui permettent de s'y balader.
- Vous retrouverez ensuite, factuellement, une liste détaillée et argumentée des préréquis pour la compréhension d'un article, ou l'application d'un tutoriel.
- Le reste du document est constitué du sujet de l'article. Typiquement: introduction au sujet, explication, illustration par les exemples/métaphores/comparaisons, conclusion et ressenti personnel.
- L'article doit impérativement donner accès aux ressources qui lui ont permis d'être développé. Ces ressources peuvent être d'autres articles vérifiés, des livres, des vidéos ou des topics dans des forums.

## Commits / Pull requests

Vous devez suivre les règles suivantes pour la rédaction des noms de commits / pull requests.

## Type de la modification: ce que vous avez fait / rajouté

Les types de modification peuvent être :

- correction
- x64
- arm
- misc (on y compte par exemple les ports COM, les systèmes de fichiers ou tout autre chose qui ne rentre pas dans les catégories d'architecture)
- exemple (ajout d'exemple)
- autre (pour autre chose qui n'y entre pas)

Il est recommandé de ne pas faire plus d'un commit par Pull Request.

## Marche à suivre pour les exemples

- Suivez la structure des documents, pour que l'exemple en question soit cohérent avec le reste de l'article.
- Appliquez-vous sur votre code (lisibilité, commentaires, vérification).
- Même si les langages majoritairement utilisés sont le C, le C++ et l'assembleur x86 (voir la liste en haut de la page), il peut être utile d'utiliser d'autres langages de programmation/schématiques qui permettraient d'interpréter clairement une information.
