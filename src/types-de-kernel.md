# Types de noyaux

Les kernels sont classés en plusieurs catégories, certaines sont plus complexes que d'autres...

## Les micro-kernels

Les micro-kernel, sont minimalistes, élégants et **résilients** aux crashs. Les systèmes basés sur un microkernel sont composés d'une collection de services exécutés dans l'userspace qui communiquent entre eux. Si un service crash il peut être redémarré sans reboot la machine entière. Les premières générations avaient l'inconvénient d'être plus lentes que les kernels monolithiques. Mais cela n'est plus vrai de nos jours: les kernels de la famille L4 n'ont rien à envier en terme de rapidité à leurs homologues monolithiques.

**Exemples**: Minix, L4, march, fushia

## Les kernels monolithiques

La méthode monolithique est la manière classique de structurer un kernel. Un kernel monolithique contient les drivers, le système de fichier, etc, dans l'espace superviseur. Contrairement aux microkernels ils sont gros et lourds, si il y a un crash dans le kernel ou si un service crash, tout crash et il faut reboot la machine.

**Exemples**: Linux, BSDs

## Les unikernels

**Exemples**: IncludeOS, MirageOS, HaLVM, Runtime.js
