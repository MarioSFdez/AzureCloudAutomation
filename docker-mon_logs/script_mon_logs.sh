#!/bin/bash
# Creación de directorios necesarios para docker-compose
mkdir -p ./loki-data/data ./loki-data/index ./loki-data/cache ./loki-data/chunks ./loki-data/compactor ./loki-data/wal
mkdir -p ./grafana-data

# Asignar los permisos a los directorios
sudo chown -R 10001:10001 ./loki-data
sudo chown -R 472:472 ./grafana-data ./dashboards ./datasources ./alerting

# Iniciar docker-compose
#docker-compose up -d
