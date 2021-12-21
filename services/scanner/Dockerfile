FROM public.ecr.aws/lambda/python:3.8 as build

# Install packages
RUN yum update -y
RUN yum install -y cpio yum-utils unzip
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Download ClamAV and related libraries and extract binaries and library files

WORKDIR /tmp
RUN yumdownloader -x \*i686 --archlist=x86_64 clamav clamav-lib clamav-update json-c pcre2 libprelude gnutls libtasn1 lib64nettle nettle libtool-ltdl
RUN rpm2cpio clamav-0*.rpm | cpio -idmv
RUN rpm2cpio clamav-lib*.rpm | cpio -idmv
RUN rpm2cpio clamav-update*.rpm | cpio -idmv
RUN rpm2cpio json-c*.rpm | cpio -idmv
RUN rpm2cpio pcre*.rpm | cpio -idmv
RUN rpm2cpio gnutls*.rpm | cpio -idmv
RUN rpm2cpio nettle*.rpm | cpio -idmv
RUN rpm2cpio libprelude*.rpm | cpio -idmv
RUN rpm2cpio libtasn1*.rpm | cpio -idmv
RUN rpm2cpio libtool-ltdl*.rpm | cpio -idmv

# Lambda Appconfig Extension
COPY build_resources/layer.zip /tmp
RUN unzip /tmp/layer.zip -d /opt
RUN rm -rf layer.zip

FROM public.ecr.aws/lambda/python:3.8 as app

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
# Disable Bytecode (.pyc) Files
ENV PYTHONDONTWRITEBYTECODE 1

ENV PATH_CLAMAV /opt/clamav
ENV VS_PATH_DB /tmp/clamav_db

RUN mkdir -p ${PATH_CLAMAV}/lib
RUN mkdir -p ${VS_PATH_DB}
COPY --from=build /opt /opt
COPY --from=build /tmp/usr/bin/clamscan ${PATH_CLAMAV}
COPY --from=build /tmp/usr/bin/freshclam ${PATH_CLAMAV}
COPY --from=build /tmp/usr/lib64 ${PATH_CLAMAV}/lib
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PATH_CLAMAV}/lib
ENV PATH=$PATH:${PATH_CLAMAV}

RUN echo "DatabaseMirror database.clamav.net" > ${PATH_CLAMAV}/freshclam.conf
RUN echo "DatabaseOwner root" >> ${PATH_CLAMAV}/freshclam.conf
RUN echo "CompressLocalDatabase yes" >> ${PATH_CLAMAV}/freshclam.conf

RUN yum update -y

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .
COPY service_config.json .

CMD [ "main.lambda_handler" ]