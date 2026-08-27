# Throwaway Ubuntu "stranger machine" for Galaaz 2.0 cold install on CRuby.
# Does not copy the git repo. The .gem is supplied at run time.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG RUBY_VERSION=3.3.12

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
      pandoc \
      pkg-config \
      libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

# Install CRuby from the official tarball (no asdf / no baseruby).
RUN curl -fsSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz" \
    | tar -xz -C /tmp \
    && cd "/tmp/ruby-${RUBY_VERSION}" \
    && ./configure --prefix=/opt/ruby --disable-install-doc --without-baseruby \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf "/tmp/ruby-${RUBY_VERSION}"

ENV PATH="/opt/ruby/bin:${PATH}"

RUN Rscript -e "install.packages(c('Rcpp','dplyr','knitr','rmarkdown','ggplot2','gridExtra'), repos='https://cloud.r-project.org')"

RUN apt-get update && apt-get install -y --no-install-recommends \
      libcurl4-openssl-dev \
      libssl-dev \
    && rm -rf /var/lib/apt/lists/*

ENV NOT_CRAN=true \
    LIBARROW_BINARY=true
RUN Rscript -e "\
  options(HTTPUserAgent = sprintf('R/%s R (%s)', getRversion(), paste(getRversion(), R.version[['platform']], R.version[['arch']], R.version[['os']]))); \
  repos <- c(PPM = 'https://packagemanager.posit.co/cran/latest/bin/linux/noble-x86_64/4.3', CRAN = 'https://cloud.r-project.org'); \
  install.packages('arrow', repos = repos); \
  stopifnot(requireNamespace('arrow', quietly = TRUE)); \
  cat('arrow', as.character(packageVersion('arrow')), '\n')"

WORKDIR /work
COPY smoke.rb /work/smoke.rb
COPY install-and-smoke.sh /usr/local/bin/install-and-smoke.sh
RUN chmod +x /usr/local/bin/install-and-smoke.sh

ENV GEM_HOME=/opt/smoke-gems \
    GEM_PATH=/opt/smoke-gems \
    GALAAZ_RCPP_CACHE_DIR=/tmp/galaaz_rcpp_cache_smoke
ENV PATH="${GEM_HOME}/bin:${PATH}"

CMD ["install-and-smoke.sh"]
