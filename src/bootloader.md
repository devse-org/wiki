# Bootloader

Un `bootloader` est un systeme chargé de démarrer un ou plusieurs systeme d'exploitation.

plusieurs types sont utilisé par les dévellopeurs de systeme d'exploitation:
- MBR/UEFI
- PXE
- GRUB
- Limine

## MBR/UEFI
un bootloader MBR ou UEFI est un bootloader créer en même temps que le systeme d'exploitation par la personne/société qui as conçu le système d'exploitation
avantages:
- permet de maitriser totalement le processus de démarrage
inconvénients:
- plus complexe a dévelloper pour les débutants
- ne permet en général que de démarrer qu'un seul systeme d'exploitation

##PXE
un bootloader PXE est un bootloader par réseau IP
avantages:
- permet de démarrer sans disques dur ou autres supports de stockage
inconvénients:
- on doit uttiliser un serveur pour démarrer
- plus complexe a dévelloper pour les débutants

##GRUB
avantages:
- souvent déja installé sur un ordinateur avec une distribution Linux
inconvénients:
- aucuns

##limine


