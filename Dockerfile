FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl git libyang2-tools make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY . ./
CMD ["sh", "-c", "PYANG=pyang XYM=xym scripts/validate-yang.sh"]
