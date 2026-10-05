#!/usr/bin/env bash
# Export all mart tables to CSV for Power BI.
# Usage:  ./scripts/export_marts.sh
#         DOCKER="sudo docker" ./scripts/export_marts.sh   (if docker needs sudo)
set -euo pipefail

DOCKER="${DOCKER:-docker}"
mkdir -p data/marts

for table in fact_orders event_log dim_date dim_customer dim_seller dim_product; do
  $DOCKER compose exec -T db psql -U o2c -d o2c \
    -c "\copy mart.$table TO STDOUT CSV HEADER" > "data/marts/$table.csv"
  echo "exported $table: $(wc -l < "data/marts/$table.csv") lines"
done