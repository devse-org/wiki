# 0 - Introduction

## Préface

Ce tutoriel vous expliquera les __bases__ du fonctionnement d'un système d'exploitation par la réalisation pas à pas d'un kernel minimaliste.

⚠️Pour suivre ce tutoriel, il vous est recommandé d'utiliser un système UNIX-Like tel que GNU/Linux. Bien que vous pouvez utilisez Windows celà demande un peux plus de travail et nous n'aborderons pas les étapes necessaires à l'instalation d'un environement de developpement sous Windows.

Avant de se lancer il faut garder en tête que le developpement de système d'exploitation est très long. Il faut donc être conscient qu'il ne s'ajis pas d'un petit projet de quelques jours. Beaucoup de système d'exploitation sont abandonné faute de motivation dans la durée. Aussi n'ayez pas les yeux plus gros que le ventre: vous n'inventerez pas le nouveau Windows ou OS X.

Pour pouvoir menner a bien ce type de projet il faut déjà posseder des bases en programmation, pas besoin d'être un expert avec 30ans d'experience en C rassurez vous.

Une erreur commune est de se lancer dans des gros projet tel que des MMORPG ou dans le cas présent un kernel sans toutefois connaitre la programmation

Bien que dans ce tutoriel nous utiliserons assez peu l'assembleur, en connaitre les bases est un sérieux plus.

Bref vous l'aurez compris, ne vous lancez pas dans un tel projet si vous n'avez pas un minimum de base. (N'essayez pas d'apprendre sur le tas, prennez du recul, apprennez a programmer et revennez)

Aussi gardez en tête de vous ne pouvez pas coder un système d'exploitation dans n'importe quel langage et la majorité des ressources que vous trouverez sur le net tourne autours du C, C++ voir du Rust.

Il est important que vous prenniez le temps de bien lire les explications plutôt de vous jettez directement sur le code et faire de bête copier/coller. Si vous ne comprennez pas du premier coup ce n'est pas grave, pensez a faire vos propres recherches et à relire plus tard à tête reposé.

## Introduction

### Qu'est ce qu'un kernel (ou noyau) ?

Le Kernel est l'élément central d'un système d'exploitation, il est chargé par le boot loader.

Le kernel a plusieurs responsabilités comme celle de gérer la mémoire, le multitaches etc. Il existe plusieurs type de noyeau qui change grandement la manière d'aborder les systèmes d'exploitations.

La conception du kernel et ses responsabilité change en fonction du type de [kernel](/types-de-kernel.html) et de la vision de l'auteur.

### Qu'est ce qu'un bootloader ?

Un bootloader est générallement ce qui permet de faire passer de la machine qui démarre à une machine prête pour faire booter/démarrer le noyau 

Un bootloader peut aussi charger des éléments important pour le kernel, comme des modules chargé dans le disques, l'A20 etc...

Dans ce tutoriel nous utiliserons [Limine](https://github.com/limine-bootloader/limine)

### L'architecture 

L'architecture c'est comment un processeur est structuré, comment il fonctionne, quel est son language assembly. 
Il y a plusieurs architecture et un kernel peut en supporter plusieurs en même temps : 

- x86 
- riscV
- arm
- powerpc
- et bien d'autres

l'architecture est importante, ici nous prenons le x86 car c'est l'architecture la plus utilisée.

le x86 est divisé en *modes* : 


| nom anglais       |nom français   |taille de registre
|------------       |-------------  |-
|real mode          |mode réel      |16/20 bit
|protected mode     |mode protégé   |32bit
|long mode          |mode long      |64bit

nous utiliserons ici le mode long car il est le plus récent, même si il a moins de documentation que le mode protégé.


### Comment ?
Comment coder un kernel ? 

Il faut prendre la route que l'on veut, mais il y a des éléments important qu'il faut faire dans un ordre à peut près précis,

Vous pouvez dans certains cas faire l'ordre que vous voulez mais il faut quand même une route... car parfois on se pose la question : quoi faire après ? 

Donc cette route ici est recommandé mais vous faites comme vous le souhaitez 


- démarrage
- com // pour le debugging 
- gdt
- idt
- interruption  // pour le debugging d'erreur
- pit 
- gestion de mémoire physique
- pagination 
- multitache 

à partir d'ici tout deviens très subjectif vous pouvez enchainer sur le smp, le système de fichier, les tâches utilisatrices, etc...
