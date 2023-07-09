FROM ubuntu:18.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.34.1/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
# Install jq
RUN wget https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 -O /usr/bin/jq && chmod +x /usr/bin/jq

# Install Bats
RUN git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && \
    /tmp/bats-core/install.sh /usr/local && \
    rm -r /tmp/bats-core

# Install Bats support
RUN git clone https://github.com/ztombol/bats-support /opt/bats-test-helpers/bats-support

# Install Bats assert
RUN git clone https://github.com/ztombol/bats-assert /opt/bats-test-helpers/bats-assert

# Install Bats mock
RUN git clone https://github.com/lox/bats-mock /opt/bats-test-helpers/bats-mock
