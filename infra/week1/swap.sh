#!/usr/bin/env bash
# Executed as root through SSM after the target has drained. Never enable set -x.
set -euo pipefail
source /opt/umc/region.env
export AWS_DEFAULT_REGION="$AWS_REGION"
p() { aws ssm get-parameter --name "/umc/app/$1" --with-decryption --query Parameter.Value --output text; }
IMAGE=$(p image)
aws ecr get-login-password | docker login --username AWS --password-stdin "${IMAGE%%/*}" >/dev/null
docker pull "$IMAGE" >/dev/null
umask 077
{
  printf 'DB_HOST=%s\n' "$(p db-host)"
  printf 'DB_PORT=3306\nDB_NAME=%s\n' "$(p db-name)"
  printf 'DB_USER=%s\n' "$(p db-user)"
  printf 'DB_PASSWORD=%s\n' "$(p db-password)"
  printf 'JWT_SECRET=%s\n' "$(p jwt-secret)"
  printf 'JWT_ACCESS_EXPIRATION=3600\nPORT=3000\nCORS_DISABLED=true\n'
} > /opt/umc/app.env
if docker container inspect app >/dev/null 2>&1; then
  docker stop -t 30 app >/dev/null
  docker rm app >/dev/null
fi
docker run -d --name app --restart unless-stopped --env-file /opt/umc/app.env -p 3000:3000 "$IMAGE" >/dev/null
for attempt in $(seq 1 60); do
  if curl --fail --silent --max-time 3 http://127.0.0.1:3000/health >/dev/null; then
    echo 'Container readiness passed'
    exit 0
  fi
  sleep 2
done
echo 'Container readiness failed; leave target out of service' >&2
exit 1
