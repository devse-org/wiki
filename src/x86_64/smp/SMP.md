# Symmetric Multiprocessing

## Un peu de vocabulaire

Les termes "coeurs" et "CPU" seront utilisés tout au long de ce tutoriel. Ils représentent tous deux la même entité, à savoir, une unité centrale de traitement. Vous aurez remarqué que ce groupe nominal barbare peut être littéralement traduit par "Central Processing Unit", ou CPU.

Le terme "thread" désigne un fil d'instructions, exécuté en parallèle à d'autres threads ; ou, autrement dit, un flot d'instructions dont l'exécution n'interfère généralement pas avec l'exécution d'un autre flot d'instructions.

## Prérequis

Dans ce tutoriel, pour implémenter le SMP, nous prenons en compte que vous avez déjà implémenté la base de votre noyau :

- [IDT](/x86_64/structures/IDT.md)
- [GDT](/x86_64/structures/GDT.md)
- [MADT](/x86_64/acpi/MADT.md)
- [APIC](/x86_64/périphériques/APIC.md)
- Paging

On considère aussi que la structure de votre noyau est composée de ces caractéristiques :

- Une architecture higher-half
- Un support du 64 bits
- Un système de temporisation

## Introduction

Qu'est ce que le SMP ?

SMP est un sigle signifiant "Symetric Multi Processing", que l'on pourrait littéralement traduire par "Multi-traîtement symétrique". On utilise ce terme pour parler d'un système multiprocesseur, qui exploite plusieurs CPUs de façon parallèle. Un noyau qui supporte le SMP peut bénéficier d'énormes améliorations de performances.

En sachant que - __généralement__ - un processeur possède 2 threads par coeur, pour un processeur de 8 coeurs il y aura 16 threads exploitables.

Le SMP est différent de NUMA, les processeurs NUMA sont des processeurs dont certains de leurs coeurs n'ont pas accès à toute la mémoire.

