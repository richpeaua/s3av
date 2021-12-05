FROM python:3.8-alpine as build

# Lambda Appconfig Extension
COPY build_resources/layer.zip /tmp
RUN unzip /tmp/layer.zip -d /opt
RUN rm -rf layer.zip

FROM python:3.8-alpine

WORKDIR /opt/s3av

# Install packages
ENV CLAMD_DEPS \
        git \
        linux-headers
RUN apk update
RUN set -x \
    && apk add --no-cache --virtual .persistent-deps \
        findutils \
        bash \
        unzip \
        coreutils \
        curl \
        clamav \
        clamav-libunrar \
        freshclam \
    && apk add --no-cache --virtual .build-deps \
        $CLAMD_DEPS \
    && chmod +x /usr/bin/ \
    && mkdir -p /var/lib/clamav /run/clamav/ \
    && apk del .build-deps

RUN echo "DatabaseMirror database.clamav.net" > /var/lib/clamav/freshclam.conf
RUN echo "DatabaseOwner root" >> /var/lib/clamav/freshclam.conf

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
# Disable Bytecode (.pyc) Files
ENV PYTHONDONTWRITEBYTECODE 1

COPY --from=build /opt /opt

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

CMD [ "/bin/bash" ]