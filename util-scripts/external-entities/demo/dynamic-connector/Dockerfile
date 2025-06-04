FROM registry.fedoraproject.org/fedora:41

RUN dnf install -y python pip

RUN pip install flask

COPY dynamic-connector.py /dynamic-connector.py

CMD python /dynamic-connector.py
