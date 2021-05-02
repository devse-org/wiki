# 0 - Introduction

## Préface

Ce tutoriel vous expliquera les __bases__ du fonctionnement d'un système d'exploitation par la réalisation pas à pas d'un kernel minimaliste.

⚠️ Pour suivre ce tutoriel, il vous est recommandé d'utiliser un système UNIX-Like tel que GNU/Linux. Bien que vous puissiez utiliser Windows celà demande un peux plus de travail et nous n'aborderons pas les étapes necessaires à l'instalation d'un environement de developpement sous Windows.

Avant de se lancer il faut garder en tête que le developpement de système d'exploitation est très long. Il faut donc être conscient qu'il ne s'agit pas d'un petit projet de quelques jours. Beaucoup de systèmes d'exploitation sont abandonnés faute de motivation dans la durée. Aussi n'ayez pas les yeux plus gros que le ventre: vous n'inventerez pas le nouveau Windows ou OS X.

Pour pouvoir mener a bien ce type de projet il faut déjà posseder des bases en programmation, pas besoin d'être un expert avec 30ans d'expérience en C rassurez vous.

Une erreur commune est de se lancer dans de gros projet tels qu'un MMORPG ou dans le cas présent un kernel sans toutefois connaitre la programmation

Bien que dans ce tutoriel nous utiliserons assez peu l'assembleur, en connaitre les bases est un sérieux plus.

Bref. Vous l'aurez compris. Ne vous lancez pas dans un tel projet si vous n'avez pas un minimum de base. (N'essayez pas d'apprendre sur le tas, prennez du recul, apprennez a programmer et revennez)

Aussi gardez en tête que vous ne pouvez pas programmer un système d'exploitation dans n'importe quel langage et la majorité des ressources que vous trouverez sur le net tournent autours du C, C++ voire du Rust.

Il est important que vous prenniez le temps de bien lire les explications plutôt de vous jeter directement sur le code et faire de bêtes copier/coller. Si vous ne comprennez pas du premier coup ce n'est pas grave, pensez a faire vos propres recherches et à relire plus tard à tête reposée.

## Introduction

### Qu'est ce qu'un kernel (ou noyau) ?

Le Kernel est l'élément central d'un système d'exploitation, il est chargé par le boot loader.

Le kernel a plusieurs responsabilités comme celle de gérer la mémoire, le multitaches etc. Il existe plusieurs types de noyeaux qui change grandement la manière d'aborder les systèmes d'exploitations.

La conception du kernel et ses responsabilités changent en fonction du type de [kernel](types-de-kernel.md) et du point de vue de l'auteur.

### Qu'est ce qu'un bootloader ?

Un bootloader un programme permettant de démarrer votre kernel.

Un bootloader peut aussi charger des éléments important pour le kernel, comme des modules chargé dans le disques, l'A20 etc...

Dans ce tutoriel nous utiliserons [Limine](https://github.com/limine-bootloader/limine)

### L'architecture

L'architecture c'est la façon dont un processeur est structuré, sa façon de fonctionner, son [ISA](https://en.wikipedia.org/wiki/Instruction_set_architecture).
Il y a plusieurs architecture et un kernel peut en supporter plusieurs en même temps :

- x86
- RISC-V
- ARM
- PowerPC
- Et bien d'autres...

L'architecture est importante, ici nous prenons le x86 car c'est l'architecture la plus utilisée.

Le x86 est divisé en *modes* :

| nom anglais    | nom français | taille de registre |
| -------------- | ------------ | ------------------ |
| real mode      | mode réel    | 16/20 bit          |
| protected mode | mode protégé | 32bit              |
| long mode      | mode long    | 64bit              |

Nous utiliserons ici le mode long, car il est le plus récent, même si il a moins de documentation que le mode protégé.

### Comment ?

Comment coder un kernel ?

Il faut prendre la route que l'on veut, mais il y a des éléments importants qu'il faut faire dans un ordre assez précis.

Vous pouvez dans certains cas le faire dans l'ordre que vous voulez mais il faut quand même une route... car parfois on se pose la question : que faire ensuite ?

La route ci-dessous est recommandée mais vous pouvez le faire de la manière dont vous l'entendez:

- démarrage
- com // pour le debugging
- GDT (Global Descriptor Table) utilisée à l'époque pour la [segmentation de la mémoire](https://fr.wikipedia.org/wiki/Segmentation_(informatique))
- IDT (Interrupt Descriptor Table) utilisée pour gérer les [interruptions](https://fr.wikipedia.org/wiki/Interruption_(informatique))
- Interruption  // pour le debugging d'erreur
- PIT
- Gestion de mémoire physique
- Pagination
- Multitâche

À partir d'ici, tout devient très subjectif vous pouvez enchainer sur le SMP, le système de fichiers, les tâches utilisateur, etc...
