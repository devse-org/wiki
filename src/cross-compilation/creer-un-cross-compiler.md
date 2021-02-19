
# Créer un cross compiler (gcc)

## Pourquoi créer un cross compiler ? 

Il faut créer un `cross compiler` car un compilateur (gcc, clang, tcc...) généralement est configuré pour un système cible. 

Par exemple si vous êtes sur linux, vous utiliser un compilateur configuré pour linux. 

Cependant celui qui tourne par défaut sur votre machine peut être configuré pour un système d'exploitation en particulier et non pour le votre, cela peut mener, plus tard, à des problèmes. 

Il faut alors utiliser un cross compiler pour votre kernel et non pour linux. 

## Quel plateforme cible ? 

Il faut déjà savoir quel plateforme cible utiliser, cela dépendra de l'architecture de votre kernel. 

Si il est 64bit il faut utiliser: 
`x86_64-pc`

mais si il est en 32bit il faut utiliser: 
`i686-pc`

## Les dépendances

Pour que vous puissiez compiler gcc et binutils (ld, objdump...) il faut que vous ayez ceci: (sur debian)

- build-essential
- bison
- flex
- texinfo
- libgmp3-dev
- libmpc-dev
- libmpfr-dev

soit: 
```bash

$ sudo apt-get install make build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo wget gcc binutils

```

## Le téléchargement du code source 

pour le téléchargement du code source vous pouvez utiliser wget et tar pour la décompression 

> il faut noter que le téléchargement peut prendre beaucoup de temps pour les personnes qui n'ont pas de bonne connection.

### binutils 
pour binutils vous pouvez juste utiliser le lien: 
```bash
https://ftp.gnu.org/gnu/binutils/binutils-$binutilsversion.tar.xz
```
avec `$binutilsversion` qui peut être égale à 2.33.1 

### gcc 

pour gcc il faut cependant utiliser le lien: 
```bash
ftp://ftp.gnu.org/gnu/gcc/gcc-$gccversion/gcc-$gccversion.tar.xz

```

on peut avoir `$gccversion` qui peut être égale à 10.1.0

## Le build

> il faut noter que le build peut prendre lui aussi beaucoup de temps pour les personnes qui ont des ordinateurs un peut lents.

pour la construction du cross compilateur il faut utiliser un chemin différent du code source, par exemple si vous avez: 
```
toolchain/gcc
toolchain/binutils
```
vous pouvez rajouter les chemins: 
```
toolchain/binutils-build
toolchain/gcc-build 
```

vous devez aussi mettre en place un `prefix` cela permet au compilateur d'être sur que tout les fichier de build du cross compilateur finissent dans le même dossier. vous pouvez dire que `prefix` est directement le dossier toolchain de ce cas. 

```
toolchain/local
```

### binutils 

pour binutils dans le chemins binutils-build vous pouvez faire 

```bash
../binutils/configure --prefix="$prefix" --target="$target" --with-sysroot --disable-nls --disable-werror 
```

vous pouvez ensuite faire 

```bash
make all -j
make install -j
```


### gcc 

pour gcc dans le chemins gcc-build vous pouvez faire 

```bash
../gcc/configure --prefix="$prefix" --target="$target" --with-sysroot --disable-nls --enable-languages=c,c++ --with-newlib
```

vous pouvez ensuite faire 

```bash
make -j all-gcc 
make -j all-target-libgcc
make -j install-gcc 
make -j install-target-libgcc
```
