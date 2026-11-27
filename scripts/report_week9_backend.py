"""Render actual execution logs as clearly labelled documents, never terminal mockups."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'evidence/week9-backend'
font = ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc', 23)
title_font = ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc', 32)
def render(filename, title, text):
    probe = ImageDraw.Draw(Image.new('RGB',(1,1)))
    lines = []
    for line in text.splitlines():
        current = ''
        for ch in line:
            if probe.textlength(current + ch,font=font)>1300:
                lines.append(current)
                current=ch
            else: current+=ch
        lines.append(current)
    img=Image.new('RGB',(1400,160+33*len(lines)),'white')
    draw=ImageDraw.Draw(img)
    draw.text((40,24),title,font=title_font,fill='#302448')
    draw.text((40,78),'실제 실행 원문/코드 문서 · 터미널 스크린샷이 아닙니다.',font=font,fill='#596174')
    for i,line in enumerate(lines): draw.text((40,130+i*33),line,font=font,fill='#182032')
    img.save(OUT/filename,quality=94)
logs=(OUT/'backend-test.txt').read_text()
relevant=[l for l in logs.splitlines() if any(x in l for x in ['favorite integration','rating integration','transaction','Swagger:','favorite unit','rating unit','ℹ'])]
render('07-all-tests-passed-rendered.jpg','백엔드 전체85 통과 / 신규 단위4·메모리DB 통합11', '\n'.join(relevant))
render('08-unit-code-rendered.jpg','필수 평점 단위 테스트 + 본문 즐겨찾기 단위 테스트', (ROOT/'movie-backend/test/week9-unit.test.cjs').read_text())
render('09-duplicate-removed-rendered.jpg','중복 검사 제거 → 단위·통합2 실패 (예상된 실패)', (OUT/'duplicate-removed.txt').read_text())
render('10-transaction-removed-rendered.jpg','트랜잭션 제거 → 평점1건 잔존 (예상된 실패)', (OUT/'transaction-removed.txt').read_text())
render('11-live-mysql-rendered.jpg','실제 MySQL 실행·롤백·정리 결과', (OUT/'live-verification.txt').read_text())
render('12-flutter-checks-rendered.jpg','Flutter 회귀 테스트109 통과 / 분석 결과', (OUT/'flutter-analyze.txt').read_text()+'\n'+ '\n'.join((OUT/'flutter-test.txt').read_text().splitlines()[-5:]))
render('13-rollback-code-rendered.jpg','첫 INSERT 이후 실패 및 DB 개수 검증 코드', '\n'.join((ROOT/'movie-backend/test/week9-memory.e2e.test.cjs').read_text().splitlines()[90:155]))
render('14-restored-passed-rendered.jpg','중복 검사·트랜잭션 복원 후 신규15 통과', (OUT/'restored-tests.txt').read_text())
print('Rendered 8 labelled evidence documents from actual logs/code.')
