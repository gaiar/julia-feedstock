#!/bin/sh

export C_INCLUDE_PATH=${PREFIX}/include
export LD_LIBRARY_PATH=${PREFIX}/lib
export LIBRARY_PATH=${PREFIX}/lib
export CMAKE_PREFIX_PATH=${PREFIX}

# Hack to suppress building docs
cat >doc/Makefile <<EOF
html :	
	mkdir -p _build/html
EOF

# Julia sets this to unix makefiles later on in its build process
export CMAKE_GENERATOR="make"

NO_GIT=1 make -C base version_git.jl.phony

export EXTRA_MAKEFLAGS=""
if [ "$(uname)" == "Darwin" ]; then
	export EXTRA_MAKEFLAGS="USE_SYSTEM_LIBUNWIND=1"
elif [ "$(uname)" == "Linux" ]; then
	# On linux the released version of libunwind has issues building julia
	# See: https://github.com/JuliaLang/julia/issues/23615
	export EXTRA_MAKEFLAGS="USE_SYSTEM_LIBUNWIND=0"
fi

if [ "$(uname -m)" == "armv7l" ]; then
	export JULIA_CPU="cortex-a7"
	export JULIA_ARCH="armv7-a"
elif [ "$(uname -m)" == "armv6l" ]; then
	export JULIA_CPU="arm1176jzf-s"
	export JULIA_ARCH="arm-linux-gnueabi"
fi

make -j${CPU_COUNT} prefix=${PREFIX} MARCH=${JULIA_ARCH} sysconfigdir=${PREFIX}/etc NO_GIT=1 \
	LIBBLAS=-lopenblas LIBBLASNAME=libopenblas LIBLAPACK=-lopenblas LIBLAPACKNAME=libopenblas \
	JULIA_CPU_TARGET=${JULIA_CPU} \
	USE_LLVM_SHLIB=0 \
	USE_SYSTEM_ARPACK=1 \
	USE_SYSTEM_BLAS=1 \
	USE_SYSTEM_CURL=1 \
	USE_SYSTEM_FFTW=1 \
	USE_SYSTEM_GMP=1 \
	USE_SYSTEM_LAPACK=1 \
	USE_SYSTEM_LIBGIT2=1 \
	USE_SYSTEM_LIBSSH2=1 \
	USE_SYSTEM_LLVM=0 \
	USE_SYSTEM_MPFR=1 \
	USE_SYSTEM_OPENLIBM=1 \
	USE_SYSTEM_OPENSPECFUN=1 \
	USE_SYSTEM_PATCHELF=1 \
	USE_SYSTEM_PCRE=1 \
	USE_SYSTEM_SUITESPARSE=1 \
	${EXTRA_MAKEFLAGS} \
	TAGGED_RELEASE_BANNER="conda-forge-julia release" \
	install

# Configure juliarc to use conda environment
cat "${RECIPE_DIR}/juliarc.jl" >>"${PREFIX}/etc/julia/juliarc.jl"
