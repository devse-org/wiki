# Types de noyaux

Les kernel sont classés en plusieurs catégories, certaines sont plus complexe que d'autres...

## Les micro-kernel

Les micro-kernel, sont minimalistes, elegants et **résiliants** aux crashs. Un systeme basé sur un micro-kernel est composé d'une colletions de services executés dans l'user space qui communiquent entre eux. Si un service crash, il peut être redémarré sans reboot la machine toute entière. Les premières generations avaient l'inconvénient d'être plus lent que les kernel monolithiques, mais cela n'est plus vrai de nos jours les kernel de la famille L4 n'ont rien à envier en terme de rapidité à leurs homologues monolithiques.

**Exemples**: Minix, L4, march, fushia

## Les kernel monolithique

Les kernel monolithiques sont la marnière classique de structurer un kernel, ils contiennent les driver, système de fichier etc. dans l'espace superviseur. Contrairement aux microkernel ils sont gros et lourds, si il y a un crash dans le kernel ou dans un service, tout crash et il faut reboot la machine.

**Exemples**: Linux, BSDs

## Les unikernel

**Exemples**: IncludeOS, MirageOS, HaLVM, Runtime.js
