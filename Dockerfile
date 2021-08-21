FROM ubuntu:18.04
RUN apt-get update && apt-get install -yyq python3 python3-pip
COPY requirements.txt /zips/requirements.txt
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir -r /zips/requirements.txt
RUN pip3 install --use-feature=2020-resolver opentelemetry-distro==0.21b0 opentelemetry-launcher opentelemetry-instrumentation-flask
COPY zips.json /zips
COPY templates /zips/templates
COPY entry.py /zips
COPY entrypoint.sh /zips
RUN opentelemetry-bootstrap --action=install
ENTRYPOINT ["/zips/entrypoint.sh"]
