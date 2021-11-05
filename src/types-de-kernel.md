# Types de noyaux

Les kernels sont classés en plusieurs catégories, certaines sont plus complexes que d'autres...

## Les micro-kernels

Les micro-kernel, sont minimalistes, élégants et **résilients** aux crashs. Les systèmes basés sur un microkernel sont composés d'une collection de services exécutés dans l'userspace qui communiquent entre eux. Si un service crash il peut être redémarré sans reboot la machine entière. Les premières générations avaient l'inconvénient d'être plus lentes que les kernels monolithiques. Mais cela n'est plus vrai de nos jours: les kernels de la famille L4 n'ont rien à envier en terme de rapidité à leurs homologues monolithiques.

**Exemples**: Minix, L4, march, fushia

## Les exo-kernels

Les exo-kernels, sont une forme plus poussée de micro-kernels, en effet, les exo-kernels ont pour but de placer le noyau dans l'espace utilisateur, essayant de supprimer toutes abstraction entre le kernel et la machine. Générallement le lien entre la machine et l'application et faite à travers une librairie lié dès le démarrage de l'application (par exemple LibOSes). Les applications peuvent donc gérer elles mêmes certaines parties bas niveau et donc avoir de meilleure performance. Cependant le développement d'exo-kernel est très dur.

**Exemples**: Xen, Glaze

## Les kernels monolithiques

La méthode monolithique est la manière classique de structurer un kernel. Un kernel monolithique contient les drivers, le système de fichier, etc, dans l'espace superviseur. Contrairement aux microkernels ils sont gros et lourds, si il y a un crash dans le kernel ou si un service crash, tout crash et il faut reboot la machine.
Les kernels monolithiques peuvent être modulaire (comme Linux), cependant les modules sont directements intégrés au noyaux et non à l'espace utilisateur comme le ferrait un micro kernel.

**Exemples**: Linux, BSDs

## Les unikernels

Les unikernels sont spéciaux car ils n'ont pas comme but d'être utilisés sur une machine de travail, mais plutôt sur un serveur. Les unikernels sont souvent utilisés à des fins de virtualisation, comme Docker.

**Exemples**: IncludeOS, MirageOS, HaLVM, Runtime.js

## Références 

- [The Exokernel Operating System Architecture](https://u.cs.biu.ac.il/~wisemay/2os/microkernels/exokernel.pdf)
