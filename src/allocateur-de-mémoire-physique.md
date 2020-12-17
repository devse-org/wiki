# Allocateur de mémoire physique

Un `allocateur de mémoire physique` est un algorithme d'allocation 'basique' qui est générallement utilisé par le kernel pour allouer et libérer des pages.

> Note : tout au long de ce document, nous utilisons le terme `page` comme zone de mémoire qui à pour taille 4096 byte 
> Cette taille peut changer mais pour l'instant il est mieux d'utiliser la même taille de page entre le paging et l'allocateur de mémoire physique

Il doit pouvoir : 

- Alouer une/plusieurs page libre
- Libérer une page allouée
- Gérer qu'elle zone de la mémoire est utilisable ou non

ou en code C : 
```c
void* alloc_page(uint64_t page_count);

void free_page(void* page_addr, uint64_t page_count);

void init_pmm(memory_map_t memory_map); // PMM = Physical Memory Manager
```

## L'Allocateur de mémoire physique avec une bitmap

Dans ce document, nous expliquerons comment mettre en place un allocateur de mémoire physique avec une bitmap.

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

## Initialiser l'Allocateur de mémoire physique

L'allocateur de mémoire physique doit être initialisé le plus tôt possible, vous devez avoir au moins la carte de la mémoire (qu'elle zone est libre et qu'elle zone ne l'est pas) générallement fournie par le bootloader

cependant vous devez calculer avant la future taille de la bitmap, générallement la taille de la mémoire est la fin de la dernière entrée de la carte de la mémoire.

```c 
uint64_t memory_end = memory_map[memory_map_size].end;
uint64_t bitmap_size = memory_end / (PAGE_SIZE*8);
```

après avoir obtenu la taille de la future bitmap vous devez trouver une place pour la positionner.

Vous devez trouver une entrée valide de la carte de la mémoire et placer la bitmap au début de cette entrée.

```c
for(int i = 0; i < mem_map.size && bitmap==NULL; i++){
    mem_map_entry_t entry = mem_map.entry[i]; 
    if(entry.is_free && entry.size >= bitmap_size){
        bitmap = entry->start;
    }
}
```

ensuite pour chaque entrée de la carte de la mémoire vous mettez la région de la bitmap en utilisé ou libre.
on peut mettre par défaut toutes la bitmap comme utilisée et puis la mettre libre seulement quand c'est nécéssaire

```c
uint64_t free_memory = 0;

memset(bitmap, 0xff, bitmap_size); // mettre toutes les pages comme utilisées

for(int i = 0; i < mem_map.size; i++){
    mem_map_entry_t entry = mem_map.entry[i]; 
    // en espérant ici que entry.start et entry.end sont déjà aligné par rapport à une page
    if(entry.is_free){
        for(uint64_t j = entry.start; j < entry.end; j+=PAGE_SIZE){

            bitmap_clear_bit(j/PAGE_SIZE);
            free_memory += PAGE_SIZE;
        }
    }
}

```

cependant la zone ou est placé la bitmap est marquée comme libre. Donc une tâche peut écraser cette zone et donc causer des problèmes... vous devez donc marquer la zone de la bitmap comme utilisée : 

```c
uint64_t bitmap_start = (uint64_t)bitmap;
uint64_t bitmap_end = bitmap_start + bitmap_size;
for(uint64_t i = bitmap_start; i <= bitmap_end; i+= PAGE_SIZE){
    bitmap_set_bit(i/PAGE_SIZE);
}
```

## L'allocation, la recherche et la libération de pages

Après avoir sa bitmap initializée et que vous pouvez mettre une page comme libre ou utilisée vous pouvez commencer à implementer des fonction d'allocation et de libération de page cependant vous devez commencer par vérifier si une page est utilisée ou libérée (ou si le bit d'une page est à 0 où à 1) :
```c
static inline bool bitmap_is_bit_set(uint64_t page_addr){
    
    uint64_t bit = get_bitmap_bit_index(page_addr);
    uint64_t byte = get_bitmap_array_index(page_addr);
    return bitmap[byte] & (1 << bit);
}
```
### l'allocation de page

Une fonction d'allocation de page doit avoir comme argument le nombre de pages allouées et doit retourner des pages qui serront mises comme utilisé

pour commencer vous devez mettre en place une fonction qui cherche et trouve de nouvelles pages 

