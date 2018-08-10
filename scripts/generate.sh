#!/bin/bash

echo "FROM buildpack-deps:$(awk -F'_' '{print tolower($2)}' <<< $LINUX_VERSION)"

cat << EOF

# Prepare to install dependencies.
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -yq update
RUN apt-get -yq install --no-install-suggests --no-install-recommends software-properties-common
RUN apt-get -yq install --no-install-suggests --no-install-recommends curl

# Install dependencies to build C++ core.
RUN apt-get -yq --no-install-suggests --no-install-recommends install build-essential  # make.
RUN apt-get -yq --no-install-suggests --no-install-recommends install libopencv-dev valgrind
RUN apt-add-repository -y "ppa:ubuntu-toolchain-r/test"
RUN apt-get -yq update

# Download cmake (stored at ~/cmake/bin/cmake).
ADD https://cmake.org/files/v3.7/cmake-3.7.2-Linux-x86_64.sh /cmake.sh
RUN mkdir /opt/cmake
RUN sh /cmake.sh --prefix=/opt/cmake --skip-license
RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake
RUN cmake --version

RUN curl -s https://cmake.org/files/v3.6/cmake-3.6.2-Linux-x86_64.tar.gz > ~/cmake.tar.gz
RUN mkdir ~/cmake
RUN tar -x -f ~/cmake.tar.gz -C ~/cmake --strip-components=1

# Install R.
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" | tee -a /etc/apt/sources.list > /dev/null
RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
RUN gpg -a --export E084DAB9 | apt-key add -
RUN apt-get -yq update
RUN apt-get -yq --no-install-suggests --no-install-recommends install r-base

# Install dependencies to build R.
RUN apt-get -yq --no-install-suggests --no-install-recommends install libcurl4-gnutls-dev libssl-dev  # For devtools.
RUN apt-get -yq --no-install-suggests --no-install-recommends install libxml2-dev libxslt-dev  # For roxygen.
RUN apt-get -yq --no-install-suggests --no-install-recommends install libgfortran-8-dev liblapack-dev liblapack3 libopenblas-base libopenblas-dev  # For RcppEigen.
RUN R -e 'install.packages(c("Rcpp", "devtools", "testthat", "roxygen2", "DiceKriging", "lmtest", "sandwich", "RcppEigen"), repos="http://cran.us.r-project.org")'

# Install clang.
RUN curl -sSL "http://apt.llvm.org/llvm-snapshot.gpg.key" | apt-key add -
RUN echo "deb http://apt.llvm.org/precise/ llvm-toolchain-precise-3.7 main" | tee -a /etc/apt/sources.list > /dev/null
RUN apt-get -yq update
RUN apt-get -yq --no-install-suggests --no-install-recommends install clang-3.7

# Install g++.
RUN apt-get -yq --no-install-suggests --no-install-recommends install g++-4.9

EOF