# Verrou

Le verrou est utilisé pour que un processeur accède à un code à la fois.

Par exemple, on peut utiliser un verrou pour un driver ATA, pour éviter qu'il y ait plusieurs écritures en même temps alors on utilise un verrou au début et on le débloque à la fin. 

Un équivalent serrait : 

```cpp
struct verrou ata_verrou = 0;
void ata_read(){
    verrouiller(&ata_verrou);
    // [CODE]
    deverrouiller(&ata_verrou);
};
```

## Préréquis
Même si le verrou utilise l'instruction `lock` il peut être utiliser même si on a qu'un seul processeur.
Pour comprendre le verrou il faut avoir un minimum de base en assembleur.

## L'instruction `LOCK`

L'instruction `lock` est utilisé juste avant une autre instruction qui accède / écrit dans la mémoire.

Cette instruction permet d'obtenir la possession exclusive de la partie du cache concernée le temps que l'instruction s'exécute. Un seul cpu à la fois peut éxecuter l'instruction.

Exemple de code utilisant le lock : ou 
```x86asm
lock bts dword [rdi], 0
```

## Verrouillage & Déverrouillage
### Code assembleur
Pour verrouiller on doit implémenter une fonction qui vérifie le vérrou :
- si il est à 1, c'est qu'il est verrouillé et que l'on doit attendre
- si il est à 0, c'est que on peut le déverrouiller 

Pour le deverrouiller, il suffit donc de mettre le vérou à 0.

Pour le verrouillage le code pourrait ressembler à ceci : 
```x86asm
locker:
    lock bts dword [rdi], 0
    jc spin
    ret

spin:
    pause   ; pour gagner des performances
    test dword [rdi], 0
    jnz spin 
    jmp locker
```

Ce code test le bit 0 de l'addresse contenu dans le registre `rdi` (registre utilisé pour les arguments de fonctions en 64bit)

```x86asm
lock bts dword [rdi], 0
jc spin
``` 
Si le bit est à 0 il le met à 1 et CF à 0
Si le bit est à 1 il met CF à 1 

jc spin jump à spin seulement si CF == 1

Pour le dévérouillage le code pourrait ressembler à ceci :
```x86asm
unlock: 
    lock btr dword [rdi], 0
    ret
```

Il réinitialise simplement le bit contenu dans `rdi`.

Désormais, il nous faut ajouter un temps mort, en effet, si un cpu a crasher ou a oublié de déverrouiller un verrou il peut arriver que les autres cpu soient bloqués donc, il est recommandé de rajouter un temps mort pour signaler l'erreur.
On peut faire cela ainsi : 

```x86asm
locker:
    mov rax, 0
    lock bts dword [rdi], 0
    jc spin
    ret

spin:
    inc rax
    cmp rax, 0xfffffff
    je timed_out

    pause   ; pour gagner des performances
    test dword [rdi], 0
    jnz spin 
    jmp locker

timed_out: 
    ; code du time out 
```
Le temps pris ici est stocké dans le registre `rax`.
A chaque fois, ce registre est incrementer jusqu'a arriver à `0xfffffff` alors il saute à 
`timed_out`.

On peut utiliser une fonction c/c++ dans 
timed_out

### Code C

Dans le code c on peut se permettre de rajouter des informations au verrou.
On peut par example rajouter le fichier, la ligne, le cpu etc...
Cela permet de mieux débugger si il y a une 
erreur dans le code.


Les fonction en C/C++ doivent être utilisé comme ceci : 

```cpp
void locker(volatile uint32_t* lock);
void unlock(volatile uint32_t* lock);
```
Dans le cas ou l'on voudrais rajouter plus d'information au lock, il faut faire une structure contenant un membre 32bit, comme ceci :

```cpp
struct verrou{
    uint32_t data; // ne doit pas être changé
    const char* fichier;
    uint64_t line;
    uint64_t cpu;
}__attribute__(packed);
``` 
Maintenant vous devez rajouter des fonction 
verrouiller et déverrouiller qui appellerons 
locker et unlock

*note : si vous voulez avoir la ligne/le fichier, vous devez utiliser des #define et non des fonction*

Example ! 
```cpp
void verrouiller(verrou* v){

    // code pour remplir les données du vérrou

    locker(&(v->data));
}
void deverrouiller(verrou* v){
    unlocker(&(v->data));
}
``` 
Il vous faut maintenant implementer la fonction qui serra appelé dans `timed_out` : 

```cpp
void crocheter_le_verrou(verrou* v){
    // vous pouvez log des informations importantes ici
}
``` 
Vous avez maintenant deux choix : 

1- dans la fonction  crocheter_le_verrou vous continuez en attandant jusqu'à ce que le vérrou soit deverrouillé

2- Dans la fonction crocheter_le_verrou vous mettez le membre `data` du vérou v à 0, ce qui forcera le vérrou à être dévérouiller

## Utilisation

Pour utiliser le verrou, il ne vous reste plus qu'a faire : 
```cpp
verrou ata_verrou = {0};

void ata_read(){
    verrouiller(&ata_verrou);
    // votre code ici
    deverrouiller(&ata_verrou);
}
```
Le code serra alors éxecuté sur un cpu a la fois !

Il est important d'utiliser les verrou quand il le faut, dans un allocateur de frame, le changement de context, l'utilisation d'appareils...

