import os, time, requests
from datetime import datetime

NGROK_URL = os.getenv('NGROK_URL','').rstrip('/')
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
TG_CHAT_ID = os.getenv('TG_CHAT_ID')
CHECK_INTERVAL = int(os.getenv('CHECK_INTERVAL', '300'))
TIMEOUT = int(os.getenv('CHECK_TIMEOUT', '8'))

def send_telegram(msg):
    if not TELEGRAM_BOT_TOKEN or not TG_CHAT_ID:
        print('Telegram creds missing; cannot send alert.')
        return
    try:
        url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
        payload = {'chat_id': TG_CHAT_ID, 'text': msg}
        r = requests.post(url, json=payload, timeout=10)
        print('tg status', r.status_code)
    except Exception as e:
        print('tg send failed', e)

def check_target():
    if not NGROK_URL:
        print('NGROK_URL not set. Exiting monitor.')
        return False
    candidates = [NGROK_URL + '/health', NGROK_URL]
    for u in candidates:
        try:
            r = requests.get(u, timeout=TIMEOUT)
            print('checked', u, '->', r.status_code)
            if r.status_code == 200:
                return True
        except Exception as e:
            print('check failed', u, e)
    return False

def main_loop():
    print('Bella monitor starting. NGROK_URL=', NGROK_URL)
    while True:
        ok = check_target()
        ts = datetime.utcnow().isoformat()
        if not ok:
            msg = f"[Bella Monitor] Colab / Bella runtime appears DOWN (ngrok check failed) at {ts}"
            print(msg)
            send_telegram(msg)
        else:
            print(f"[{ts}] Target healthy.")
        time.sleep(CHECK_INTERVAL)

if __name__ == '__main__':
    main_loop()
