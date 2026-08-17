# Throwaway Ubuntu "stranger machine" for Galaaz 2.0 cold install.
# Does not copy the git repo. The .gem is supplied at run time.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tar \
      build-essential \
      g++ \
      make \
      openjdk-21-jdk-headless \
      r-base \
      r-base-dev \
      pandoc \
      pkg-config \
      libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

ARG JRUBY_VERSION=10.0.3.0
RUN curl -fsSL \
      "https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz" \
    | tar -xz -C /opt \
    && ln -s "/opt/jruby-${JRUBY_VERSION}" /opt/jruby

ENV PATH="/opt/jruby/bin:${PATH}" \
    JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

# Gatekeeper compile needs Rcpp. Fast specs also pull ggplot2/dplyr/knitr at load time;
# compile those here so rspec does not hit the 60s bridge timeout installing from CRAN.
RUN Rscript -e "install.packages(c('Rcpp','dplyr','knitr','rmarkdown','ggplot2','gridExtra'), repos='https://cloud.r-project.org')"

# libcurl + openssl: needed to download/load Arrow. Install the R package from
# Posit Linux binaries so we do not compile Arrow C++ (CRAN source does).
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

# Isolated gem home so nothing from a host Ruby leaks in.
ENV GEM_HOME=/opt/smoke-gems \
    GEM_PATH=/opt/smoke-gems \
    GALAAZ_RCPP_CACHE_DIR=/tmp/galaaz_rcpp_cache_smoke
ENV PATH="${GEM_HOME}/bin:${PATH}"

CMD ["install-and-smoke.sh"]
