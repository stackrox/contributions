FROM registry.access.redhat.com/ubi9:9.1.0-1782

# #ENV Variables
# ENV APP_MODULE testapp:app
# ENV APP_CONFIG gunicorn.conf.py

#Change User
USER 0

# Install the required software
RUN dnf install -y wget yum-utils make gcc openssl-devel bzip2-devel libffi-devel zlib-devel && \
    wget https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tgz && \
    tar xzf Python-3.10.8.tgz && \
    cd Python-3.10.8 && \
    ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions && \
    make altinstall && \
    cd .. && \
    rm Python-3.10.8.tgz

# # Install pip
# RUN curl -O https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && python3 get-pip.py

#Make Application Directory
RUN mkdir ./app && cd ./app && echo python -V

# Copy Files into containers
COPY ./ ./app

#WORKDIR
WORKDIR ./app

#Install App Dependecies
RUN pip3.10 install -r requirements.txt && pip3.10 install --upgrade pip

#Expose Ports
EXPOSE 8080/tcp

#Change Permissions to allow not root-user work
RUN chmod -R g+rw ./

#Change User
USER 1001

#ENTRY
ENTRYPOINT python3.10 app.py
