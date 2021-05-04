# 01 - Hello world !

<img src="/x86_64/assets/tutoriel-hello-world-result.png">

> résultat à la fin de ce tutoriel

Dans cette partie nous allons faire un "hello world !" en 64bit. 

Pour ce projet nous utiliserons donc: 
- [un cross compilateur](/cross-compilation/creer-un-cross-compiler.md)
- [Limine](https://github.com/limine-bootloader/limine) comme bootloader
- [Echfs](https://github.com/echfs/echfs) comme système de fichier

Pour commencer vous devez mettre un place un [cross compilateur](/cross-compilation/creer-un-cross-compiler.md) dans votre projet.

Vous utiliserez echfs comme système de fichier car c'est assez simple de l'utiliser quand on débute, car normalement sans echfs on doit créer un disque, le partitionner, le monter, installer un système de fichier, mettre nos fichier... Avec echfs c'est plus simple (grâce à l'outil `echfs-utils`). 

Vous devez donc cloner limine dans la source de votre projet (ou en le rajoutant en sous module git), ici nous prenons en compte le fait que vous utilisez directement la [branche qui contient les binaires](https://github.com/limine-bootloader/limine/tree/latest-binary).

# Le Fichier Makefile

> Note: vous pouvez utiliser d'autres système de build, il faut juste suivre les même commandes et arguments pour gcc/ld.

## Compilation

Pour commencer nous devons obtenir tout les fichier '.c' avec find et obtenir le fichier objet '.o' équivalent à ce fichier c.

> Ici nous prenons en compte que vous utiliser le dossier "src" pour mettre le code de votre kernel.

```makefile
SRCS := $(wildcard ./src/**.c)
OBJS := $(SRCS:.c=.o)
```

Puis ensuite vous pouvez compiler les fichiers C mais avant nous devons changer certains flags du compilateurs:

- `-ffreestanding`: Active l'environnement freestanding, cela signifie que le compilateur désactive les librairies standards du C (faites pour GNU/linux). Il signifie aussi que les programmes ne commencent pas forcément à `main`. 
- `-O1`: Vous pouvez utiliser -O2 ou même -O3 même si rarement le compilateur peut retirer des bouts de code qui ne devraient pas être retiré.
- `-m64`: Active le 64bit.
- `-mno-red-zone`: Désactive la red-zone (en mode 64bit).
- `-mno-sse`: Désactive l'utilisation de l'sse.
- `-mno-avx`: Désactive l'utilisation de l'avx.
- `-fno-stack-protector`: Désactive la protection de la stack.
- `-fno-pic`: produit un code qui n'est pas '*indépendant de la position*'.
- `-no-pie`: Ne produit pas un executable avec une position indépendante.
- `-masm=intel`: Utilise l'asm intel pour la génération de code.

```makefile
CFLAGS :=                  \
	-Isrc                   \
	-std=c11                \
	-ffreestanding          \
	-fno-stack-protector    \
	-fno-pic                \
    -no-pie                 \
    -O1                     \
    -m64                    \
    -g                      \
    -masm=intel             \
    -mno-red-zone           \
    -mno-sse                \
    -mno-avx                
```

Maintenant vous pouvez rajouter une target a votre makefile pour compiler vos fichier C en objet:

> Ici nous prenons en comptes que vous avez mit CC soit avec le path de votre cross compilateur.

```makefile
.SUFFIXE: .c
.o: $(SRCS)
	$(CC) $(CFLAGS) -c $< -o $@
```

## Linking

Après avoir compilé tout les fichier C en fichier objet, nous devons les liers pour créer le fichier du kernel.

Nous utiliserons `ld` (soit celui fournit par le binutils de votre cross compilateur soit celui fournit par votre distribution)

Avant il nous faut un fichier de linking, qui définit la position de certaines parties du code. Nous le mettrons dans le chemins `src/link.ld`.

Il faut commencer par définir le point d'entrée, où commence le code... Ici la fonction: `kernel_start` pour commencer, donc: 
```ld
ENTRY(kernel_start)
```

Ensuite il faut définir la position des sections du code (que cela soit les données (data/rodata/bss) ou le code (text)), soit la position `0xffffffff80100000` car c'est un kernel higher half, donc il est placé dans la moitié haute de la mémoire: `0xffffffff80000000` mais ici nous rajoutons un décalage de 1M (`0x100000`) (pour éviter de toucher l'adresse 0 en physique). 

Nous devons aussi positioner le header pour le bootloader (ici dans la section `stivale2hdr`), il permet de donner des informations importantes quand le bootloader lit le kernel. Le bootloader demande à ce que cette section soit la première dans le code.

Pour finir nous avons: 
```ld
ENTRY(kernel_start)

SECTIONS
{
    kernel_phys_offset = 0xffffffff80100000;
    . = kernel_phys_offset;
    
    .stivale2hdr ALIGN(4K):
    {
        KEEP(*(.stivale2hdr))
    }
    
    .text ALIGN(4K):
    {
        *(.text*)
    }
    
    .rodata ALIGN(4K):
    {
        *(.rodata*)
    }
    
    .data  ALIGN(4K):
    {
        *(.data*)
    }
    
    .bss  ALIGN(4K) :
    {
        *(COMMON)
        *(.bss*)
    }
}
```

Comme pour la compilation des fichiers C, nous devons passer des arguments spécifiques:

- `-z max-page-size=0x1000`: Signifie que la taille max d'une page ne peut pas dépasser `0x1000` (4096).
- `-nostdlib` Demande à ne pas utiliser la librairie standard.
- `-T{CHEMIN_DU_FICHIER_DE_LINKING}`: Demande à utiliser le fichier de linking.
Donc ici:

```makefile
LD_FLAGS :=                 \
	-nostdlib               \
	-Tsrc/link.ld           \
	-z max-page-size=0x1000

```

Maintenant nous pouvons lier les fichiers objets en un `kernel.elf`: (en utilisant une nouvelle target dans le fichier Makefile):

```makefile
kernel.elf: $(OBJS)
    $(LD) $(LD_FLAGS) $(OBJS) -o $@
```

## Création Du Fichier De Configuration Du Bootloader
Avant de continuer, nous devons créer un fichier `limine.cfg`, c'est un fichier lu par le bootloader, il paramètre certaines options et pointe où se trouve le kernel dans le disque:

```s
:mykernel
PROTOCOL=stivale2
KERNEL_PATH=boot:///kernel.elf
```

Ici nous voulons définir l'entrée `mykernel` qui a le protocol `stivale2` et qui a comme fichier elf pour le kernel: `/kernel.elf` dans la partition de `boot`.

Ensuite, vous pouvez mettre en place la création du disque:

## Création Du Disque

Pour commencer il faut créer un path pour le disk, (ici `disk.hdd`).

```makefile
KERNEL_DISK := disk.hdd
```
Ensuite dans la target de création du disque du makefile:

Nous créons un fichier disk.hdd vide de taille 8M (avec `dd`).

```makefile
dd if=/dev/zero bs=8M count=0 seek=64 of=$(KERNEL_DISK)
```

Nous formatons le disque pour utiliser un système de partition `MBR` avec 1 seule partition (qui prend tout le disque).
```makefile
parted -s $(KERNEL_DISK) mklabel msdos
parted -s $(KERNEL_DISK) mkpart primary 1 100%
```

Nous utilisons echfs-utils pour formater la partition en echfs et pour rajouter le fichier kernel, le fichier config pour limine, et un fichier système pour limine (`limine.sys`).
```makefile
echfs-utils -m -p0 $(KERNEL_DISK) quick-format 4096 # taille de block de 4096
echfs-utils -m -p0 $(KERNEL_DISK) import kernel.elf kernel.elf
echfs-utils -m -p0 $(KERNEL_DISK) import limine.cfg limine.cfg
echfs-utils -m -p0 $(KERNEL_DISK) import ./limine/limine.sys limine.sys
```

Puis nous installons limine sur la partition echfs:
```makefile
./limine/limine-install-linux-x86_64 $(KERNEL_DISK)
```

Ce qui donne comme résultat:
```makefile
$(KERNEL_DISK): kernel.elf 
	rm -f $(KERNEL_DISK)
	dd if=/dev/zero bs=8M count=0 seek=64 of=$(KERNEL_DISK)
	parted -s $(KERNEL_DISK) mklabel msdos
	parted -s $(KERNEL_DISK) mkpart primary 1 100%
	echfs-utils -g -p0 $(KERNEL_DISK) quick-format 4096
	echfs-utils -g -p0 $(KERNEL_DISK) import kernel.elf kernel.elf
	echfs-utils -g -p0 $(KERNEL_DISK) import limine.cfg limine.cfg
	echfs-utils -m -p0 $(KERNEL_DISK) import ./limine/limine.sys limine.sys
	./limine/limine-install-linux-x86_64 $(KERNEL_DISK)
```

## L'Execution

Ici une fois avoir créer le disque nous allons faire une cible: `run`, elle servira plus tard quand vous pourrez enfin tester votre kernel ;) .
Elle est assez simple: nous lançons qemu-system-x86_64, avec une mémoire de `512M`, on active `kvm` (une accélération pour l'émulation), on utilise le disque `disk.hdd`, et des options de debug, comme:
- `-serial stdio`: Redirige la sortie de qemu dans `stdio` .
- `-d cpu_reset`: Signale dans la console quand le cpu se réinitialise après une erreur.
- `-device pvpanic`: signale quand il y a des évenements de panic.
- `-s`: Permet de debug avec gdb.


```makefile
run: $(KERNEL_DISK)
    qemu-system-x86_64 -m 512M -s -device pvpanic -serial stdio -enable-kvm -d cpu_reset -hda ./disk.hdd
```

# Le Code

Maintenant après avoir tout configuré avec le makefile, nous pouvons commencer à coder ! 

Vous commencerez par créer un fichier kernel.c dans le dossier src (le nom du fichier n'est pas obligé d'être kernel.c).

Mais avant nous devons rajouter le header du bootloader, qui permet de donner des informations/configurer le bootloader quand il charge le kernel, ici nous utilisons le protocol stivale 2, nous recommandons d'utiliser [le code/header fournis par stivale2](https://github.com/stivale/stivale/blob/master/stivale2.h) qui facilite la création du header.

Nous créons une variable dans le `kernel.c` du type stivale2_header, nous demandons au linker de la positioner dans la section "`.stivale2hdr`" et de forcer le fait qu'elle soit utilisée (pour éviter à ce que le compilateur vire l'entrée automatiquement).

