FROM python:3.9-alpine
COPY . /zips
RUN pip install --no-cache-dir -r /zips/requirements.txt
ENTRYPOINT ["/zips/entrypoint.sh"]
