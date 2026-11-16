"""Run Android scenarios and capture the actual emulator screen and videos."""
import json
from pathlib import Path
import re
import signal
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'evidence/week8-frontend'
ADB = '/Users/yeonie/Library/Android/sdk/platform-tools/adb'
OUT.mkdir(parents=True, exist_ok=True)
phase = sys.argv[1] if len(sys.argv) > 1 else 'live'
video = None
video_name = None

def finish_video():
    global video, video_name
    if video is None:
        return
    subprocess.run([ADB, 'shell', 'pkill', '-2', 'screenrecord'], check=False, capture_output=True)
    try:
        video.wait(timeout=12)
    except subprocess.TimeoutExpired:
        video.terminate()
        video.wait(timeout=5)
    subprocess.run([ADB, 'pull', f'/sdcard/{video_name}.mp4', str(OUT / f'{video_name}.mp4')], check=True, capture_output=True)
    video = None

command = ['flutter', 'test', '--no-pub', '--no-uninstall', 'integration_test/week8_evidence_test.dart', '-d', 'emulator-5554',
           f'--dart-define=W8_PHASE={phase}', '--reporter=expanded']
process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
try:
    with (OUT / f'android-{phase}.txt').open('w') as log:
        for raw in process.stdout:
            line = raw.replace('\r', '')
            log.write(line)
            log.flush()
            match = re.search(r'WEEK8_VIDEO_START=([a-zA-Z0-9-]+)', line)
            if match:
                video_name = match.group(1)
                video = subprocess.Popen([ADB, 'shell', 'screenrecord', '--bit-rate', '2500000', '--time-limit', '180',
                                          f'/sdcard/{video_name}.mp4'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            match = re.search(r'WEEK8_CAPTURE=([a-zA-Z0-9-]+)', line)
            if match:
                name = match.group(1)
                with (OUT / f'{name}.png').open('wb') as image:
                    subprocess.run([ADB, 'exec-out', 'screencap', '-p'], stdout=image, check=True)
                print(f'Captured {name}', flush=True)
            if 'WEEK8_RESULT=' in line:
                result = json.loads(line.split('WEEK8_RESULT=', 1)[1])
                (OUT / f'result-{phase}.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
                print(f"Verified {phase}: passed={result['passed']}", flush=True)
            if 'WEEK8_VIDEO_STOP=' in line:
                finish_video()
            if not line.startswith('WEEK8_') and any(text in line for text in ['Error', 'Exception', 'failed', 'passed', 'Running Gradle', 'Installing', 'Expected:', 'Actual:']):
                print(line.rstrip(), flush=True)
    code = process.wait()
finally:
    finish_video()
sys.exit(code)
