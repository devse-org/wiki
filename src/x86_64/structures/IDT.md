# Interrupt Descriptor Table

La table de description des interruptions est une table qui permet au cpu 
de pouvoir savoir ou aller (jump) quand il y a une interruption.

Il y a deux structures utilisées (en 64bit) : 

- La table d'entrée d'interruptions
- L'entrée de la table d'interruptions 

## Table d'entrée

La table d'entrée contient une adresse qui situe une table d'entrée d'IDT et la taille de la table (en mémoire).

pour la table d'entrée la structure est comme ceci :

|nom                    |taille     |
|-----------------------|-----------|
|taille                 | 16 bit    |
|addresse de la table   | 64 bit    |

la table d'entrée peut être définie comme ceci:
```c
IDT_entry_count = 64; 
IDT_Entry_t ent[IDT_entry_count];
IDT_table.addr = (uint64_t)ent;
IDT_table.size = sizeof(IDT_Entry_t) * IDT_entry_count;
```

## entrée d'IDT

l'entrée d'une IDT doit être structurée comme ceci :

|nom                        |taille     |
|---------------------------|-----------|
|offset (0-16)              | 16 bit    |
|segment de code            | 16 bit    |
|numéro d'interruption      | 8 bit     |
|attributs                  | 8 bit     |
|offset (16-32)             | 16 bit    |
|bits spécifiques au 64bit  | //        |
|offset (32-64)             | 32 bit    |
|zéro                       | 32 bit    |

le `segment de code` étant le segment de code utilisé pendant l'interruption.

l'`offset` est l'addresse où le CPU va jump si il y a une interruption. 

### Les attributs 
l'attribut d'une entrée d'une IDT est formée comme ceci : 

|nom                    |bit        |
|-----------------------|-----------|
|type d'interruption    | 0 - 4     |
|zéro                   | 5         |
|niveau de privilège    | 6 - 7     |
|présent                | 8         |

le `niveau de privilège` (aka DPL) est le niveau de privilège requis pour que l'interruption soit appelée.

il est utilisé pour éviter à ce que une application utilisatrice puisse appeller une interruption qui est réservée au kernel


### Types d'interruptions

les types d'interruption sont les mêmes que cela soit en 64bit ou en 32bit. 

|valeur                 |signification                          |
|-----------------------|---------------------------------------|
|0b0111 (7)             | trappe d'interruption 16bit           |
|0b0110 (6)             | porte d'interruption  16bit           |
|0b1110 (14)            | porte d'interruption  32bit           |
|0b1111 (15)            | trappe d'interruption 32bit           |

La différence entre une `trappe`(aka trap) et une `porte` (aka gate) est que la gate désactive `IF`, ce qui veut dire que vous devrez réactiver les interruptions à la fin de l'ISR.

la trappe ne désactive pas `IF` donc vous pouvez désactiver / réactiver vous même dans l'isr les interrupts.

