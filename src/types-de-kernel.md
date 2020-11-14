# Types de noyaux

Les kernel sont classé dans plusieurs parties, certains sont plus complexe que d'autres...

## Les micro-kernel

Les micro-kernel, sont minimalist, elegant et **résiliant** aux crashs. Un system baser sur un micro-kernel sont composer d'une colletions de services executer dans l'user space qui communique entre eux. Si un service crash il peuvent être redémarrer sans reboot la machine entier. Les premiers generation avait l'inconvénient d'être plus lent que les kernel monolithique. Mais cela n'est plus vrai de nos jours les kernel de la famille L4 n'ont rien a envier en term de rapidité à leur homologue monolithique.

**Exemples**: Minix, L4, march, fushia

## Les kernel monolithique

Les kernel monolithique, est la marnière classic de structurer un kernel, ils contiennent les driver, système de fichier etc dans l'espace superviseur. Contrairement aux microkernels ils sont gros et lourd, si il y a un crash dans le kernel ou un service crash tout crash et ils faut reboot la machine.

**Exemples**: Linux, BSDs

## Les unikernel

**Exemples**: IncludeOS, MirageOS, HaLVM, Runtime.js
