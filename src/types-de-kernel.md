# Types de noyaux

Les kernel sont classé dans plusieurs parties, certains sont plus complexe que d'autres...

## Les micro-kernel

Les micro-kernel, sont minimalistes, élegants et **résilients** aux crashs. Des systèmes basés sur des micro-kernels sont composés d'une colletion de services executés dans l'user space qui communiquent entre eux. Si un service crash il peut être redemarré sans reboot la machine entière. Les premierès generations avaient l'inconvénient d'être plus lents que les kernel monolithiques. Mais cela n'est plus vrai de nos jours: les kernels de la famille L4 n'ont rien à envier en terme de rapidité à leurs homologues monolithiques.

**Exemples**: Minix, L4, march, fushia

## Les kernel monolithique

Les kernel monolithiques, sont la marnière classique de structurer un kernel. Ils contiennent les drivers, le système de fichier, etc, dans l'espace superviseur. Contrairement aux microkernels ils sont gros et lourds, si il y a un crash dans le kernel ou si un service crash, tout crash et il faut reboot la machine.

**Exemples**: Linux, BSDs

## Les unikernel

**Exemples**: IncludeOS, MirageOS, HaLVM, Runtime.js
