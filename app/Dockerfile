FROM python:3.7-alpine

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /opt/

ENTRYPOINT FLASK_APP=/opt/app.py flask run --host=0.0.0.0 --port=80
