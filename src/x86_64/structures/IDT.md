# Interrupt Descriptor Table

La table de description des interruptions est une table qui permet au cpu 
de pouvoir savoir ou aller (jump) quand il y a une interruption

Il y a deux structures utilisés (en 64bit) : 

- La table d'entrée d'interruptions
- L'entrée de la table d'interruptions 

## Table d'entrée

La table d'entrée contient une addresse ou est situé toutes les entrées d'interruptions et une taille.

pour la table d'entrée la structure est comme ceci :
|nom                    |taille     |
|-----------------------|-----------|
|taille                 | 16 bit    |
|addresse des entrées   | 64 bit    |

la taille peut être définie comme ceci : 
```c
IDT_table.size = sizeof(IDT_entry_t) * IDT_entry_count;
```

## entrée d'IDT

l'entrée d'une IDT doit être structuré comme ceci :

|nom                    |taille     |
|-----------------------|-----------|
|offset (0-16)          | 16 bit    |
|segment de code        | 16 bit    |
|numéro d'interruption  | 8 bit     |
|attributs              | 8 bit     |
|offset (16-32)         | 16 bit    |
|offset (32-64)         | 32 bit    |
|zéro                   | 32 bit    |

le `segment de code` serra le segment de code utilisé pendant l'interruption

l'`offset` est l'addresse où le cpu va jump quand il y a une interruption 

### Les attributs 
l'attribut d'une entrée d'une IDT est formée comme ceci : 

|nom                    |bit        |
|-----------------------|-----------|
|type d'interruption    | 0 - 4     |
|zéro                   | 5         |
|niveau de privilège    | 6 - 7     |
|présent                | 8         |

le `niveau de privilège` (aka DPL) est le niveau de privilège requis pour que l'interruption soit appelée

il est utilisé pour éviter à ce que une application utilisatrice puisse appeller une interruption 
qui est reservé au kernel


### Types d'interruptions

les types d'interruptions sont les mêmes que cela soit en 64bit ou en 32bit 

|valeur                 |signification                          |
|-----------------------|---------------------------------------|
|0b0111 (7)             | trappe d'interruption 16bit           |
|0b0110 (6)             | porte d'interruption  16bit           |
|0b1110 (14)            | porte d'interruption  32bit           |
|0b1111 (15)            | trappe d'interruption 32bit           |

la différence entre une `trappe`(aka trap) et une `porte` (aka gate) est que la
gate désactive `IF` et vous devez réactiver les interruptions à la fin de l'isr

la trappe ne désactive pas `IF` donc vous pouvez désactiver / réactiver vous même 
dans l'isr les interrupts

