# Verrou


Le verrou est utilisé pour que un code soit éxécuté par un thread à la fois. 

Par exemple on peut utiliser un verrou pour un driver ATA, pour éviter qu'il y ait plusieurs écritures en même temps alors on utilise un verrou au début et on le débloque à la fin.

Un équivalent en code serrait :


```c
struct Lock lock;

void ata_read(/* ... */)
{
    acquire(&lock);

    /* ... */

    release(&lock);
};
```
## Préréquis



Même si le verrou utilise l'instruction `lock`, il peut être utiliser même si on a qu'un seul processeur.

Pour comprendre le verrou il faut avoir un minimum de base en assembleur.

## L'instruction `LOCK`

L'instruction `lock` est utilisé juste avant une autre instruction qui accède / écrit dans la mémoire.


Elle permet d'obtenir la possession exclusive de la partie du cache concernée le temps que l'instruction s'exécute. Un seul cpu à la fois peut éxecuter l'instruction.

Exemple de code utilisant le lock :ou

```asm
lock bts dword [rdi], 0
```

## Verrouillage & Déverrouillage
### Code assembleur


Pour verrouiller on doit implémenter une fonction
qui vérifie le vérrou :
- si il est à 1, cela signifi qu'il est verrouillé et que l'on doit attendre
- si il est à 0, cela signifie que l'on peut le déverrouiller

Pour le deverrouiller il suffit de mettre le vérou à 0.

Pour le verrouillage le code pourrait ressembler à ceci :

```x86asm
locker:
    lock bts dword [rdi], 0
    jc spin
    ret

spin:
    pause   ; pour éviter au processeur de surchauffer
    test dword [rdi], 0
    jnz spin
    jmp locker
```

Ce code test le bit 0 de l'addresse contenu dans le registre `rdi` (registre utilisé pour les
arguments de fonctions en 64bit)

```x86asm
lock bts dword [rdi], 0
jc spin

```
- si le bit est à 0 il le met à 1 et CF à 0

jc spin jump à spin seulement si CF == 1.

Pour le dévérouillage le code pourrait ressembler à ceci :
```x86asm
unlock: 
    lock btr dword [rdi], 0
    ret
```

Il reinitialise juste le bit contenu dans `rdi`

Maintenant, nous devons rajouter un temps mort

Parfois si un cpu a crash ou a oublié de déverrouiller un verrou il peut arriver que les autres cpu soient bloqués donc il est recommandé de rajouter un temps mort pour signaler l'erreur :


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

Le temps pris ici est stocké dans le registre `rax`
A chaque fois il l'incrémente et si il est égal à `0xfffffff` alors il saute à
`timed_out`

On peut utiliser une fonction c/c++ dans
timed_out.

### Code C

Dans le code C on peut se permettre de rajouter des informations au verrou,
on peut rajouter le fichier, la ligne, le cpu etc...
Cela permet de mieux débugger si il y a une
erreur dans le code.


Les fonction en C doivent être utilisé comme ceci :

```cpp
void locker(volatile uint32_t* lock);
void unlock(volatile uint32_t* lock);
```
Si on veut rajouter plus d'information au lock on doit faire une structure contenant un membre 32bit

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
locker et unlock.

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

Maintenant vous devez implementer la fonction qui serra appelé dans `timed_out`

```cpp
void crocheter_le_verrou(verrou* v){
    // vous pouvez log des informations importantes ici
    
}

```
Maintenant vous pouvez choisir entre 2 possibilité :


1- dans la fonction  crocheter_le_verrou vous continuez en attandant jusqu'à ce que le vérrou soit deverrouillé

2- Dans la fonction crocheter_le_verrou vous mettez le membre `data` du vérou v à 0, ce qui forcera le vérrou à être dévérouiller

## Utilisation

Desormais, pour utiliser votre verrou vous pouvez juste faire :

```c
struct Lock lock;

void ata_read(/* ... */)
{
    acquire(&lock);

    /* ... */


void ata_read(){
    verrouiller(&ata_verrou);
    // votre code ici
    deverrouiller(&ata_verrou);
}
```
Ainsi, le code serra éxécuté seulement à 1 cpu à la fois !

Il est important d'utiliser les verrou quand il le faut, dans un allocateur de frame, le changement de contexte, l'utilisation d'appareils...
