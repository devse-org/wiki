# Global Descriptor Table

La table de descripteur globale à été introduite avec le processeur 16bit d'intel (le 80286) pour gérer la mémoire sous forme de segments.

la segmentation ne devrais plus être utilisé, elle a été remplacé par le paging. Le paging est toujours obligatoire pour passer du 32 au 64 bit avec l'architecture x86.

Cependant la `GDT` est aussi utilisée pour contenir la tss. La structure est différente entre le 32 et 64 bit.

La table globale de descripteur est principalement formée de 2 structures:

- la gdtr (le registre de segments)
- le segment

# le registre de segments

le registre de segments en mode long (x86_64) doit être construit comme ceci:

|nom                    |taille     |
|-----------------------|-----------|
|taille                 | 16 bit    |
|adresse de la table    | 64 bit    |

__taille__: le registre taille doit contenir la taille de la table de segment, soit le nombre de segment multiplié par la taille du segment, cependant en 64bit la taille du segment de la TSS est doublé, il faut alors compter le double.

__adresse de la table__: l'adresse de la table doit pointer directement vers la table de segments

# les segments 

un segment en x86_64 est formé comme ceci:

|nom                    |taille     |
|-----------------------|-----------|
| limite basse (0-15)   | 16 bit    |
| base basse (0-15)     | 16 bit    |
| base milieu (16-23)   | 8 bit     |
| flag                  | 8 bit     |
| limite haute (16-19)  | 4 bit     |
| granularité           | 4 bit     |
| base haute (24-31)    | 8 bit     |

## les registres base

le registre base est le début du segment, en mode long il faut le mettre à 0

## les registres limite 

le registre limite est une adresse 20bit, il représente la fin du segment

il est multiplié par 4096 si le bit *granularité* est à 1

en mode long il faut le mettre à 0xfffff pour demander à ce que le segment prenne toute la mémoire

## le registre flag

les flags d'un segment est formé comme ceci:

|nom                    |taille     |
|-----------------------|-----------|
| accédé                | 1 bit     |
| écriture              | 1 bit     |
| direction/conformité  | 1 bit     |
| executable            | 1 bit     |
| type de descripteur   | 1 bit     |
| niveau de privilège   | 2 bit     |
| segment présent       | 1 bit     |

__accédé__ : doit être à 0, il est mit à 1 quand le processeur l'utilise

__écriture__: si le bit est à 1 alors l'écriture est autorisé avec le segment, si le bit est à 0 alors le segment est seulement lisible 

__direction/conformité__: 
- pour les descripteurs de données:
    - le bit défini le sens du segment, si il est mit alors le sens du segment est vers le bas, il doit être à 0 pour le 64 bit
- pour les descripteurs de code: 
    - si le bit est à 1 alors le code peut être éxécuté par un niveau de privilège plus bas ou égal au registre `niveau de privilège`
    - si le bit est à 0 alors le code peut seulement être éxecuté par le registre `niveau de privilège` 

__executable__: définis si le segment est éxécutable ou non, si il est à 0 alors le segment ne peut pas être exécuté (c'est un segment de donné `data`) mais si il est à 1 alors c'est un segment qui peut être exécuté (c'est un segment de code `code`)

__type de descripteur__: doit être mit à 1 pour les segment de code/data et il doit être à 0 pour la tss

__niveau de privilège__: représente le niveau de privilège du descripteur (de 0 à 3) 

__segment présent__: doit être mit à 1 pour tout descripteur (sauf pour le descripteur null)

## types de segment
il y a différents type de segments:

__le segment null__: l'entrée 0 d'une gdt est une entrée nulle, tout le segment est à 0

__le segment code du kernel__: la première entrée doit être un segment pour le kernel

sources:

- [wikipedia](https://en.wikipedia.org/wiki/Global_Descriptor_Table)
- [osdev](https://wiki.osdev.org/GDT)
- [documentation intel](https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.html)