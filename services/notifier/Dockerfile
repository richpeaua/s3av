FROM public.ecr.aws/lambda/python:3.8 

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
# Disable Bytecode (.pyc) Files
ENV PYTHONDONTWRITEBYTECODE 1

RUN yum update -y
RUN yum install -y unzip

# Lambda Appconfig Extension
## TODO refactor the below to place into multi-stage build to clean up the zip file being removed
COPY build_resources/layer.zip /tmp
RUN unzip /tmp/layer.zip -d /opt
RUN rm -rf layer.zip

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

CMD [ "main.lambda_handler" ]