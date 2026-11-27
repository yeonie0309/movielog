# 관측 쿼리
공식 dashboard.json을 가져오고 아래 식으로 교차 확인한다. 시간 단위는 seconds다.

| 항목 | PromQL |
|---|---|
| 실제 앱 처리 RPS | `sum(rate(http_requests_total{job="app"}[1m]))` |
| 성공 쓰기 RPS | `sum(rate(http_requests_total{job="app",method="POST",route="/movie-records",status="201"}[1m]))` |
| 전체 p95 | `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{job="app"}[5m])))` |
| 인스턴스별 p95 | `histogram_quantile(0.95, sum by (instance,le) (rate(http_request_duration_seconds_bucket{job="app"}[5m])))` |
| 5xx 비율 | `sum(rate(http_requests_total{job="app",status=~"5.."}[5m])) / sum(rate(http_requests_total{job="app"}[5m])) or vector(0)` |
| 호스트별 CPU 사용률 | `100 * (1 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[1m])))` |
| DB 연결 수 (중복 수집 dedup) | `max(mysql_global_status_threads_connected)` |
| DB 실행 중 연결 수 (dedup) | `max(mysql_global_status_threads_running)` |
| 앱 수집 성공 | `up{job="app"}` |

부하 도구의 초 단위 구간별 결과와 Grafana 1m/5m rate 창은 같지 않다. 짧은40초 단계는 종료 후 scrape 여유를 두고, 보고서에 구간과 질의 시점을 남긴다. p95를 인스턴스끼리 평균내지 않는다.
RDS를 두 Alloy가 읽으므로 connected/running을 sum하면 2배가 된다. max를 사용한다.
원본 워크북 알림의 오류율식에 IS ABOVE 1을 적용하면 100% 초과 조건이다. 필수 p95 알림은 histogram 식 >1초, 오류율 추가알림은 >0.01로 구분한다.
p95는 95백분위수다. 이를 100명 중1명 대기시간으로 해석하지 않는다.
