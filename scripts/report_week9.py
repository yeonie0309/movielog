"""Build a read-only viewer of actual command/API results, never simulated results."""
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'evidence/week9-frontend'


def block(title, text):
    text = '\n'.join(line.rstrip() for line in text.splitlines())
    return '<h2>' + html.escape(title) + '</h2><pre>' + html.escape(text) + '</pre>'


summary = json.loads((OUT / 'verification-summary.json').read_text())
live = json.loads((OUT / 'result-live.json').read_text())
states = json.loads((OUT / 'result-states.json').read_text())
analyze = (OUT / 'flutter-analyze.txt').read_text()
tests = (OUT / 'flutter-test.txt').read_text()
sections = {
    'checks': '<h1>MovieLog · Week 9 실행 검증</h1><p>실제 CLI 출력·Android 테스트 결과를 읽는 뷰어. 터미널 화면을 재현한 이미지가 아닙니다.</p>' +
        block('flutter analyze --no-pub --no-fatal-infos', analyze) +
        block('flutter test --no-pub --reporter expanded', '\n'.join(tests.splitlines()[-6:])) +
        block('Android 실제 실행', '\n'.join(
            f'{phase}: ' + next(line for line in (OUT / f'android-{phase}.txt').read_text().splitlines() if 'All tests passed!' in line)
            + f'\n원본 result-{phase}.json passed=' + str((live if phase == 'live' else states)['passed'])
            for phase in ['live', 'states'])) +
        block('요약', json.dumps({k: v for k, v in summary.items() if k in ['flutterTests', 'week9Tests', 'androidScenarios', 'analyzeErrors', 'analyzeWarnings', 'existingWeek0Infos']}, ensure_ascii=False, indent=2)),
    'network': '<h1>MovieLog · 실제 v8 / TMDB 요청</h1><p>result-live.json 원본. Authorization 값·비밀번호 제외. bearerAttached는 부착 여부만 의미합니다.</p>' +
        block('실제 성공 요청 흐름', '\n'.join(f"{r['method']:6} {r['path']:35} → {r['status']}" for r in live['requests'] if r['path'].startswith('/v8/favorites') or r['path'] in ['/v8/movie-records', '/search/movie', '/discover/movie'])) +
        block('실제 통합 저장', json.dumps(next(r for r in live['requests'] if r['path'] == '/v8/movie-records'), ensure_ascii=False, indent=2)) +
        block('실제 무효 토큰 응답', json.dumps(states['requests'], ensure_ascii=False, indent=2)),
    'safety': '<h1>MovieLog · 세션·보안·정리 검증</h1><p>자동 테스트·실제 실행 기록의 결과입니다. 사람의 수동 검증 완료를 의미하지 않습니다.</p>' +
        block('실제 검증 요약', json.dumps(summary, ensure_ascii=False, indent=2)) +
        block('실패 주입 구분', '다음 page·검색·목록·영화 한 건 실패와 409/404는 제어된 실패 주입입니다.\n실제 v8 회원가입·로그인·즐겨찾기·통합 저장·계정 분리 및 AUTH401_3은 서버 응답으로 확인했습니다.\n중단 실행의 회원 ID와 데이터 정리는 interrupted-attempts에 별도 보관합니다.'),
}
style = '''body{margin:0;background:#edf0f6;color:#172033;font:16px/1.55 -apple-system,BlinkMacSystemFont,sans-serif}
main{max-width:1060px;margin:24px auto;padding:30px;background:white;border-radius:16px}h1{font-size:28px;margin:0 0 12px}h2{font-size:19px;margin:22px 0 8px}p{color:#536078}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f4f6fb;border-left:4px solid #745ab5;padding:14px;font:14px/1.5 ui-monospace,Menlo,monospace}nav a{margin-right:20px}'''
for name, content in sections.items():
    (OUT / f'{name}.html').write_text('<!doctype html><html lang="ko"><meta charset="utf-8"><title>Week 9 ' + name + '</title><style>' + style + '</style><main><nav><a href="checks.html">실행 검사</a><a href="network.html">실제 요청</a><a href="safety.html">보안·정리</a></nav>' + content + '</main></html>')
print('Built actual-result viewers: checks, network, safety')

# Rasterize the actual text as a plainly labelled document, never fake a terminal.
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print('Pillow unavailable; HTML and original logs remain available.')
else:
    font = ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc', 24)
    title_font = ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc', 34)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    for number, (name, content) in enumerate(sections.items(), 27):
        text = html.unescape(re.sub('<[^>]+>', '\n', content))
        lines = []
        for line in text.splitlines():
            if not line.strip():
                if lines and lines[-1] != '':
                    lines.append('')
                continue
            current = ''
            for character in line:
                if probe.textlength(current + character, font=font) > 1280:
                    lines.append(current)
                    current = character
                else:
                    current += character
            lines.append(current)
        image = Image.new('RGB', (1400, 160 + 35 * len(lines)), 'white')
        draw = ImageDraw.Draw(image)
        draw.text((50, 30), '실제 실행 로그 · 원문 렌더링', font=title_font, fill='#352952')
        draw.text((50, 82), '터미널·브라우저 스크린샷이 아닙니다. 원본 TXT/JSON을 함께 제공합니다.', font=font, fill='#505a70')
        for index, line in enumerate(lines):
            draw.text((50, 135 + 35 * index), line, font=font, fill='#172033')
        image.save(OUT / f'{number}-{name}-rendered.jpg', quality=92)
    print('Rendered 3 labelled images from actual logs (not UI screenshots)')
