FROM registry.fedoraproject.org/fedora:41

RUN dnf install -y python pip

RUN pip install flask

COPY ping_server.py /ping_server.py

CMD python /ping_server.py