Il est utile de savoir qu'il faudra implémenter les interruptions [APIC](/x86_64/périphériques/APIC.md) pour les autres CPUs, ce qui n'est pas abordé dans ce tutoriel (pour l'instant).

## Obtenir le numéro du coeur actuel

Obtenir le numero du coeur actuel est très important pour plus tard, il permet d'identifier le CPU sur lequel on travaille.

Pour obtenir l'identifiant du CPU actuel on doit utiliser l'[APIC](/x86_64/périphériques/APIC.md). Le numéro du CPU est contenu dans le registre 20 de l'APIC, et il est situé du 24ème au 32ème bit, il faut donc décaler à droite la valeur lue de 24 bits.

```cpp
#define LAPIC_REGISTER 20
uint32_t get_current_processor_id()
{
    return apic_read(LAPIC_REGISTER) >> 24;
}
```

## Obtenir les entrées Local APIC

Voir : [LAPIC](/x86_64/périphériques/APIC.md)

Pour commencer à utiliser le SMP, il faut obtenir les entrées LAPIC de la table MADT. Chaque CPU posède une entrée LAPIC.

Pour connaitre le nombre total de CPUs il suffit donc de compter le nombre de LAPIC dans la MADT.

Ces entrées LAPIC ont deux valeurs importantes:

- __`ACPI_ID`__ : un identifiant utilisé par l'ACPI,
- __`ACIC_ID`__ : un identifiant utilisé par l'APIC pendant l'initialisation.

Généralement, sur les processeurs modernes, `ACPI_ID` et `APIC_ID` sont égaux, mais ce n'est pas toujours le cas.

Pour utiliser les autres CPU, il faudra faire attention : le CPU principal (celui sur lequel votre kernel démarre) est aussi dans la liste. Il faut donc vérifier que le CPU que l'on souhaite utiliser est libre. Pour cela, il suffit de comparer l'identifiant du CPU actuel avec l'identifiant du CPU de l'entrée `LAPIC`.

```cpp
// lapic_entry : entrée LAPIC que l'on est en train de manipuler
if (get_current_processor_id() == lapic_entry.apic_id) {
    // On est actuellement en train de traiter le CPU principal, attention à ne pas faire planter votre kernel!
} else {
    // Ce CPU n'est pas le CPU principal, on peut donc s'en servir librement.
}
```

## Pre-Initialisation

Pour utiliser les CPUs, il faut d'abord les préparer, en particulier préparer l'IDT, la table de page, la GDT, le code d'initialisation...

On place donc tout ceci de cette façon :

| Entrée             | Adresse |
| ------------------ | ------- |
| Code du trampoline | 0x1000  |
| Pile               | 0x570   |
| GDT                | 0x580   |
| IDT                | 0x590   |
| Table de page      | 0x600   |
| Adresse de saut    | 0x610   |

Il faut savoir que tout ceci est temporaire, tout devra être remplacé plus tard.

### GDT + IDT

Pour stocker la GDT et l'IDT, c'est assez simple.
Il existe deux instructions en 64 bits qui sont dédiées:

- `sgdt [adresse]` pour stocker la GDT à une adresse précise,
- `sidt [adresse]` pour stocker l'IDT à une adresse précise.

Dans notre cas on a donc:

```x86asm
sgdt [0x580] ; stockage de la GDT
sidt [0x590] ; stockage de l'IDT
```

### Pile

Pour initialiser la pile on doit stocker une adresse valide à l'adresse `0x570`:

```cpp
POKE(570) = stack_address + stack_size;
```

### Code du trampoline

Pour le trampoline nous avons besoin d'un code écrit en assembleur, délimité par `trampoline_start` et `trampoline_end`.

Le code trampoline doit être chargé à partir de l'adresse `0x1000`, ce qui donne pour la partie cpp :

```c
#define TRAMPOLINE_START 0x1000

// On calcule la taille du programme trampoline pour copier son contenu
uint64_t trampoline_len = (uint64_t)&trampoline_end - (uint64_t)&trampoline_start;

// On copie le code trampoline au bon endroit
memcpy((void *)TRAMPOLINE_START, &trampoline_start, trampoline_len);
```

et dans le code assembleur, on spécifie le code trampoline avec :

```x86asm
trampoline_start:
    ; code du trampoline
trampoline_end:
```

### Addresse de saut

L'addresse de saut est l'adresse à laquelle va se rendre le CPU juste après son initialisaiton, on y met donc le programme principal.

### Table de page pour le futur CPU

Pour le futur CPU on peut choisir de prende une copie de la table de page actuelle, mais attention il faut effectuer une copie, et pas simplement une référence à l'ancienne, sinon des évènements étranges peuvent avoir lieu.

## Chargement du CPU

Pour initialiser le nouveau CPU, il faut demander à l'APIC de le charger.
Pour ce faire, on utilise les deux registres de commande d'interuptions `ICR1` (registre `0x0300`) et `ICR2`.

Pour initialiser le nouveau CPU il faut envoyer à l'APIC l'identifiant du nouveau CPU dans `ICR2` et l'interuption d'initialisation dans `ICR1` :

```cpp
// On écrit l'identifiant du nouveau CPU dans ICR2, attention à bien utiliser son identifiant APIC
write(icr2, (apic_id << 24));
// On envoie la demande d'initialisation
write(icr1, 0x500);
```

L'initialisation peut être un peu longue, il faut donc attendre au moins 10 millisecondes avant de l'utiliser.

On commence par envoyer le nouveau CPU à l'adresse trampoline, là encore à travers l'APIC. L'identifiant du CPU va encore dans `ICR2`, et l'instruction à écrire dans `ICR1` devient `0x0600 | (trampoline_addr >> 12)` :

```cpp
// Chargement de l'identifiant du nouveau CPU
write(icr2, (apic_id << 24));
// Chargement de l'adresse trampoline
write(icr1, 0x600 | ((uint32_t)trampoline_addr / 4096));
```

## Le code du trampoline

Pour commencer, on peut simplement utiliser le code suivant, qui envoie le caractère `a` sur le port `COM0`.
Ce code est bien sûr temporaire, mais permet de vérifier que le nouveau CPU démarre correctement.

```x86asm
mov al, 'a'
mov dx, 0x3F8
out dx, al
```

Lorsque le CPU est initialisé il est en 16 bits, il le sera donc aussi lors de l'exécution du trampoline.
Il faut donc penser à modifier la configuration du CPU pour le passer en 64 bits.
On aura donc 3 parties dans le trampoline : pour passer de 16 à 32 bits, puis de 32 à 64 bits et enfin le trampoline final en 64 bits :

```x86asm
[16 bits]
trampoline_start:

trampoline_16:
    ;...

[32 bits]
trampoline_32:
    ;...

[64 bits]
trampoline_64:
    ;...

trampoline_end:
```

### Le code 16 bits

*Note : trampoline_addr est l'addresse ou vous avez placé votre trampoline, dans ce cas, `0x1000`.*

On commence par passer de 16 bits à 32 bits.
Pour cela, il faut initialiser une nouvelle GDT et mettre le bit 0 du `cr0` à 1 pour activer le mode protégé :

```x86asm
cli ; On désactive les interrupt, c'est important pendant le passage de 16 à 32 bits
mov ax, 0x0 ; On initialise tous les registres à 0
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
```

On doit créer une GDT 32 bits pour le 32 bit, on procède donc ainsi :

```x86asm
align 16
gdt_32:
    dw gdt_32_end - gdt_32_start - 1
    dd gdt_32_start - trampoline_start + trampoline_addr

align 16
gdt_32_start:
    ; descripteur NULL
    dq 0
    ; descripteur de code
    dq 0x00CF9A000000FFFF
    ; descripteur de donné
    dq 0x00CF92000000FFFF
gdt_32_end:
```

Et on doit maintenant charger cette GDT :

```x86asm
lgdt [gdt_32 - trampoline_start + trampoline_addr]
```

On peut donc activer le mode protégé :

```x86asm
mov eax, cr0
or al, 0x1
mov cr0, eax
```

...Puis sauter en changeant le *segment code* vers l'entrée `0x8` de la GDT :

```x86asm
jmp 0x8:(trampoline32 - trampoline_start + trampoline_addr)
```

### Le code 32 bits

On doit dans un premier temps charger la table de page dans le `cr3`, puis activer le paging et le PAE du `cr4` en activant les bits 5 et 7 du registre `cr4` :

```x86asm
; Chargement de la table de page :
mov eax, dword [0x600]
mov cr3, eax
; Activation du paging et du PAE
mov eax, cr4
or eax, 1 << 5
or eax, 1 << 7
mov cr4, eax
```

On active maintenant le mode long, en activant le 8ème bit de l'EFER (*Extended Feature Enable Register*) :

```x86asm
mov ecx, 0xc0000080 ; registre efer
rdmsr

or eax,1 << 8
wrmsr
```

On active ensuite le paging en écrivant le 31ème bit du registre `cr0` :

```x86asm
mov eax, cr0
or eax, 1 << 31
mov cr0, eax
```

Et pour finir il faut créer puis charger une GDT 64 bits :

```x86asm
align 16
gdt_64:
    dw gdt_64_end - gdt_64_start - 1
    dd gdt_64_start - trampoline_start + trampoline_addr

align 16
gdt_64_start:
    ; null selector 0x0
    dq 0
    ; cs selector 8
    dq 0x00AF98000000FFFF
    ; ds selector 16
    dq 0x00CF92000000FFFF
gdt_64_end:

; Chargement de la nouvelle GDT
lgdt [gdt_64 - trampoline_start + trampoline_addr]
```

On peut ensuite passer à la section 64 bits, en utilisant l'instruction `jmp` comme précédement :

```x86asm
; jmp 0x8 : permet de charger le segment de code de la GDT
jmp 0x8:(trampoline64 - trampoline_start + trampoline_addr)
```

### Le code 64 bits

On commence par définir les valeurs des registre `ds`, `ss` et `es` en fonction de la nouvelle GDT :

```x86asm
mov ax, 0x10
mov ds, ax
mov es, ax
mov ss, ax
mov ax, 0x0
mov fs, ax
mov gs, ax
```

Et on charge ensuite la GDT, l'IDT et la stack au bon endroit :

```x86asm
; Chargement de la GDT
lgdt [0x580]
; Chargement de l'IDT
lidt [0x590]
; Chargement de la stack
mov rsp, [0x570]
mov rbp, 0x0
```

On doit ensuite passer du code trampoline au code physique à exécuter sur ce nouveau CPU.
C'est à ce moment que on doit activer certains bits de `cr4` et `cr0` et surtout le SSE !

```x86asm
jmp virtual_code

virtual_code:
    mov rax, cr0
    ; Activation du monitoring de multi-processeur et de l'émulation
    btr eax, 2
    bts eax, 1
    mov cr0, rax
```

Enfin, pour terminer l'initialisation de ce nouveau CPU il faut finir par :

```x86asm
    mov rax, [0x610]
    jmp rax
```

## Note de fin

Le nouveau CPU est maintenant fonctionnel, mais ce n'est pas encore fini.
Il faut mettre en place un système de lock pour la communication inter-CPU, mettre à jour le multitasking pour utiliser ce nouveau CPU, charger une GDT, un IDT et une stack unique...

## Ressources

- [manuel intel](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
- [osdev](https://wiki.osdev.org/Main_Page)
