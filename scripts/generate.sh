#!/bin/bash

echo "FROM buildpack-deps:$(awk -F'_' '{print tolower($2)}' <<< $LINUX_VERSION)"
echo "RUN apt-get update"
# install lsb-release, etc., for testing linux distro
echo "RUN apt-get update && apt-get -y install lsb-release unzip"

cat << EOF

# Prepare to install dependencies.
ENV DEBIAN_FRONTEND noninteractive
CMD mkdir ~/logs
CMD apt-get -yq update &>> ~/logs/apt-get-update.log
CMD apt-get -yq install --no-install-suggests --no-install-recommends software-properties-common
CMD apt-get -yq install --no-install-suggests --no-install-recommends curl

# Install dependencies to build C++ core.
CMD apt-get -yq --no-install-suggests --no-install-recommends install build-essential  # make.
CMD apt-get -yq --no-install-suggests --no-install-recommends install libopencv-dev valgrind
CMD apt-add-repository -y "ppa:ubuntu-toolchain-r/test"
CMD apt-get -yq update &>> ~/logs/apt-get-update.log

# Download cmake (stored at ~/cmake/bin/cmake).
ADD https://cmake.org/files/v3.7/cmake-3.7.2-Linux-x86_64.sh /cmake.sh
RUN mkdir /opt/cmake
RUN sh /cmake.sh --prefix=/opt/cmake --skip-license
RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake
RUN cmake --version

CMD curl -s https://cmake.org/files/v3.6/cmake-3.6.2-Linux-x86_64.tar.gz > ~/cmake.tar.gz
CMD mkdir ~/cmake
CMD tar -x -f ~/cmake.tar.gz -C ~/cmake --strip-components=1

# Install R.
CMD echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" | tee -a /etc/apt/sources.list > /dev/null
CMD gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
CMD gpg -a --export E084DAB9 | apt-key add -
CMD apt-get -yq update &>> ~/logs/apt-get-update.log
CMD apt-get -yq --no-install-suggests --no-install-recommends install r-base

# Install dependencies to build R.
CMD apt-get -yq --no-install-suggests --no-install-recommends install libcurl4-gnutls-dev libssl-dev  # For devtools.
CMD apt-get -yq --no-install-suggests --no-install-recommends install libxml2-dev libxslt-dev  # For roxygen.
CMD apt-get -yq --no-install-suggests --no-install-recommends install libgfortran-8-dev liblapack-dev liblapack3 libopenblas-base libopenblas-dev  # For RcppEigen.
CMD R -e 'install.packages(c("Rcpp", "devtools", "testthat", "roxygen2", "DiceKriging", "lmtest", "sandwich", "RcppEigen"), repos="http://cran.us.r-project.org")'

# Install clang.
CMD curl -sSL "http://apt.llvm.org/llvm-snapshot.gpg.key" | apt-key add -
CMD echo "deb http://apt.llvm.org/precise/ llvm-toolchain-precise-3.7 main" | tee -a /etc/apt/sources.list > /dev/null
CMD apt-get -yq update &>> ~/logs/apt-get-update.log
CMD apt-get -yq --no-install-suggests --no-install-recommends install clang-3.7

# Install g++.
CMD apt-get -yq --no-install-suggests --no-install-recommends install g++-4.9

EOF