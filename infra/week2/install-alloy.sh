#!/usr/bin/env bash
# Execute on disposable EC2 via SSM as root; never use set -x.
set -euo pipefail
umask 077
: "${AWS_REGION:?AWS_REGION must be set explicitly}"
p() { aws ssm get-parameter --region "$AWS_REGION" --name "/umc/app/$1" --with-decryption --query Parameter.Value --output text; }
# Root-only file avoids secrets in docker run arguments / SSM command bodies.
mkdir -p /opt/alloy /var/lib/alloy
chmod 700 /opt/alloy /var/lib/alloy
trap 'rm -f /opt/alloy/runtime.env' EXIT
{
  for pair in GC_FLEET_URL:gc-fleet-url GC_FLEET_USER:gc-fleet-user GC_PROM_URL:gc-prom-url GC_PROM_USER:gc-prom-user GC_TOKEN:gc-token MYSQL_DSN:mysql-dsn; do
    key="${pair%%:*}"; name="${pair#*:}"; value=$(p "$name")
    test -n "$value" && test "$value" != None || { echo "Missing parameter name: $name" >&2; exit 1; }
    printf '%s=%s\n' "$key" "$value"
    if [ "$key" = GC_TOKEN ]; then printf 'GCLOUD_RW_API_KEY=%s\n' "$value"; fi
  done
} > /opt/alloy/runtime.env
docker pull grafana/alloy:v1.20.1 >/dev/null
docker run --rm --network none --env-file /opt/alloy/runtime.env   -v /opt/alloy/config.alloy:/etc/alloy/config.alloy:ro   grafana/alloy:v1.20.1 validate /etc/alloy/config.alloy
if docker container inspect alloy >/dev/null 2>&1; then docker rm -f alloy >/dev/null; fi
docker run -d --name alloy --restart unless-stopped --network host --pid host   -v /:/rootfs:ro   -v /opt/alloy/config.alloy:/etc/alloy/config.alloy:ro   -v /var/lib/alloy:/var/lib/alloy   --env-file /opt/alloy/runtime.env   grafana/alloy:v1.20.1 run --storage.path=/var/lib/alloy   --server.http.listen-addr=127.0.0.1:12345 /etc/alloy/config.alloy >/dev/null
echo 'Alloy launched; credentials not printed. Verify /-/ready and Fleet Inventory.'
