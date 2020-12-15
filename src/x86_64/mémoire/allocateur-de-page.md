# Allocateur de page [WIP]

Un allocateur de page est un allocateur basique, nécéssaire pour faire le paging

Note : tout au long de ce document, nous utilisons le terme `page` comme zone de mémoire qui à pour taille 4096 byte 
Cette taille peut changer mais pour l'instant il est mieux d'utiliser la même taille de page avec le paging et l'allocateur de page


Il doit pouvoir : 

    - Alouer une/plusieurs page libre
    - Libérer une page allouée
    - Gérer qu'elle zone de la mémoire est utilisable ou non

ou en code C : 
```c
void* alloc_page(uint64_t page_count);

void free_page(void* page_addr, uint64_t page_count);

void init_pmm(memory_map_t memory_map);
```

## L'allocateur de page avec une bitmap

Dans ce document, nous expliquerons comment mettre en place un allocateur de page avec une bitmap.

La bitmap est une table de uint64/32/16 ou uint8_t avec chaque bit qui représente une page libre (quand le bit est à 0) ou utilisée (quand le bit est à 1).

vous pouvez facilement convertir une addresse en index/bit de la table par exemple : 

```c
static inline uint64_t get_bitmap_array_index(uint64_t page_addr){
    return page_addr/8; // ici c'est 8 car nous utilisons une bitmap avec des uint8_t qui font 8bit
}

static inline uint64_t get_bitmap_bit_index(uint64_t page_addr){
    return page_addr%8;
}
```

la bitmap a l'avantage d'être petite par exemple pour une mémoire de 4Go on a : 

`((2^32 / 4096) / 8)` = 131 072 byte soit 
une bitmap de 128 kb 

il faut aussi savoir que la bitmap à l'avantage d'être très rapide, on peut facilement rendre libre/allouer une page


## Changer l'état d'une page dans la bitmap 

pour cette partie vous devez placer une variable temporairement nulle... Cette variable est la bitmap qui serra initialisé plus tard, mais nous devons tout d'abord savoir comment changer l'état d'une page

ici la variable est : 
```c
uint8_t* bitmap = NULL;
```

Avant d'allouer/libérer des pages, il faut les changers d'état, donc mettre un bit précis de la bitmap à 0 ou à 1

il faut juste 2 fonction qui permettent de soit mettre un bit de la bitmap à 0 soit de le mettre à 1 par rapport à une page
```c
static inline void bitmap_set_bit(uint64_t page_addr)
{
    uint64_t bit = get_bitmap_bit_index(page_addr);
    uint64_t byte = get_bitmap_array_index(page_addr);

    bitmap[byte] |= (1 << bit);
}

static inline void bitmap_clear_bit(uint64_t page_addr)
{
    uint64_t bit = get_bitmap_bit_index(page_addr);
    uint64_t byte = get_bitmap_array_index(page_addr);

    bitmap[byte] &= ~(1 << bit);
}
```

## Initialiser l'allocateur de page

L'allocateur de page doit être initialisé le plus tôt possible, vous devez avoir au moins la carte de la mémoire (qu'elle zone est libre et qu'elle zone ne l'est pas)

Vous devez trouver une zone libre et placer votre bitmap par rapport à cette addresse.


Après avoir trouver ou placer la bitmap vous devez calculer la taille de la bitmap, générallement vous pouvez juste prendre la dernière entre de la carte de la mémoire et juste calculer le dernier bit comme ceci : 

```c 
uint64_t memory_end = memory_map[memory_map_size].end;
uint64_t bitmap_size = memory_end / (PAGE_SIZE*8);
```

il faut aussi savoir que vous devez mettre la zone où est placée la bitmap comme utilisée pour éviter à ce que le kernel alloue de la mémoire qui pointe vers la bitmap 

ensuite pour chaque entrée de la carte de la mémoire vous