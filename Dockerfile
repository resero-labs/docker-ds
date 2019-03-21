FROM nvidia/cuda:9.0-cudnn7-runtime-ubuntu16.04
ARG DEBIAN_FRONTEND=noninteractive
LABEL maintainer="rappdw@gmail.com"

# install python 3.6.7
RUN apt-get update; \
    apt-get install -y \
        gcc \
        make \
        openssl \
        wget \
        zlib1g-dev \
        libreadline-gplv2-dev \
        libncursesw5-dev \
        libssl-dev \
        libsqlite3-dev \
        tk-dev \
        libgdbm-dev \
        libc6-dev \
        libbz2-dev \
		tcl \
		tk \
		libffi-dev \
		libgomp1 \
		libssl-dev \
    ; \
    apt-get clean; \
    rm -rf /var/tmp/* /tmp/* /var/lib/apt/lists/*; \
    cd \tmp; \
    wget https://www.python.org/ftp/python/3.6.7/Python-3.6.7.tgz;\
    tar -xvf Python-3.6.7.tgz; \
    cd Python-3.6.7; \
    ./configure; \
    make; \
    make install; \
    pip3 install -U pip; \
    ldconfig; \
    cd /usr/local/bin; \
	ln -Fs idle3 idle; \
	ln -Fs pydoc3 pydoc; \
	ln -Fs python3 python; \
	ln -Fs python3-config python-config


# install node.js
ENV NODE_VERSION=8.10.0 \
    YARN_VERSION=1.5.1

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && buildDeps='xz-utils' \
    && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x64';; \
      ppc64el) ARCH='ppc64le';; \
      s390x) ARCH='s390x';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armv7l';; \
      i386) ARCH='x86';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
  && apt-get update && apt-get install -y --no-install-recommends \
    $buildDeps \
    ca-certificates \
    curl \
    openssl \
  && rm -rf /var/lib/apt/lists/* \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && apt-get purge -y --auto-remove $buildDeps \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

# install jupyter and datascience bundle
COPY root/tmp/requirements.txt /tmp/requirements.txt

RUN cd /tmp; \
    pip3 install --no-cache-dir -r requirements.txt

RUN jupyter serverextension enable --py jupyterlab \
    && jupyter nbextension enable --py widgetsnbextension \
    && jupyter labextension install \
        @jupyter-widgets/jupyterlab-manager \
        jupyter-matplotlib \
        jupyterlab_bokeh \
        @pyviz/jupyterlab_pyviz \
        @jupyterlab/plotly-extension \
        @mflevine/jupyterlab_html

#
# Configure environment
#
# Use 1000 for uid and gid. It's common in the Resero environments for a host directory to be mounted
# into the container, when this is done, it's also common for the uid/gid of the user doing so to be
# 1000. This allows for "correct" file priveledges when doing so
ENV NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=1000

# assumes that the project has been mounted into /home/jovyan/project
# to ensure this derived projects should add the following to their dockerutils.cfg file
# [notebook]
# volumes=--mount type=bind,source={project_root},target=/home/jovyan/project

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

RUN set -ex; \
    apt-get update; \
    apt-get install -y \
        less \
        vim \
    ; \
    apt-get clean; \
    rm -rf /var/tmp/* /tmp/* /var/lib/apt/lists/*

COPY root/ /

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-9.0/targets/x86_64-linux/lib/

CMD ["/usr/local/bin/start-notebook.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]

