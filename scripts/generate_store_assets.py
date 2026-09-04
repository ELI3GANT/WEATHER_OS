import os
import subprocess

PROJECT_DIR = "/home/eli3gant/OTP/01_PRODUCTS/weather-os"
OUTPUT_DIR = os.path.join(PROJECT_DIR, "assets/store_listing/google_play")
FONT_BOLD = os.path.join(PROJECT_DIR, "assets/fonts/Barlow-Bold.ttf")
FONT_SEMIBOLD = os.path.join(PROJECT_DIR, "assets/fonts/Barlow-SemiBold.ttf")
FONT_MEDIUM = os.path.join(PROJECT_DIR, "assets/fonts/Barlow-Medium.ttf")

os.makedirs(OUTPUT_DIR, exist_ok=True)

screens = [
    {
        "filename": "02_screenshot_telemetry.png",
        "tag": "LIVE TELEMETRY",
        "title": "PRECISION WEATHER",
        "subtitle": "Cinematic conditions & atmospheric tracking",
        "source": os.path.join(PROJECT_DIR, "test/visual/goldens/home_compact_android.png"),
    },
    {
        "filename": "03_screenshot_forecast.png",
        "tag": "ATMOSPHERIC RAILS",
        "title": "HOURLY & 7-DAY OUTLOOK",
        "subtitle": "Calibrated thermal bars & threat matrix",
        "source": os.path.join(PROJECT_DIR, "test/visual/goldens/showcase_compact.png"),
    },
    {
        "filename": "04_screenshot_storm.png",
        "tag": "SEVERE RISK MATRIX",
        "title": "HAZARD INTELLIGENCE",
        "subtitle": "Convective storm alerts & wind shear indicators",
        "source": os.path.join(PROJECT_DIR, "test/visual/goldens/showcase_storm.png"),
    },
    {
        "filename": "05_screenshot_density.png",
        "tag": "HIGH-DENSITY METRICS",
        "title": "DEEP ATMOSPHERE",
        "subtitle": "Barometric pressure, dew point & UV index",
        "source": os.path.join(PROJECT_DIR, "test/visual/goldens/home_large_text.png"),
    },
]

def render_screenshot(item):
    out_path = os.path.join(OUTPUT_DIR, item["filename"])
    src_path = item["source"]
    tag = item["tag"]
    title = item["title"]
    subtitle = item["subtitle"]
    
    # 1. Scale source UI to fit nicely inside phone mockup (e.g. width 880)
    scaled_ui = f"/tmp/scaled_ui_{os.path.basename(item['filename'])}"
    subprocess.run([
        "magick", src_path,
        "-resize", "880x",
        scaled_ui
    ], check=True)
    
    # 2. Add rounded corners and border
    mockup_ui = f"/tmp/mockup_{os.path.basename(item['filename'])}"
    subprocess.run([
        "magick", scaled_ui,
        "-bordercolor", "#25374C",
        "-border", "3",
        mockup_ui
    ], check=True)

    # 3. Compose onto 1080x2400 canvas
    cmd = [
        "magick",
        "-size", "1080x2400",
        "gradient:#0A131F-#03060A",
        # Tag
        "-font", FONT_SEMIBOLD,
        "-pointsize", "34",
        "-fill", "#38BDF8",
        "-gravity", "North",
        "-annotate", "+0+120", tag,
        # Title
        "-font", FONT_BOLD,
        "-pointsize", "74",
        "-fill", "#F6FAFF",
        "-gravity", "North",
        "-annotate", "+0+185", title,
        # Subtitle
        "-font", FONT_MEDIUM,
        "-pointsize", "38",
        "-fill", "#8CA0BA",
        "-gravity", "North",
        "-annotate", "+0+285", subtitle,
        # Composite Phone Mockup
        "-gravity", "North",
        "-geometry", "+0+410",
        mockup_ui,
        "-composite",
        "-strip",
        out_path
    ]
    subprocess.run(cmd, check=True)
    print(f"✅ Generated: {out_path}")

for screen in screens:
    render_screenshot(screen)
