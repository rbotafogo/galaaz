# Try image: JRuby + GNU R + Galaaz already installed. Drops into gstudio (IRB).
# Distinct from docker/cold-install (that image proves gem install).
FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/rbotafogo/galaaz" \
      org.opencontainers.image.description="Galaaz 2.1 gstudio try image (JRuby + GNU R)" \
      org.opencontainers.image.licenses="BSD-2-Clause"

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
    && rm -rf /var/lib/apt/lists/*

# R packages before JRuby so a JRuby bump does not rebuild ggplot2.
RUN Rscript -e "install.packages(c('Rcpp','ggplot2','gridExtra'), repos='https://cloud.r-project.org')"

ARG JRUBY_VERSION=10.1.1.0
RUN curl -fsSL \
      "https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz" \
    | tar -xz -C /opt \
    && ln -s "/opt/jruby-${JRUBY_VERSION}" /opt/jruby

ENV PATH="/opt/jruby/bin:${PATH}" \
    JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64" \
    GEM_HOME=/opt/galaaz-gems \
    GEM_PATH=/opt/galaaz-gems \
    GALAAZ_RCPP_CACHE_DIR=/tmp/galaaz_rcpp_cache_try

ENV PATH="${GEM_HOME}/bin:${PATH}"

RUN gem sources --add https://rubygems.org/ >/dev/null 2>&1 || true \
    && gem install --source https://rubygems.org galaaz \
    && gem_dir="$(jruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path")" \
    && make -C "${gem_dir}/ext/new_bridge" all

WORKDIR /work
CMD ["gstudio"]
