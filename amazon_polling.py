# pip install requests bs4 python-dotenv espeak-ng termcolor

import json
import os
import time

import dotenv
import requests
from bs4 import BeautifulSoup
from termcolor import colored  # pip install termcolor

dotenv.load_dotenv()

# tracking url example:
# "https://www.amazon.in/progress-tracker/package/share/?unauthenticated=1&vt=SHARED_PACKAGE_TRACKING&shareToken=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx"

# run this script with the env variable set:
# $ AMAZON_TRACKING_URL="https://..." python amazon_polling.py

TRACKING_URL = os.getenv("AMAZON_TRACKING_URL", None)

if not TRACKING_URL:
    print(
        colored(
            "[ERROR] Please set the AMAZON_TRACKING_URL environment variable.",
            "red",
        )
    )
    exit(-1)

POLL_INTERVAL = 60
STATE_FILE = "last_state.json"


def speak(message):
    os.system(f'espeak-ng "{message}"')


def load_last_state():
    if os.path.isfile(STATE_FILE):
        with open(STATE_FILE, "r") as f:
            return json.load(f)
    return None


def save_state(data):
    with open(STATE_FILE, "w") as f:
        json.dump(data, f)


def interpret_status(milestone, percent):
    if milestone == "DELIVERED":
        return ("DELIVERED", "green", "Package has been delivered.")
    elif milestone in ["OUT_FOR_DELIVERY", "OUT FOR DELIVERY"]:
        return ("OUT FOR DELIVERY", "magenta", "Package is out for delivery.")
    elif percent and percent > 50:
        return ("IN TRANSIT", "yellow", "Package is on the way.")
    elif milestone == "SHIPPED":
        return ("SHIPPED", "blue", "Package is shipped.")
    else:
        return ("UNKNOWN", "red", "Package status is unclear.")


def fetch_tracking():
    try:
        response = requests.get(TRACKING_URL, headers={"User-Agent": "Mozilla/5.0"})
        soup = BeautifulSoup(response.text, "html.parser")
        script = soup.find("script", {"type": "a-state"})
        data = json.loads(script.text.strip())
        return {
            "milestone": data.get("progressTracker", {}).get("lastReachedMilestone"),
            "percent": data.get("progressTracker", {}).get(
                "lastTransitionPercentComplete"
            ),
        }
    except:
        return None


if __name__ == "__main__":
    import os

    os.system("clear" if os.name == "posix" else "cls")
    print("🔄 Amazon Tracker Started")
    while True:
        current = fetch_tracking()
        if not current:
            print(colored("[ERROR] Failed to fetch current tracking data.", "red"))
            time.sleep(POLL_INTERVAL)
            continue

        last = load_last_state()

        if current != last:
            status, color, speak_msg = interpret_status(
                current["milestone"], current["percent"]
            )
            print(
                colored(f"==> STATUS CHANGED: {status} ({current['percent']}%)", color)
            )
            speak(speak_msg)
            save_state(current)
        else:
            print(
                colored(
                    f"[NO CHANGE] Current Status: {current['milestone']} ({current['percent']}%)",
                    "cyan",
                )
            )

        time.sleep(POLL_INTERVAL)
