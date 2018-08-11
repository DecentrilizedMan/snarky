# Creates an environment for building both snarky and things that use snarky.
FROM debian:buster-slim

# Sometimes you need a specific version.
ARG OCAML_VERSION=4.07.0

# Install the libsnark dependencies and a bootstrap OCaml environment.
RUN apt-get -q update && \
    apt-get -q -y install \
        build-essential \
        cmake \
        git \
        libboost-dev \
        libboost-program-options-dev \
        libffi-dev \
        libgmp-dev \
        libgmp3-dev \
        libprocps-dev \
        libssl-dev \
        ocaml \
        opam \
        nano \
        python-markdown && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# We want to drop root! First, add a user to be and create a homedir.
RUN useradd snarky -m

# Create a volume we can work in. For initial build, we'll copy the local
# context. To update the snarky library itself later, bind mount your updated
# source over this and run the build again.
RUN mkdir -p /source && chown -R snarky:snarky /source
VOLUME ["/source"]

# Be the new user before initializing OPAM.
USER snarky
WORKDIR /home/snarky/

# Move to a newer version of OCaml and install dune/jbuilder.
RUN opam init -y && \
    opam switch $OCAML_VERSION && \
    opam install dune

# Actually copy the source files here, for caching reasons.
ADD . /source

USER snarky

# Pin and install the dependencies.
RUN cd /source && \
    eval `opam config env` && \
    opam pin add -y interval_union .
RUN cd /source && \
    eval `opam config env` && \
    opam pin add -y bitstring_lib .

RUN cd /source && \
    eval `opam config env` && \
    opam pin add -y snary .

# Do the build!
RUN eval `opam config env` && \
    opam install -y snarky

# Use a slight hack to always have the current OCaml environment.
CMD ["/bin/bash", "--init-file", "/home/snarky/.opam/opam-init/init.sh"]

