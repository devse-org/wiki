# Global Descriptor Table

La table de descripteur globale à été introduite avec le processeur 16bit d'intel (le 80286) pour gérer la mémoire sous forme de segments.

La segmentation ne devrais plus être utilisé, elle a été remplacé par le paging. Le paging est toujours obligatoire pour passer du 32 au 64 bit avec l'architecture x86.

Cependant la `GDT` est aussi utilisée pour contenir la tss. La structure est différente entre le 32 et 64 bit.

La table globale de descripteur est principalement formée de 2 structures:

- la gdtr (le registre de segments)
- le segment

# Le registre de segments

le registre de segments en mode long (x86_64) doit être construit comme ceci:

| nom                 | taille |
| ------------------- | ------ |
| taille              | 16 bit |
| adresse de la table | 64 bit |

__taille__: Le registre taille doit contenir la taille de la table de segment, soit le nombre de segment multiplié par la taille du segment, cependant en 64bit la taille du segment de la TSS est doublé, il faut alors compter le double.

__adresse de la table__: L'adresse de la table doit pointer directement vers la table de segments.

# Les segments 

Un segment en x86_64 est formé comme ceci:

| nom                  | taille |
| -------------------- | ------ |
| limite basse (0-15)  | 16 bit |
| base basse (0-15)    | 16 bit |
| base milieu (16-23)  | 8 bit  |
| flag                 | 8 bit  |
| limite haute (16-19) | 4 bit  |
| granularité          | 4 bit  |
| base haute (24-31)   | 8 bit  |

## Les registres base

Le registre base est le début du segment, en mode long il faut le mettre à 0.

## Les registres limite 

Le registre limite est une adresse 20bit, il représente la fin du segment.
Il est multiplié par 4096 si le bit `granularité` est à 1.
En mode long (64 bit) il faut le mettre à 0xfffff pour demander à ce que le segment prenne toute la mémoire.

## Le registre flag

Les flags d'un segment est formé comme ceci:

| nom                  | taille |
| -------------------- | ------ |
| accédé               | 1 bit  |
| écriture/lisible     | 1 bit  |
| direction/conformité | 1 bit  |
| executable           | 1 bit  |
| type de descripteur  | 1 bit  |
| niveau de privilège  | 2 bit  |
| segment présent      | 1 bit  |

__accédé__ : Doit être à 0, il est mit à 1 quand le processeur l'utilise.

__écriture/lisible__:
- Si c'est un segment de donnée: si le bit est à 1 alors l'écriture est autorisé avec le segment, si le bit est à 0 alors le segment est seulement lisible.
- Si c'est un segment de code: si le bit est à 1 alors on peut lire le segment sinon le segment ne peut pas être lu.

__direction/conformité__: 
- Pour les descripteurs de données:
    - Le bit défini le sens du segment, si il est mit alors le sens du segment est vers le bas, il doit être à 0 pour le 64 bit.
- Pour les descripteurs de code: 
    - Si le bit est à 1 alors le code peut être éxécuté par un niveau de privilège plus bas ou égal au registre `niveau de privilège`.
    - Si le bit est à 0 alors le code peut seulement être éxecuté par le registre `niveau de privilège`.

__executable__: Définis si le segment est éxécutable ou non, si il est à 0 alors le segment ne peut pas être exécuté (c'est un segment de donné `data`) mais s'il est à 1 alors c'est un segment qui peut être exécuté (c'est un segment de code `code`).

__type de descripteur__: Doit être mit à 1 pour les segment de code/data et il doit être à 0 pour la tss.

__niveau de privilège__: Représente le niveau de privilège du descripteur (de 0 à 3).

__segment présent__: Doit être mit à 1 pour tout descripteur (sauf pour le descripteur null).

## Le registre granularité

Le registre granularité d'un segment est formé comme ceci:

| nom         | taille |
| ----------- | ------ |
| granularité | 1 bit  |
| taille      | 1 bit  |
| mode long   | 1 bit  |
| zéro        | 1 bit  |

__granularité__: Le bit granularité doit être mit quand la limite est fixe, cependant si le bit est à 1 alors la limite est multipliée par 4096.

__taille__: Le bit taille doit être mit à 0 pour le 16bit/64bit, 1 pour le 32bit.

__mode long__: Le bit doit être à 1 pour les descripteur de code en 64bit sinon il reste à 0.

## Types de segment

Il y a différents type de segments:

### Le segment null

L'entrée 0 d'une gdt est une entrée nulle, tout le segment est à 0.

### Le segment code du kernel

La première entrée doit être un segment pour le kernel éxecutable soit un segment de code:

- Dans le type il faut que le bit 'type de descripteur' soit à 1.
- Il faut que le segment ait l'accès en écriture.
- Il faut que le bit executable soit mit.
- Le niveau de privilège doit être à 0.

Cela produit un type pour le mode x86_64:
`0b10011010`

La granularité doit être à `0b10`

### Le segment data du kernel

La seconde entrée doit être un segment de donnée pour le kernel.
- Il faut utiliser la même démarche que le segment de code sauf qu'il faut mettre le bit executable à 0.

Cela produit un type pour le mode x86_64:
`0b10010010`

La granularité doit être à `0`

### Le segment code des utilisateurs

La troisième entrée doit être un segment pour les applications éxecutable depuis l'anneau (niveau de privilège) 3.

- Il faut reproduire la même démarche que pour le segment code du kernel sauf que le niveau de privilège doit être à 3 pour le segment.

Cela produit un type pour le mode x86_64:
`0b11111010`

La granularité doit être à `0b10`.

### Le segment données des utilisateurs

La quatrième entrée doit être un segment pour les données d'applications depuis l'anneau (niveau de privilège) 3.
Il faut reproduire la même démarche que pour le segment data du kernel sauf que le niveau de privilège doit être à 3.

Cela produit un type pour le mode x86_64:
`0b11110010`.

La granularité doit être à `0`.

# Le chargement d'une gdt

Pour charger un registre d'une gdt il faut utiliser l'instruction:

```x86asm
lgdt [registre]
```

Avec le registre contenant l'adresse du registre de la gdt.
Cependant en 64bit il faut charger les registre du segment de code et de donnée. Ici nous allons utiliser l'instruction `retf` qui permet de charger un segment de code:

```x86asm
gdtr_install:
    lgdt [rdi]
    ; met tout les segments avec leurs valeurs ciblants le segment de données
    mov ax, 0x10

    mov ds, ax
    mov es, ax
    mov ss, ax

    mov rax, qword .trampoline ; addresse de retour
    push qword 0x8 ; segment de code
    push rax 

    o64 retf  ; fait un far return

.trampoline:
    pop rbp
    ret
```

## Références

- [wikipedia](https://en.wikipedia.org/wiki/Global_Descriptor_Table)
- [osdev](https://wiki.osdev.org/GDT)
- [documentation intel](https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.html)
