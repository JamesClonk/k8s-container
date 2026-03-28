FROM ubuntu:24.04

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# force tzdata to be non-interactive
RUN ln -fs /usr/share/zoneinfo/Europe/Zurich /etc/localtime
RUN DEBIAN_FRONTEND=noninteractive DEBCONF_FRONTEND=noninteractive \
 && apt-get -y update \
 && apt-get -y dist-upgrade \
 && apt-get -y install tzdata \
 && apt-get clean \
 && find /usr/share/doc/*/* ! -name copyright | xargs rm -rf \
 && apt-get autoremove -y \
 && rm -rf \
    /usr/share/man/* /usr/share/info/* \
    /var/lib/apt/lists/* /tmp/*

RUN apt-get -y update \
 && DEBIAN_FRONTEND=noninteractive DEBCONF_FRONTEND=noninteractive apt-get -y install \
      git vim-tiny openssh-client curl wget jq ca-certificates apt-transport-https \
      wireguard wireguard-tools unzip bzip2 sudo net-tools traceroute apache2-utils \
      iputils-arping iputils-clockdiff iputils-ping iputils-tracepath iproute2 dnsutils
RUN update-ca-certificates

# https://googlechromelabs.github.io/chrome-for-testing/
ENV CHROME_VERSION=143.0.7499.192
# install chrome
RUN wget --no-verbose "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" \
 && apt-get install -y "./google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" \
 && rm -rf google-chrome-stable_${CHROME_VERSION}-1_amd64.deb
# install chromedriver
RUN wget --no-verbose "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip" \
 && unzip chromedriver-linux64.zip \
 && mv chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
 && chmod u+x /usr/local/bin/chromedriver \
 && rm -rf chromedriver*

RUN apt-get -y update \
 && DEBIAN_FRONTEND=noninteractive DEBCONF_FRONTEND=noninteractive apt-get -y install \
    ruby-dev libreadline-dev libtool libssl-dev libffi-dev libyaml-dev libz-dev openssl build-essential cmake \
 && apt-get clean \
 && find /usr/share/doc/*/* ! -name copyright | xargs rm -rf \
 && apt-get autoremove -y \
 && rm -rf \
    /usr/share/man/* /usr/share/info/* \
    /var/lib/apt/lists/* /tmp/*

# add ~/bin to path for custom binaries
ENV PATH=/root/bin:$PATH
# add ~/.local/bin to path, because of pip installs
ENV PATH=/root/.local/bin:$PATH

# install mise: https://github.com/jdx/mise/releases
ENV MISE_VERSION=2026.1.2
RUN wget --no-verbose "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-x64" \
 && mv "mise-v${MISE_VERSION}-linux-x64" /usr/local/bin/mise \
 && chmod u+x /usr/local/bin/mise
# add mise shims to path
ENV PATH=/root/.local/share/mise/shims:$PATH
# install mise runtimes..
RUN mise activate --shims \
 && mise use --global ruby@3.2.8 \
 && mise use --global go@1.22.12

# install bundler
RUN mise activate --shims \
 && gem install bundler

# install useful ruby gems
RUN mise activate --shims \
 && gem install httparty \
 && gem install rest-client \
 && gem install deep_merge \
 && gem install hashdiff \
 && gem install fugit \
 && gem install chronic \
 && gem install json \
 && gem install rexml

# install docker
RUN wget --no-verbose 'https://download.docker.com/linux/static/stable/x86_64/docker-25.0.5.tgz' \
 && tar -zxf docker-25.0.5.tgz \
 && chmod u+x docker/* \
 && mv docker/* /usr/local/bin/. \
 && rm -f docker-25.0.5.tgz
RUN /usr/local/bin/docker --version

# https://github.com/regclient/regclient
ENV REGCTL_VERSION=0.11.1
# install regctl
RUN wget --no-verbose "https://github.com/regclient/regclient/releases/download/v${REGCTL_VERSION}/regctl-linux-amd64" \
  && mv regctl-linux-amd64 /usr/local/bin/regctl \
  && chmod u+x /usr/local/bin/regctl

# install regsync
RUN wget --no-verbose "https://github.com/regclient/regclient/releases/download/v${REGCTL_VERSION}/regsync-linux-amd64" \
  && mv regsync-linux-amd64 /usr/local/bin/regsync \
  && chmod u+x /usr/local/bin/regsync

# install regbot
RUN wget --no-verbose "https://github.com/regclient/regclient/releases/download/v${REGCTL_VERSION}/regbot-linux-amd64" \
  && mv regbot-linux-amd64 /usr/local/bin/regbot \
  && chmod u+x /usr/local/bin/regbot

# install mc
RUN wget --no-verbose 'https://dl.minio.io/client/mc/release/linux-amd64/mc' \
&& mv mc /usr/local/bin/mc \
 && chmod u+x /usr/local/bin/mc \
 && mc ls || true

# install sops: https://github.com/getsops/sops
ENV SOPS_VERSION=3.11.0
RUN wget --no-verbose "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" \
  && mv "sops-v${SOPS_VERSION}.linux.amd64" /usr/local/bin/sops \
  && chmod u+x /usr/local/bin/sops

# install yj (yaml/json converter): https://github.com/sclevine/yj
RUN wget --no-verbose 'https://github.com/sclevine/yj/releases/download/v5.1.0/yj-linux-amd64' \
  && mv yj-linux-amd64 /usr/local/bin/yj \
  && chmod u+x /usr/local/bin/yj

# install yq (jq for yaml): https://github.com/mikefarah/yq
RUN wget --no-verbose 'https://github.com/mikefarah/yq/releases/download/v4.49.2/yq_linux_amd64' \
  && mv yq_linux_amd64 /usr/local/bin/yq \
  && chmod u+x /usr/local/bin/yq

# install kubectl
RUN wget --no-verbose https://dl.k8s.io/release/v1.34.5/bin/linux/amd64/kubectl \
  && mv kubectl /usr/local/bin/kubectl \
  && chmod u+x /usr/local/bin/kubectl

# install cnpg plugin: https://github.com/cloudnative-pg/cloudnative-pg/
RUN wget --no-verbose 'https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v1.27.1/kubectl-cnpg_1.27.1_linux_x86_64.tar.gz' \
  && tar -xzf kubectl-cnpg_1.27.1_linux_x86_64.tar.gz kubectl-cnpg \
  && mv kubectl-cnpg /usr/local/bin/kubectl-cnpg \
  && chmod u+x /usr/local/bin/kubectl-cnpg \
  && rm -f kubectl-cnpg_1.27.1_linux_x86_64.tar.gz

# install taskfile
RUN wget --no-verbose 'https://github.com/go-task/task/releases/download/v3.49.1/task_linux_amd64.tar.gz' \
 && tar -xzf task_linux_amd64.tar.gz \
 && mv completion/bash/task.bash /etc/bash_completion.d/task \
 && mv task /usr/local/bin/task \
 && chmod u+x /usr/local/bin/task \
 && rm -rf completion LICENSE README.md task_linux_amd64.tar.gz

# install plato
RUN wget --no-verbose 'https://github.com/JamesClonk/plato/releases/download/v1.2.0/plato_1.2.0_linux_x86_64.tar.gz' \
 && tar -xzf plato_1.2.0_linux_x86_64.tar.gz \
 && mv plato /usr/local/bin/plato \
 && chmod u+x /usr/local/bin/plato \
 && rm -rf LICENSE README.md plato_1.2.0_linux_x86_64.tar.gz

# install hurl
RUN wget --no-verbose 'https://github.com/Orange-OpenSource/hurl/releases/download/6.1.1/hurl-6.1.1-x86_64-unknown-linux-gnu.tar.gz' \
 && tar -xzf hurl-6.1.1-x86_64-unknown-linux-gnu.tar.gz \
 && mv hurl-6.1.1-x86_64-unknown-linux-gnu/bin/hurl /usr/local/bin/hurl \
 && mv hurl-6.1.1-x86_64-unknown-linux-gnu/bin/hurlfmt /usr/local/bin/hurlfmt \
 && chmod u+x /usr/local/bin/hurl \
 && chmod u+x /usr/local/bin/hurlfmt \
 && rm -rf hurl-6.1.1*

# install kapp: https://github.com/carvel-dev/kapp
RUN wget --no-verbose 'https://github.com/carvel-dev/kapp/releases/download/v0.65.0/kapp-linux-amd64' \
  && mv kapp-linux-amd64 /usr/local/bin/kapp \
  && chmod u+x /usr/local/bin/kapp

# install ytt: https://github.com/carvel-dev/ytt/
RUN wget --no-verbose 'https://github.com/carvel-dev/ytt/releases/download/v0.52.2/ytt-linux-amd64' \
  && mv ytt-linux-amd64 /usr/local/bin/ytt \
  && chmod u+x /usr/local/bin/ytt

# install kbld: https://github.com/carvel-dev/kbld
RUN wget --no-verbose 'https://github.com/carvel-dev/kbld/releases/download/v0.47.0/kbld-linux-amd64' \
  && mv kbld-linux-amd64 /usr/local/bin/kbld \
  && chmod u+x /usr/local/bin/kbld

# install imgpkg: https://github.com/carvel-dev/imgpkg/
RUN wget --no-verbose 'https://github.com/carvel-dev/imgpkg/releases/download/v0.47.0/imgpkg-linux-amd64' \
  && mv imgpkg-linux-amd64 /usr/local/bin/imgpkg \
  && chmod u+x /usr/local/bin/imgpkg

# install vendir: https://github.com/carvel-dev/vendir/
RUN wget --no-verbose 'https://github.com/carvel-dev/vendir/releases/download/v0.45.0/vendir-linux-amd64' \
  && mv vendir-linux-amd64 /usr/local/bin/vendir \
  && chmod u+x /usr/local/bin/vendir

# install helm
ENV HELM_VERSION=3.16.4
RUN wget --no-verbose "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
 && tar -xzf "helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
 && mv linux-amd64/helm /usr/local/bin/helm \
 && chmod u+x /usr/local/bin/helm \
 && rm -f "helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
 && rm -rf linux-amd64

# install age: https://github.com/FiloSottile/age/
ENV AGE_VERSION=1.2.1
RUN wget --no-verbose "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-amd64.tar.gz" \
  && tar -xzf "age-v${AGE_VERSION}-linux-amd64.tar.gz" \
  && mv age/age age/age-keygen /usr/local/bin/ \
  && chmod u+x /usr/local/bin/age \
  && chmod u+x /usr/local/bin/age-keygen \
  && rm -rf age*

# enable mise properly (shim for non-interactive, normal for interactive)
RUN echo 'eval "$(mise activate bash --shims)"' >> ~/.bash_profile
RUN echo 'eval "$(mise activate bash)"' >> ~/.bashrc
