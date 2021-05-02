
# Créer un cross compiler GCC (C/C++)

## Pourquoi créer un cross compiler ?

Il faut créer un `cross compiler` car un compilateur (GCC, clang, TCC...) généralement est configuré pour un système cible.

Par exemple si vous êtes sur GNU/Linux, vous utilisez un compilateur configuré pour GNU/Linux.

Cependant, celui qui tourne par défaut sur votre machine peut être configuré pour un système d'exploitation en particulier et non pour le vôtre, cela peut mener, plus tard, à d'importants problèmes.

Il faut alors utiliser un cross compiler pour votre kernel et non pour GNU/Linux.

## Quel plateforme cible ?

Il faut déjà savoir quel plateforme cible utiliser, cela dépendra de l'architecture de votre kernel:

pour du x86 64bit il faut utiliser:
`x86_64-pc`

pour du x86 32bit il faut utiliser:
`i686-pc`

## Les dépendances

Pour que vous puissiez compiler GCC et binutils (ld, objdump...), il faut que vous ayez ces paquets: (sur debian)

- build-essential
- bison
- flex
- texinfo
- libgmp3-dev
- libmpc-dev
- libmpfr-dev

soit:

```bash
sudo apt-get install make build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo wget gcc binutils
```

## Le téléchargement du code source

pour le téléchargement du code source vous pouvez utiliser wget pour le téléchargement et tar pour la décompression.

> le téléchargement peut prendre beaucoup de temps en fonction de la connection internet.

### Téléchargement binutils

pour binutils vous pouvez juste utiliser le lien:

```bash
https://ftp.gnu.org/gnu/binutils/binutils-$binutilsversion.tar.xz
```

avec `$binutilsversion` qui peut être égale à 2.33.1

### Téléchargement GCC

Pour GCC il faut cependant utiliser le lien:

```bash
ftp://ftp.gnu.org/gnu/gcc/gcc-$gccversion/gcc-$gccversion.tar.xz

```

On peut avoir `$gccversion` qui peut être égale à `10.1.0`.

## Le build

> le build peut prendre beaucoup de temps en fonction de la puissance de l'ordinateur

Pour la construction du cross compilateur il faut utiliser un chemin différent du code source, par exemple, si vous avez:

- toolchain/gcc
- toolchain/binutils

Vous pouvez rajouter les chemins:

- toolchain/binutils-build
- toolchain/gcc-build

Vous devez aussi mettre en place un `prefix` cela permet au compilateur d'être sûr que tout les fichiers de build du cross compilateur finissent dans le même dossier.

Vous pouvez dire que `prefix` est directement le dossier toolchain de ce cas.

- toolchain/local

### Build binutils

Pour binutils dans le chemin binutils-build vous pouvez faire :

```bash
../binutils/configure --prefix="$prefix" --target="$target" --with-sysroot --disable-nls --disable-werror
```

Vous pouvez ensuite faire :

```bash
make all -j
make install -j
```

### Build GCC

Pour GCC dans le chemin gcc-build vous pouvez faire

```bash
../gcc/configure --prefix="$prefix" --target="$target" --with-sysroot --disable-nls --enable-languages=c,c++ --with-newlib
```

Vous pouvez ensuite faire :

```bash
make -j all-gcc
make -j all-target-libgcc
make -j install-gcc
make -j install-target-libgcc
```

Vous pouvez maintenant utiliser votre toolchain !

Cependant il faudrait plus tard implémenter une toolchain spécifique pour votre os.
C'est une toolchain modifiée pour votre système d'exploitation.