```c
// note ici c'est la fonction brut, il y a plusieurs optimizations possiblent qui serront abordés plus tard 
uint64_t find_free_pages(uint64_t count){
    uint64_t free_count = 0; // le nombre de pages libres de suite
    for(int i = 0; i < (mem_size/PAGE_SIZE); i++){
        if(!bitmap_is_bit_set(i)){
            free_count++; // on augmente le nombre de page trouvées d'affilée de 1
            if(free_count == count){
                return i;
            }
        }else{
            free_count = 0; 
        }
    }
    return -1; // il n'y a pas de page libres
}
```

`find_free_page` donne donc `count` pages libre

après avoir trouvé les pages vous devez les mettre comme utilisées : 
```c
void* alloc_page(uint64_t count){
    uint64_t page = find_free_pages(count); // ici pas de gestion d'erreur mais vous pouvez vérifier si il n'y a plus de pages disponibles

    for(int i = page; i < count+page; i++){
        bitmap_set_bit(i);
    }
    return (void*)(page*PAGE_SIZE);
}
```
et vous avez une Allocateur de mémoire physique ! :tada:

### la libération de page

après avoir alloués des pages vous devez pouvoir les rendres libres.

Le fonctionnement est plus simple que l'allocation, vous devez juste mettres les bits des pages à 0 

**Note** : ici il n'y a pas de vérification d'erreur car c'est un exemple

```c
void free_page(void* addr, uint64_t page_count){
    uint64_t target= ((uint64_t)addr) / PAGE_SIZE;
    for(int i = target; i<= target+page_count; i++){
        bitmap_clear_bit(i);
    }
}
```

cette fonction met juste les bit de la bitmap à 0 

### les optimizations 

l'allocation de pages comme ici est très lent, à chaque fois on revient à 0 pour chercher une page et ça peut ralentir énormément le système. 
On peut donc mettre en place plusieurs optimizations : 

on peut déjà créer une variable last_free_page qui donne la dernière page libre à la place de toujours revenir à la page 0 pour en chercher une nouvelle. Cela améliore largement les performances : 

```c
uint64_t last_free_page = 0;
uint64_t find_free_pages(uint64_t count){
    uint64_t free_count = 0;
    for(int i = last_free_page; i < (mem_size/PAGE_SIZE); i++){
        if(!bitmap_is_bit_set(i)){
            free_count++;  trouvées d'affilée de 1
            if(free_count == count){
                last_free_page = i; // la dernière page libre
                return i;
            }
        }else{
            free_count = 0; 
        }
    }

    return -1; // il n'y a pas de page libres
}
```

cependant si on ne trouve pas de page libre à partir de la dernière page libre, il peut en avoir avant. Il faut donc réésayer en mettant le nombre de page libre à zéro

```c
// à la fin de la fonction find_free_pages()
if(last_free_page != 0){
    last_free_page = 0;
    return find_free_pages(count); // juste réésayer mais avec la dernière page libre en 0x0
}
return -1;
```

vous pouvez aussi mettre que la dernière page libre est automatiquement remise à la dernière page libérée  dans free_page: 
```c
// free_page()
last_free_page = page_addr;
```

---
une autre optimization serait dans find_free_page, on peut utiliser la capacité du processeur à faire des vérification avec des nombres 64/32 16 et 8 bit pour que cela soit plus rapide. En sachant que dans une bitmap, quand il y a une entrée de la table totallement pleine, tout les bit sont à 1 donc ils sont donc à `0b11111111` = `0xff`

on peut donc rajouter
(sans le code pour last_free_page pour que cela soit plus compréhensible)

```c
uint64_t find_free_pages(uint64_t count){
    int i = 0;
    
    for(int i = 0; i < (mem_size/PAGE_SIZE); i++){
        // vous pouvez aussi utiliser des uint64_t ou n'importe quel autres types
        while(bitmap[i/8] == 0xff && i < (mem_size/PAGE_SIZE)-8){
            free_count = 0; // en sachant que les pages sont utilisées, alors on reset le nombre de page libres de suite
            i += 8- (i % 8); // rajouter mettre i au prochain index de la bitmap
        }    
        
        if(!bitmap_is_bit_set(i)){
            free_count++;  trouvées d'affilée de 1
            if(free_count == count){ 
                return i;
            }
        }else{
            free_count = 0; 
        }
    }
    return -1;
}
```

---
maintenant vous pouvez utiliser votre Allocateur de mémoire physique principalement pour le paging ou pour un allocateur plus 'intelligent' (malloc/free/realloc) !