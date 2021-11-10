# Verrou

Le verrou est utilisé pour qu'un même code soit exécuté par un thread à la fois.

On peut, par exemple, utiliser un verrou pour un driver ATA, afin qu'il n'y ait plusieurs écritures en même temps. On utilise alors un verrou au début de l'opération que l'on débloque à la fin.

Un équivalent en code serait:

```c
struct Lock lock;

void ata_read(/* ... */)
{
    acquire(&lock);

    /* ... */

    release(&lock);
};
```

## Prérequis

Même si le verrou utilise l'instruction `lock` il peut être utilisé même si la machine ne possède qu'un seul processeur.
Pour comprendre le verrou il faut avoir un minimum de base en assembleur.

## L'instruction `LOCK`

l'instruction `lock` est utilisée juste avant une autre instruction qui accède / écrit dans la mémoire.

Elle permet d'obtenir la possession exclusive de la partie du cache concernée le temps que l'instruction s'exécute. Un seul CPU à la fois peut exécuter l'instruction.

Exemple de code utilisant le lock :

```asm
lock bts dword [rdi], 0
```

## Verrouillage & Déverrouillage

### Code assembleur

pour verrouiller on doit implémenter une fonction qui vérifie le vérrou,
si il est à 1, alors le verrou est bloqué, on doit attendre.
si il est à 0, alors le verrou est débloqué, c'est notre tour.

pour le déverrouiller on doit juste mettre le vérou à 0.

pour le verrouillage le code pourrait ressembler à ceci :
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

Ce code test le bit 0 de l'addresse contenu dans le registre `rdi` (registre utilisé pour les arguments de fonctions en 64bit)

```x86asm
lock bts dword [rdi], 0
jc spin
```
si le bit est à 0 il le met à 1 et CF à 0
si le bit est à 1 il met CF à 1

jc spin jump à spin seulement si CF == 1

pour le déverrouillage le code pourrait ressembler à ceci :

```x86asm
unlock:
    lock btr dword [rdi], 0
    ret
```

il réinitialise juste le bit contenu dans `rdi`

Maintenant on doit rajouter un temps mort

parfois si un CPU a crash ou a oublié de déverrouiller un verrou il peut arriver que les autres CPU soient bloqués? Il est donc recommandé de rajouter un temps mort pour signaler l'erreur.

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
Il incrémente chaque fois et si il est égal à `0xfffffff` alors il saute à `timed_out`

On peut utiliser une fonction C/C++ dans timed_out

### Code C

Dans le code C on peut se permettre de rajouter des informations au verrou. On peut rajouter le fichier, la ligne, le cpu etc...
cela permet de mieux débugger si il y a une erreur dans le code


Les fonction en c doivent être utilisées comme ceci :

```cpp
void lock(volatile uint32_t* lock);
void unlock(volatile uint32_t* lock);
```

Si on veut rajouter plus d'informations au lock on doit faire une structure contenant un membre 32bit

```cpp
struct verrou
{
    uint32_t data; // ne doit pas être changé
    const char* fichier;
    uint64_t line;
    uint64_t cpu;
} __attribute__(packed);
```
Vous devez maintenant rajouter des fonction verrouiller et déverrouiller qui appelleront respectivement lock et unlock

> Note : si vous voulez avoir la ligne/le fichier, vous devez utiliser des #define et non des fonction

```cpp
void verrouiller(verrou* v)
{
    // code pour remplir les données du vérrou

    lock(&(v->data));
}

void deverrouiller(verrou* v)
{
    unlock(&(v->data));
}
```

Maintenant vous devez implementer la fonction qui serra appelé dans `timed_out`

```cpp
void crocheter_le_verrou(verrou* v)
{
    // vous pouvez log des informations importantes ici
}
```

maintenant vous pouvez choisir entre 2 possibilité :

* dans la fonction crocheter_le_verrou vous continuez en attandant jusqu'à ce que le verrou soit déverrouillé

* dans la fonction crocheter_le_verrou vous devez mettre le membre `data` du vérou v à 0, ce qui forcera le verrou à être déverrouiller

## Utilisation

Maintenant, pour utiliser votre verrou, vous pouvez juste faire

```c
struct Lock lock;

void ata_read(/* ... */)
{
    acquire(&lock);

    /* ... */

    release(&lock);
}
```

Le code sera désormais exécuté seulement sur 1 cpu à la fois !

Il est important d'utiliser les verrou quand il le faut, dans un allocateur de frame, le changement de contexte, l'utilisation d'appareils...
