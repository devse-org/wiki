#!/bin/bash
set -e
# il est recommandé d'utiliser : https://wiki.osdev.org/Cross-Compiler_Successful_Builds



bin_utils_version="2.34"
binutils_file="binutils-$bin_utils_version.tar.xz"

gcc_version="10.1.0"
gcc_file="gcc-$gcc_version.tar.xz"
export PREFIX="$PWD/cross_compiler"
export TARGET="x86_64-pc-elf"
export PATH="$PREFIX/bin:$PATH"
mkdir -p ./cross_compiler/build/gcc ./cross_compiler/build/binutils
mkdir -p ./cross_compiler/src


cd ./cross_compiler/src

echo "[bin_utils]"

# BIN UTILS

wget -c "https://ftp.gnu.org/gnu/binutils/$binutils_file"
tar xf "$binutils_file"

export binutils_src="$PWD/binutils-$bin_utils_version"

# GCC

wget -c "ftp://ftp.gnu.org/gnu/gcc/gcc-$gcc_version/$gcc_file"
tar xf "$gcc_file"

export gcc_src="$PWD/gcc-$gcc_version"

cd ..
cd build

echo "build de bin_utils"
cd binutils
"$binutils_src/configure" --target="$TARGET" 	\
        --prefix="$PREFIX" 	\
        --with-sysroot 		\
        --disable-nls 		\
        --disable-werror


make -j$(nproc)
make install -j$(nproc)

cd ..


echo "build de gcc"
cd gcc
"$gcc_src/configure" --target="$TARGET" \
        --prefix="$PREFIX" 		\
        --disable-nls			\
        --enable-languages=c,c++	\
        --with-newlib

make all-gcc -j$(nproc)
make all-target-libgcc -j$(nproc)
make install-gcc -j$(nproc)
make install-target-libgcc -j$(nproc)

echo "la toolchain est prête :^)"
