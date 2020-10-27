# Symmetric Multi Processing

## Introduction

Qu'est ce que le smp ? 

Le smp veut dire symmetric multi processing

On utilise ce terme pour dire multi processeur. Un kernel qui supporte le smp peut avoir d'énorme boost de performance. En sachant que __générallement__ les processeur ont 2 thread par cpu, pour un processeur à 8 coeur on a 16 thread exploitable. 

Le smp est différent de NUMA, les processeur numa sont des processeur où certains coeur n'ont pas accès à toute la mémoire. 

Dans ce tutoriel pour implémenter le smp nous prenons en compte que vous avez déjà implémenté dans votre kernel : 

- [IDT](/x86_64/structures/IDT.md)
- [GDT](/x86_64/structures/GDT.md)
- [MADT](/x86_64/périphériques/MADT.md)
- [LAPIC](/x86_64/périphériques/LAPIC.md)
- [APIC](/x86_64/périphériques/APIC.md)
- paging
- votre kernel soit higher half
- votre kernel soit 64bit
- un système de timer pour attendre 

il faut aussi savoir qu'il faudrat implémenter les interruption [APIC](/x86_64/périphériques/APIC.md) pour les autres cpu, ce qui n'est pas abordé dans ce tutoriel (pour l'instant)

## Obtenir Le Numéro Du CPU Actuel

obtenir le numero du cpu actuel est très important pour plus tard.

pour obtenir l'identifiant/numéro du cpu actuel on doit utiliser l'[APIC](/x86_64/périphériques/APIC.md)

on doit lire dans l'apic au registre 20
puis on doit shifter les bit à 24 

```cpp
// LAPIC_REGISTER = 20
uint32_t get_current_processor_id()
{
    return apic::read(LAPIC_REGISTER) >> 24;
}
```


## Obtenir Les Entrees Local APIC

voir : [LAPIC](/x86_64/périphériques/LAPIC.md)

pour commencer le smp il faut obtenir les entrées lapic de la table madt

chaque cpu a une entrée LAPIC.
Le nombre de cpu est donc le nombre de LAPIC dans la MADT.

l'entrée LAPIC à 2 entrée importante 

__ACPI_ID__ : utilisé pour l'acpi

et 

__APIC_ID__ : utilisé pour l'apic, pendant l'initialisation

__générallement ACPI_ID et APIC_ID sont égaux__


il faut prendre en compte que le cpu principal (celui qui est booté au démarrage) est aussi dans la liste. 
Il faut alors séparer cette entré en comparant si le numéro du cpu actuel est égal au numéro cpu de l'entrée local apic

```cpp
if(get_current_processor_id() == lapic_entry.apic_id){
    // alors c'est le cpu principal
}else{
    // un cpu que l'on peut utiliser !
}
```

## Pre-Initialisation

avant d'initialiser les cpu, il faut préparer le terrain. 

Il faut préparer ou vous aller placer l'idt/table_de_page/gdt/code d'initialisation/... de votre cpu 

nous allons tout placer comme ceci : 

|entrée|addresse|
|----|-----|
|code du trampoline| 0x1000| 
|stack | 0x570 |
|gdt | 0x580|
|idt | 0x590|
|page table | 0x600 |
| address de jump | 0x610 |

il faut savoir qu'il faudrat plus tard changer la fdt et la table de page, tout ceci est temporaire et devra être remplacé, la stack, la gdt, et la table de page.

#### GDT + IDT
pour stocker la gdt, et l'idt c'est simple 
on peut juste utiliser les instruction 64bit 

sgdt

sidt

ces instruction permettent de stocker la gdt et l'idt dans un addresse précise.

alors

```intel
sgdt [0x580] ; stockage de la gdt
sidt [0x590] ; stockage de l'idt
```
#### Stack

pour la stack on doit stocker une __addresse__ valide en 0x570

```cpp
POKE(570) = stack_address + stack_size;
```

#### Code Du Trampoline

pour le code du trampoline il faut du code assembly délimité par 

__trampoline_start et __trampoline_end



il faudrat copier le code du trampline de 0x1000 à la taille du trampoline.

donc 

```cpp
// en sachant que TRAMPOLINE_START == 0x1000
uint64_t trampoline_len = (uint64_t)&trampoline_end - (uint64_t)&trampoline_start;
    
memcpy((void *)TRAMPOLINE_START, &trampoline_start, trampoline_len);
```
et dans le code assembly : 

```asm
trampoline_start:

    ; code du trampoline

trampoline_end:
```

#### Addresse de jump

L'addresse de jump est la fonction que le cpu vas appeller après son initialisation

#### Table de page pour le futur cpu

la table de page peut être une copie de la table de page du cpu actuel 

mais si c'est une copie il faut alors après l'initialisation du cpu essayer de donner une copie et non garder la table actuel.

après avoir fait tout ceci on peut passer à l'initialisation du cpu 

## Chargement du cpu

avant il faut demander à l'apic de charger le cpu 

il faut faire écrire au 2 registre de commande d'interruption (aussi appelé ICR)

il faut écrire au ICR1  (aka registre 0x300)
0b10100000000 (0x500)


cela veut dire d'envoyer l'interruption d'initialisation au cpu dans ICR2

il faut écrire au ICR2 l'id du processeur shifter de 24

on a donc 

```cpp
write(icr2, (apic_id << 24));
write(icr1, 0x500);
```

__ensuite il faut attendre 10 ms__ pour que le cpu s'initialise

on doit ensuite envoyer à l'apic l'addresse du trampoline pour demander au cpu d'aller en 0x1000

il faut envoyer comme la première étape le apic_id
(apic_id << 24)
mais il faut envoyer à l'icr1
le bit 11 et 10 pour demander aux cpu de charger la page envoyé du trampoline donc  (0x600)


```cpp

write(icr2, (apic_id << 24));
write(icr1, 0x600 | ((uint32_t)trampoline_addr / 4096));
```
maintenant vous pouvez commencer à coder le code du trampoline ! 


## Le Code Du Trampoline 

note: pour débugger vous pouvez utiliser ce code 

```asm
mov al, 'a'
mov dx, 0x3F8
out dx, al
```
le code output le charactère a dans le port com0
c'est utile temporairement pour debugger, c'est la solution la plus courte est simple. Bien sûr le code est temporaire


pour le trampoline il faut savoir que le cpu est initialisé en 16bit, il faut donc le passer comme ceci 

16bit => 32bit => 64bit 


on doit donc faire comme ceci

```asm
[bits 16]
trampoline_start:

trampoline_16:
    ;...

[bits 32]
trampoline_32:
    ;...

[bits 64]
trampoline_64:
    ;...

trampoline_end:
```

#### Le Code 16-Bits

pour passer de 16bit à 32bit il faut initialiser une gdt et mettre le bit 0 du cr0 à 1 pour activer le protected mode

```asm
    cli ; désactiver les interrupt
    mov ax, 0x0 ; mettre tout à 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
```

__pour le chargement de la gdt__

il faut que avant le trampoline_end il y ait une structure de gdt pour le 16bit

il faut alors : 
```asm
align 16
gdt_16:
    dw gdt_16_end - gdt_16_start - 1
    dd gdt_16_start - trampoline_start + TRAMPOLINE_BASE

align 16
gdt_16_start:
    ; null selector 0x0
    dq 0
    ; cs selector 8
    dq 0x00CF9A000000FFFF
    ; ds selector 16
    dq 0x00CF92000000FFFF
gdt_16_end:
```

et dans le code on peut faire

```asm
    lgdt [gdt_16 - trampoline_start + TRAMPOLINE_BASE]
```

il faut ensuite faire

```asm
    mov eax, cr0
    or al, 0x1
    mov cr0, eax
```

et pour finir on peut jump dans le code 32bit

```
    jmp 0x8:(trampoline32 - trampoline_start + TRAMPOLINE_BASE)
```
le jmp 0x8:...

permet de dire de loader le segment de code de la gdt


#### Le Code 32 Bits

il faut commencer par charger la table de page dans le cr3

```asm
mov eax, dword [0x600]
mov cr3, eax
```
et ensuite activer le paging, et le PAE du cr4

en mettant les bit 5 et 7 du registre cr4

```asm
mov eax, cr4
or eax, 1 << 5
or eax, 1 << 7
mov cr4, eax
```

il faut ensuite activer le long mode en écrivant le bit 8 du MSR de l'EFER
(L'extended Feature Enable Register)

```asm
    mov ecx, 0xc0000080 ; registre efer
    rdmsr

    or eax,1 << 8 
    wrmsr
```

il faut, ensuite activer le paging dans le registre cr0 en activant le bit 31

```
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
```

pour finir on doit charger une gdt 64bit 

Il faut donc avoir une structure gdt avant le trampoline end
```asm

align 16
gdt_64:
    dw gdt_64_end - gdt_64_start - 1
    dd gdt_64_start - trampoline_start + TRAMPOLINE_BASE

align 16
gdt_64_start:
    ; null selector 0x0
    dq 0
    ; cs selector 8
    dq 0x00AF98000000FFFF
    ; ds selector 16
    dq 0x00CF92000000FFFF
gdt_64_end:
```
et donc charget la gdt 
```asm

lgdt [gdt_64 - trampoline_start + TRAMPOLINE_BASE]
    
```

et pour passer au 64bit on doit jump comme ceci 
```
    jmp 8:(trampoline64 - trampoline_start + TRAMPOLINE_BASE)
```
ceci met le code segment à 8 


#### Le Code 64 Bits

en 64 bit il faut setup les registres ds/ss/es/ par rapport à votre gdt 

```
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov ax, 0x0
    mov fs, ax
    mov gs, ax
```

il faut ensuite charger la gdt/ et l'idt
par rapport au addresse de stockage utilisé 
```
lgdt [0x580]
lidt [0x590]
```

on doit aussi charger la stack

```
mov rsp, [0x570]
mov rbp, 0x0
```
on doit ensuite passer du code copié du trempoline au code physique 
donc on doit faire

```
    jmp virtual_code

virtual_code:
```

dans le virtual code on doit activer certains bit de cr4 et cr0
__si vous voulez le sse, vous devez l'activer ici__

il faut donc activer le bit 1 et désactiver le 2 du registre cr0 pour le monitoring du multi processor et l'émulation 

```
    mov rax, cr0
    btr eax, 2
    bts eax, 1
    mov cr0, rax
```

il faut pour terminer l'initialisation du smp faire

```
    mov rax, [0x610]
    jmp rax
```


maintenant vous avez un cpu d'initialisé ! 

## Dernière Pensée

mais il reste encore beaucoup de chose à faire !
un système de lock, mettre à jour le multitasking, initialiser les cpu avec une gdt/idt/... unique etc...

## Ressources

- [manuel intel](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
- [osdev](https://wiki.osdev.org/Main_Page)
