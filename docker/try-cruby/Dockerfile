# Try image: CRuby + GNU R + Galaaz already installed. Drops into gstudio (IRB).
# Distinct from docker/cold-install-cruby (that image proves gem install).
FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/rbotafogo/galaaz" \
      org.opencontainers.image.description="Galaaz 2.1.4 try image (CRuby + GNU R)" \
      org.opencontainers.image.licenses="BSD-2-Clause"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG RUBY_VERSION=3.3.12
ARG GALAAZ_VERSION=2.1.4

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tar \
      build-essential \
      g++ \
      make \
      libssl-dev \
      libreadline-dev \
      zlib1g-dev \
      libyaml-dev \
      libffi-dev \
      r-base \
      r-base-dev \
    && rm -rf /var/lib/apt/lists/*

# R packages before compiling Ruby so a Ruby bump does not rebuild ggplot2.
RUN Rscript -e "install.packages(c('Rcpp','ggplot2','gridExtra'), repos='https://cloud.r-project.org')"

RUN curl -fsSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz" \
    | tar -xz -C /tmp \
    && cd "/tmp/ruby-${RUBY_VERSION}" \
    && ./configure --prefix=/opt/ruby --disable-install-doc --without-baseruby \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf "/tmp/ruby-${RUBY_VERSION}"

ENV PATH="/opt/ruby/bin:${PATH}" \
    GEM_HOME=/opt/galaaz-gems \
    GEM_PATH=/opt/galaaz-gems \
    GALAAZ_RCPP_CACHE_DIR=/tmp/galaaz_rcpp_cache_try

ENV PATH="${GEM_HOME}/bin:${PATH}"

RUN gem sources --add https://rubygems.org/ >/dev/null 2>&1 || true \
    && gem install --source https://rubygems.org galaaz -v "${GALAAZ_VERSION}" \
    && gem_dir="$(ruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path")" \
    && make -C "${gem_dir}/ext/new_bridge" all

WORKDIR /work
CMD ["gstudio"]
