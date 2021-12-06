
# Créer un cross compilateur GCC (C/C++)

## Pourquoi faire un cross compilateur ?

Il faut faire un cross compilateur car le compilateur fournis avec votre système est configuré pour une plateforme cible (CPU, système d'exploitation etc).

Par exemple, comparons deux platformes différentes (Ubuntu x64 et Debian GNU/Hurd i386).
La commande`gcc -dumpmachine` nous indique la platforme que cible le compilateur, sur Ubuntu GNU/Linux la commande me retourne `x86_64-linux-gnu` 
tandis que sur Debian GNU/Hurd nous avons `i686-gnu`.

Le resultat obtenu n'est pas surprennant, nous avons deux systèmes d'exploitation différent sur du materiel différent.

Ne pas faire un cross compilateur et utiliser le compilateur fournis avec le système c'est allez au devant de toute une série de problèmes.

## Quel plateforme cible ?

Tout cela va dépendre de l'architecture que vous ciblez (x86, risc-v) et du format de vos binaires (ELF, mach-o, PE).

Par exemple pour un système x86-64 en utilisant le format ELF: `x86_64-elf`
Ou encore `i686-elf` pour x86 (32bit)

Bien sur en attendant d'avoir notre propre toolchain.

## Compiler GCC et les binutils

Maintenant que la théorie à été rapidement esquissée nous allons pouvoir passer à la pratique.

créons un dossier toolchain/local à la racine de notre projet. C'est dans ce dossier que sera notre cross compilateur une fois compilé.

créons donc une variable `$prefix`:

```bash
prefix="<chemin vers votre projet>/toolchain/local"
```

Profitons en pour modifier notre `$PATH`:
```bash
export PATH="$PATH:$prefix/bin"
```

Puis nous allons définir une variable `$target` (qui contiendra notre platforme cible).
Comme dans notre guide nous nous concentrons sur x86-64 notre variable sera définis comme ceci:
```bash
target="x86_64-elf"
```

Nos variables d'environment étant définis nous pouvons passer à l'installation des dépendances.

### Dépendance

Pour pouvoir compiler gcc et binutils sous Debian GNU/Linux il nous faut les paquets suivant:

- build-essential
- bison
- flex
- texinfo
- libgmp3-dev
- libmpc-dev
- libmpfr-dev

Que l'on peut les installer simplement comme ceci:

```bash
sudo apt install build-essential bison flex libgmp3-dev \
                    libmpc-dev libmpfr-dev texinfo
```

Nous allons pouvoir passer à la compilation.

### binutils

Commençons par télécharger et décompresser les sources de binutils.

Ici dans ce tutoriel nous compilerons binutils `2.35`.

```bash
binutils_version="2.35"
wget "https://ftp.gnu.org/gnu/binutils/binutils-$binutils_version.tar.xz"
tar -xf "binutils-$binutils_version.tar.xz"
```

Maintenant que l'archive est décompressé nous allons passer à la compilation.

```bash
cd "binutils-$binutils_version"
mkdir build && cd build
../configure --prefix="$prefix" --target="$target"  \
                --with-sysroot --disable-nls --disable-werror
make all -j $(nproc)
make install -j $(nproc)
```

Comme la compilation risque de prendre un moment, vous pouvez en profiter pour vous faire un café.

### gcc 

Maintenant les binutils sont compilé, nous allons pouvoir passer à gcc.

Ici nous compilerons gcc `10.2.0`.

```bash
gcc_version="10.2.0"
wget http://ftp.gnu.org/gnu/gcc/gcc-$gcc_version/gcc-$gcc_version.tar.xz
tar -xf gcc-$gcc_version.tar.xz
```

Puis on passe à la compilation:

```bash
cd "gcc-$gcc_version"
mkdir build && cd build
../configure --prefix="$prefix" --target="$target" --with-sysroot \
            --disable-nls --enable-languages=c,c++ --with-newlib
make -j all-gcc 
make -j all-target-libgcc
make -j install-gcc 
make -j install-target-libgcc
```

La encore ça va prendre un certain temps, on peut donc s'accorder une deuxième pause café.

Une fois la compilation terminée vous pouvez utilisez votre cross compilateur, dans le cas de ce tutoriel `x86_64-elf-gcc`.

Cependant il faudrait plus tard implémenter une toolchain spécifique pour votre os.
C'est une toolchain modifiée pour votre système d'exploitation.