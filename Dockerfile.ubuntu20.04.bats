FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    curl

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
