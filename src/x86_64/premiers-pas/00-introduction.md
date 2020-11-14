# 0 - Introduction
Ici nous ne ferrons pas de programmation, juste des bonnes définitions pour être préparé.

## Préface (aka gate keeping)
ce tutoriels vous expliqueras comment créer les __bases__ d'un kernel




il faut savoir que c'est très dur et long. Beaucoup de kernel sont abandonné... 

il faut être déterminé et savoir coder, il faut bien connaitre le c ou c++ (le rust ne serra pas abordé dans ces tutoriels)
il faut aussi comprendre l'assembleur,cependant  l'architecture de l'assembleur dépend de vos envie. Et il ne serra pas énormément présent

Il ne faut pas commencer un kernel en parralèle d'apprendre un language, ce serra beaucoup plus dur.

Il ne faut pas croire que toutes vos application vont supporter windows, 
    
Vous ne pouvez pas coder un kernel en js

Il est __très très très__ recommandé d'utilisé linux, windows complique la vie et wsl est très lent

Il faut lire et ne pas juste faire des bêtes copier coller.

## Introduction

### Qu'est ce qu'un kernel (ou noyau) ?

Un noyau est l'une des plus grosse partie d'un système d'exploitation. Il permet aux application utilisateur d'accèder au compostants et périphériques. Il gère la mémoire, les fichier, les processus, les drivers, les processeur,  une partie de la sécurité etc...

Un noyau est l'étape après le boot loader, ou le chargeur de boot.

### Qu'est ce qu'un bootloader ?

Un bootloader est générallement ce qui permet de faire passer de la machine qui démarre à une machine prête pour faire booter/démarrer le noyau 

Il est très important et très compliqué, il est recommandé de ne pas écrire son propre bootloader quand on débute, cela va vite vous décourager...

Un bootloader peut aussi charger des éléments important pour le kernel, comme des modules chargé dans le disques, l'A20 etc...
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


| nom anglais   |nom français   |taille de registre
|------------   |-------------  |-
|real mode      |mode réel      |16/20 bit
|protected mode |mode protégé   |32bit
|long mode      |mode long      |64bit

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
