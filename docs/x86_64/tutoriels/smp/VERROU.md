# VERROU

le verrou est utilisé pour que un processeur accède à un code à la fois

par exemple on peut utiliser un verrou pour un driver ATA, pour éviter qu'il y ait plusieurs écritures en même temps alors on utilise un verrou au début et on le débloque à la fin 

un équivalent serrait : 

```cpp
struct verrou ata_verrou = 0;
void ata_read(){
    verrouiller(&ata_verrou);
    // [CODE]
    deverrouiller(&ata_verrou);
};
```

## Préréquis
même si le verrou utilise l'instruction `lock` il peut être utiliser même si on a qu'un seul processeur.
pour comprendre le verrou il faut avoir un minimum de base en assembleur.

## L'instruction `LOCK`

l'instruction `lock` est utilisé juste avant une autre instruction qui accède / écrit dans la mémoire

elle permet d'obtenir la possession exclusive de la partie du cache concernée le temps que l'instruction s'exécute. Un seul cpu à la fois peut éxecuter l'instruction.

exemple de code utilisant le lock :ou 
```x86asm
lock bts dword [rdi], 0
```

## VERROUILLAGE & DEVERROUILLAGE
### CODE ASSEMBLY
pour verrouiller on doit implémenter une fonction
qui vérifie le vérrou,
si il est à 1, c'est qu'il est verrouillé et que l'on doit attendre
si il est à 0, c'est que on peut le déverrouiller 

pour le deverrouiller on doit juste mettre le vérou à 0

pour le verrouillage le code pourrait ressembler à ceci : 
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

ce code test le bit 0 de l'addresse contenu dans le registre `rdi` (registre utilisé pour les 
arguments de fonctions en 64bit)

```x86asm
lock bts dword [rdi], 0
jc spin
``` 
si le bit est à 0 il le met à 1 et CF à 0
si le bit est à 1 il met CF à 1 

jc spin jump à spin seulement si CF == 1

pour le dévérouillage le code pourrait ressembler à ceci :
```x86asm
unlock:
    lock btr dword [rdi], 0
    ret
```

il reset juste le bit contenu dans `rdi`

maintenant on doit rajouter un temps mort

parfois si un cpu a crash ou a oublié de déverrouiller un verrou il peut arriver que les autres cpu soient bloqués donc il est recommandé de rajouter un temps mort pour signaler l'erreur

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
le temps pris ici est stocké dans le registre `rax`
à chaque fois il l'incrémente et si il est égal à `0xfffffff` alors il saute à 
`timed_out`

on peut utiliser une fonction c/c++ dans 
timed_out

### CODE C

dans le code c on peut se permettre de rajouter des informations au verrou, 
on peut rajouter le fichier, la ligne, le cpu etc...
cela permet de mieux débugger si il y a une 
erreur dans le code


les fonction en c doivent être utilisé comme ceci : 

```cpp
void locker(volatile uint32_t* lock);
void unlock(volatile uint32_t* lock);
```
si on veut rajouter plus d'information au lock on doit faire une structure contenant un membre 32bit 

```cpp
struct verrou{
    uint32_t data; // ne doit pas être changé
    const char* fichier;
    uint64_t line;
    uint64_t cpu;
}__attribute__(packed);
``` 
maintenant vous devez rajouter des fonction 
verrouiller et déverrouiller qui appellerons 
locker et unlock

*note : si vous voulez avoir la ligne/le fichier, vous devez utiliser des #define et non des fonction*

```cpp
void verrouiller(verrou* v){

    // code pour remplir les données du vérrou

    locker(&(v->data));
}
void deverrouiller(verrou* v){
    unlocker(&(v->data));
}
``` 

maintenant vous devez implementer la fonction qui serra appelé dans `timed_out`

```cpp
void crocheter_le_verrou(verrou* v){
    // vous pouvez log des informations importantes ici
}
``` 
maintenant vous pouvez choisir entre 2 possibilité : 

* dans la fonction  crocheter_le_verrou vous continuez en attandant jusqu'à ce que le vérrou soit deverrouillé

* dans la fonction crocheter_le_verrou vous mettez le membre `data` du vérou v à 0, ce qui forcera le vérrou à être dévérouiller

## utilisation

maintenant pour utiliser votre verrou vous pouvez juste faire 
```cpp
verrou ata_verrou = {0};

void ata_read(){
    verrouiller(&ata_verrou);
    // votre code ici
    deverrouiller(&ata_verrou);
}
```
et le code serra éxécuté seulement à 1 cpu à la fois !

Il est important d'utiliser les verrou quand il le faut, dans un allocateur de frame, le changement de context, l'utilisation d'appareils...

