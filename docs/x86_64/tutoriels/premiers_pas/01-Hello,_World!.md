# Votre premier noyau
Dans ce tutoriel, vous allez voir comment vous pouvez créer un noyau basique en mode long
## Compiler un "cross-compiler"
La première étape est de compiler/build un "cross-compiler", Celui utilisé dans ce tutoriel sera `x86_64-elf-gcc`.
<br>
Pour l'installer vous devrez le compiler de la source, plusieurs scripts sont disponibles en ligne pour le compiler.
<br>
Pour les utilisateurs de la distribution GNU/Linux Arch le compileur est dans le AUR (x86_64-elf-gcc)

## Commençons à coder!

Commencez par créer un fichier appelé `kernel.c`, il va être utilisé comme fichier principal dans ce tutoriel.
<br>
Pour débuter commençons à inclure les fichiers appropriés, dans ce cas ce sera `stdint.h` et `stivale.h`(fichier créé plus tard dans ce tutoriel)

# [EN ÉCRITURE]
