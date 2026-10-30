FROM python:3.12-slim
WORKDIR /home
COPY . /home
RUN python -m venv venv \
    && . venv/bin/activate \
    && pip install --upgrade pip \
    && pip install -r requirements.txt
ENV APP_ENV=prod BG_COLOR="#1abc9c" APP_ROUTE_PREFIX=""
EXPOSE 80
CMD ["sh", "-c", ". venv/bin/activate && uvicorn \"app.main:app\" --host 0.0.0.0 --port 80 --log-level info"]