```c
__attribute__((section(".stivale2hdr"), used))
struct stivale2_header header = {/* entrées */};
```

Puis nous replissons toutes les entrées.
Il faut avant créer une variable pour définir la [stack](https://fr.wikipedia.org/wiki/Pile_(informatique)) du kernel. Nous utilisons une stack de taille 32768 (32K) soit:

```c
#define STACK_SIZE 32768
char kernel_stack[STACK_SIZE];
```

Et: 
```c
struct stivale2_header header = {.stack = (uintptr_t)kernel_stack + (STACK_SIZE) }// la stack tend vers le bas, donc nous voulons donner le dessus de cette stack
```

Le header doit spécifier le point d'entrée du kernel par la variable `entry_point`, il faut le mettre à 0 pour demander au bootloader d'utiliser le point d'entrée spécifié par le fichier elf.

La spécification de stivale2 demande **pour l'instant** à mettre `flags` à 0 car il n'y a aucun flag implémenté.

```c
__attribute__((section(".stivale2hdr"), used))
static struct stivale2_header stivale_hdr = 
{
    .stack = (uintptr_t)kernel_stack + STACK_SIZE,
    .entry_point = 0,
    .flags = 0,
};
```

Maintenant il faut mettre en place des tags pour le bootloader, les tags sont une liste liée, càd que chaque entrée doit indiqué ou est la prochaine entrée:

<img src="/x86_64/assets/tutoriel-hello-world-stivale2-linked-list.svg" style="margin:5rem;padding:1rem;width:64rem;background-color:white;">

Il y a plusieurs valeurs valide pour le `identifier` qui identifie l'entrée, et nous pouvons avoir plusieurs tags mais ici nous allons en utiliser qu'un seul, celui pour définir le framebuffer.

Il faut créer une nouvelle variable statique qui contient le premier (*et le seul pour l'instant* )tag de la liste qui aura comme type `stivale2_header_tag_framebuffer`:
```c
static struct stivale2_header_tag_framebuffer framebuffer_header_tag = 
{
    .tag = 
    {
    },
}; 
```
Ici la variable `.tag.identifier` doit être à `STIVALE2_HEADER_TAG_FRAMEBUFFER_ID` pour signifier que ce tag est un qui donne des informations au bootloader à propos du framebuffer (taille en largeur/hauter, ...)

La variable `.tag.next` est à `0` pour l'instant car nous utilison qu'une seule entrée dans la liste.

Ce qui donne:
```c
static struct stivale2_header_tag_framebuffer framebuffer_header_tag = 
{
    .tag = 
    {
        .identifier = STIVALE2_HEADER_TAG_FRAMEBUFFER_ID,
        .next = 0 // fin de la liste
    },
}; 
```

Maintenant nous configurons le [framebuffer](/x86_64/périphériques/framebuffer.md), nous voulons juste le mettre pour le moment en pixel et non texte, nous essayerons de remplir l'écran en bleu.

Nous devons définir la longueur et largeur du framebuffer (ici nous utiliserons une résolution de: `1440`x`900`) et 32 bit par pixel (donc ̀`framebuffer_bpp=32`).

```c
static struct stivale2_header_tag_framebuffer framebuffer_header_tag = 
{
    .tag = 
    {
        .identifier = STIVALE2_HEADER_TAG_FRAMEBUFFER_ID,
        .next = 0 // fin de la liste
    },
    .framebuffer_width  = 1440,
    .framebuffer_height = 900,
    .framebuffer_bpp    = 32
}; 
```

Ensuite vous mettez la variable `tags` du `stivale2_header` à l'adresse du tag du framebuffer soit:

```c
__attribute__((section(".stivale2hdr"), used))
static struct stivale2_header stivale_hdr = 
{
    .stack = (uintptr_t)kernel_stack + STACK_SIZE,
    .entry_point = 0,
    .flags = 0,
    .tags = (uintptr_t)&framebuffer_header_tag
};
```

Pour finir vous devriez avoir ceci:

```c
#define STACK_SIZE 32768
char kernel_stack[STACK_SIZE];

static struct stivale2_header_tag_framebuffer framebuffer_header_tag = 
{
    .tag = {
        .identifier = STIVALE2_HEADER_TAG_FRAMEBUFFER_ID,
        .next = 0 // fin de la liste
    },
    .framebuffer_width  = 1440,
    .framebuffer_height = 900,
    .framebuffer_bpp    = 32
}; 

__attribute__((section(".stivale2hdr"), used))
static struct stivale2_header stivale_hdr = {
    .stack = (uintptr_t)kernel_stack + STACK_SIZE,
    .entry_point = 0,
    .flags = 0,
    .tags = (uintptr_t)&framebuffer_header_tag
};
```

## L'Entrée

Après la mise en place du header pour le bootloader nous devons programmer le point d'entrée, `kernel_start`, c'est une fonction qui ne retourne rien mais qui a un `struct stivale2_struct*` comme argument, qui donne sont des informations passé par le bootloader.

```c
void kernel_start(struct stivale2_struct *bootloader_data)
{
    while(1); // nous ne voulons pas sortir de kernel_start 
}
```

Maintenant il est conseillé de compiler et de tester le kernel, avant de continuer. Faites un `make run` il faut qu'il n'y ait pas d'erreur (que cela soit du bootloader ou de qemu).

## Lire Le Bootloader_data

Il est important avant de continuer de mettre en place quelques fonctions utilitaires qui permettent de lire le `bootloader_data` car il doit être lu comme une liste lié (comme le header stivale2). Par exemple si on veut obtenir l'entrée qui contient des informations à propos du framebuffer, nous devons regarder toutes les entrées et trouver celle qui a un identifiant pareil à celle du framebuffer.

```c
void *stivale2_find_tag(struct stivale2_struct *bootloader_data, uint64_t tag_id)
 {
    struct stivale2_tag *current = (void *)bootloader_data->tags;
    while(current != NULL)
    {    
        if (current->identifier == tag_id) // est ce que cette entrée est bien celle que l'on cherche ?
        {
            return current;
        }

        current = (void *)current->next; // avance d'une entrée dans la liste
    }
    return NULL; // aucune entrée trouvé
}
```

Ce qui permettra plus tard d'obtenir le tag contenant des informations à propos du framebuffer comme ceci:

```c
stivale2_find_tag(bootloader_data, STIVALE2_STRUCT_TAG_FRAMEBUFFER_ID);
```

# Le Framebuffer

Nous allons remplir l'écran en bleu pour essayer de debug, le framebuffer est structuré comme ceci:

```c
struct framebuffer_pixel
{
    uint8_t blue;
    uint8_t green;
    uint8_t red;
    uint8_t __unused;
}__attribute__((packed));
```

> voir:  [framebuffer](/x86_64/périphériques/framebuffer.md)  pour plus d'information

Nous rajoutons ensuite dans kernel_start du code pour remplir le framebuffer en bleu.

Pour commencer il faut obtenir le tag du framebuffer, il est passé dans le tag `STIVALE2_STRUCT_TAG_FRAMEBUFFER_ID` du `bootloader_data` 

Il faut utiliser `stivale2_find_tag`:

```c
struct stivale2_struct_tag_framebuffer *framebuffer_tag;
framebuffer_tag = stivale2_find_tag(bootloader_data, STIVALE2_STRUCT_TAG_FRAMEBUFFER_ID);
```

Maintenant le tag contient la taille du framebuffer, et son adresse.

Pour utiliser l'adresse il faut la convertir en un pointeur `framebuffer_pixel`:

```c
struct framebuffer_pixel* framebuffer = framebuffer_tag->framebuffer_addr;
```

Nous avons une table qui contient chaque pixel de `framebuffer_tag->framebuffer_width` de longueur et de `framebuffer_tag->framebuffer_height` de hauteur, donc nous faisons une boucle:
```c
for(size_t x = 0; x < framebuffer_tag->framebuffer_width; x++)
{
    for(size_t y = 0; y < framebuffer_tag->framebuffer_height; y++)
    {
        size_t raw_position = x + y*framebuffer_tag->framebuffer_width; // convertit les valeurs x et y en position brute dans la table 
        framebuffer[raw_position].blue = 255; // met la couleur à bleu
    }
}
```

Si vous le voulez vous pouvez faire quelque chose de plus compliqué:
```c
for(size_t x = 0; x < framebuffer_tag->framebuffer_width; x++)
{
    for(size_t y = 0; y < framebuffer_tag->framebuffer_height; y++)
    {
        size_t raw_position = x + y*framebuffer_tag->framebuffer_width; 

        framebuffer[raw_position].blue =  x ^ y;
        framebuffer[raw_position].red =  (y*2) ^ (x*2);
        framebuffer[raw_position].green =  (y*4) ^ (x*4);
    }
}
```

Qui donneras ce motif si tout fonctionne:
<img src="/x86_64/assets/tutoriel-hello-world-result.png">

# Conclusion
Cette partie du tutoriel est terminée ! vous avez maintenant un kernel qui boot, cependant dans le prochain tutoriel nous implémenterons un driver COM, qui donnera la possibilité d'écrire des informations dans la console, ce qui est très pratique pour debugger.