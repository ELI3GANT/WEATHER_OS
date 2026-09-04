import os
import subprocess

PROJECT_DIR = "/home/eli3gant/OTP/01_PRODUCTS/weather-os"
OUTPUT_DIR = os.path.join(PROJECT_DIR, "assets/store_listing/google_play")
FONT_BOLD = os.path.join(PROJECT_DIR, "assets/fonts/Barlow-Bold.ttf")
FONT_SEMIBOLD = os.path.join(PROJECT_DIR, "assets/fonts/Barlow-SemiBold.ttf")
FONT_MEDIUM = os.path.join(PROJECT_DIR, "assets/fonts/Barlow-Medium.ttf")

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs("/tmp/store_render", exist_ok=True)

# 1. Prepare Base UI Sources
# Screen 1: High-res Telemetry (captured earlier at 989x2196)
ui_telemetry = "/tmp/weatheros_captures/01_telemetry.png"
if not os.path.exists(ui_telemetry):
    ui_telemetry = os.path.join(PROJECT_DIR, "test/visual/goldens/home_compact_android.png")

# Screen 2: Hourly & 7-Day Forecast (Showcase compact)
ui_forecast = os.path.join(PROJECT_DIR, "test/visual/goldens/showcase_compact.png")

# Screen 3: Storm / Severe Risk Matrix (Showcase storm)
ui_storm = os.path.join(PROJECT_DIR, "test/visual/goldens/showcase_storm.png")

# Screen 4: High-density Telemetry / Lower Primitives
ui_density = os.path.join(PROJECT_DIR, "test/visual/goldens/showcase_compact_lower.png")

screens = [
    {
        "filename": "02_screenshot_telemetry.png",
        "glow_color": "#0284C7",
        "pill": "LIVE TELEMETRY",
        "title": "PRECISION WEATHER",
        "subtitle": "Cinematic conditions, UV & atmospheric index",
        "ui_source": ui_telemetry,
    },
    {
        "filename": "03_screenshot_forecast.png",
        "glow_color": "#0D9488",
        "pill": "ATMOSPHERIC RAILS",
        "title": "HOURLY & 7-DAY OUTLOOK",
        "subtitle": "Calibrated thermal bars & dynamic threat matrix",
        "ui_source": ui_forecast,
    },
    {
        "filename": "04_screenshot_storm.png",
        "glow_color": "#7C3AED",
        "pill": "HAZARD INTELLIGENCE",
        "title": "SEVERE RISK MATRIX",
        "subtitle": "Multi-vector convective & storm risk analysis",
        "ui_source": ui_storm,
    },
    {
        "filename": "05_screenshot_density.png",
        "glow_color": "#0369A1",
        "pill": "DEEP ATMOSPHERE",
        "title": "HIGH-DENSITY METRICS",
        "subtitle": "Barometric pressure, dew point & wind tracking",
        "ui_source": ui_density,
    },
]

PHONE_W = 860
PHONE_H = 1780
BEZEL = 14
CORNER = 42

SCREEN_W = PHONE_W - (BEZEL * 2) # 832
SCREEN_H = PHONE_H - (BEZEL * 2) # 1752

def compose_premium_screenshot(cfg):
    out_file = os.path.join(OUTPUT_DIR, cfg["filename"])
    glow_col = cfg["glow_color"]
    pill_txt = cfg["pill"]
    title_txt = cfg["title"]
    sub_txt = cfg["subtitle"]
    ui_src = cfg["ui_source"]

    print(f"Rendering {cfg['filename']}...")

    # A. Scale and crop UI content to exact SCREEN_W x SCREEN_H
    cropped_screen = f"/tmp/store_render/screen_{cfg['filename']}"
    subprocess.run([
        "magick", ui_src,
        "-resize", f"{SCREEN_W}x{SCREEN_H}^",
        "-gravity", "North",
        "-extent", f"{SCREEN_W}x{SCREEN_H}",
        cropped_screen
    ], check=True)

    # B. Add status bar mockup at top of screen (time 9:41, wifi, battery icons)
    screen_with_status = f"/tmp/store_render/status_{cfg['filename']}"
    subprocess.run([
        "magick", cropped_screen,
        "-font", FONT_SEMIBOLD,
        "-pointsize", "22",
        "-fill", "#E2E8F0",
        "-gravity", "NorthWest",
        "-annotate", "+40+18", "9:41",
        "-gravity", "NorthEast",
        "-annotate", "+40+18", "5G  ● 98%",
        screen_with_status
    ], check=True)

    # C. Build rounded screen mask
    masked_screen = f"/tmp/store_render/masked_{cfg['filename']}"
    subprocess.run([
        "magick",
        "-size", f"{SCREEN_W}x{SCREEN_H}",
        "xc:black",
        "-fill", "white",
        "-draw", f"roundrectangle 0,0 {SCREEN_W},{SCREEN_H} {CORNER-8},{CORNER-8}",
        f"/tmp/store_render/mask_{cfg['filename']}"
    ], check=True)

    subprocess.run([
        "magick", screen_with_status,
        f"/tmp/store_render/mask_{cfg['filename']}",
        "-alpha", "off", "-compose", "CopyOpacity", "-composite",
        masked_screen
    ], check=True)

    # D. Build phone body with titanium border & punch hole camera
    phone_chassis = f"/tmp/store_render/chassis_{cfg['filename']}"
    subprocess.run([
        "magick",
        "-size", f"{PHONE_W}x{PHONE_H}",
        "xc:transparent",
        # Outer shell
        "-fill", "#111A26",
        "-stroke", "#28394E",
        "-strokewidth", "3",
        "-draw", f"roundrectangle 2,2 {PHONE_W-2},{PHONE_H-2} {CORNER},{CORNER}",
        # Punch hole camera pill
        "-stroke", "none",
        "-fill", "#05090F",
        "-draw", f"roundrectangle {PHONE_W//2 - 40},10 {PHONE_W//2 + 40},32 11,11",
        # Camera lens reflection
        "-fill", "#1E2C3D",
        "-draw", f"circle {PHONE_W//2 - 16},21 {PHONE_W//2 - 13},21",
        phone_chassis
    ], check=True)

    # E. Combine chassis with screen
    assembled_phone = f"/tmp/store_render/phone_{cfg['filename']}"
    subprocess.run([
        "magick", phone_chassis,
        masked_screen,
        "-gravity", "Center",
        "-compose", "Over",
        "-composite",
        # Bottom gesture nav bar
        "-stroke", "none",
        "-fill", "#4A5D75",
        "-draw", f"roundrectangle {PHONE_W//2 - 75},{PHONE_H - 18} {PHONE_W//2 + 75},{PHONE_H - 13} 2.5,2.5",
        assembled_phone
    ], check=True)

    # F. Add soft deep drop shadow behind assembled phone
    phone_with_shadow = f"/tmp/store_render/shadow_{cfg['filename']}"
    subprocess.run([
        "magick", assembled_phone,
        "(", "+clone", "-background", "black", "-shadow", "85x30+0+28", ")",
        "+swap",
        "-background", "none",
        "-layers", "merge", "+repage",
        phone_with_shadow
    ], check=True)

    # G. Build Background with ambient colored backlight glow
    bg_canvas = f"/tmp/store_render/bg_{cfg['filename']}"
    subprocess.run([
        "magick",
        "-size", "1080x2400",
        "gradient:#0A121D-#04070B",
        # Ambient color glow spotlight behind the phone
        "(",
        "-size", "960x960",
        f"radial-gradient:{glow_col}33-transparent",
        ")",
        "-gravity", "Center",
        "-geometry", "+0+150",
        "-composite",
        bg_canvas
    ], check=True)

    # H. Render Badge Pill
    pill_img = f"/tmp/store_render/pill_{cfg['filename']}"
    subprocess.run([
        "magick",
        "-size", "400x56",
        "xc:transparent",
        "-fill", "#0E1C2C",
        "-stroke", "#223E5E",
        "-strokewidth", "1.5",
        "-draw", "roundrectangle 2,2 398,54 26,26",
        "-font", FONT_BOLD,
        "-pointsize", "22",
        "-fill", "#38BDF8",
        "-stroke", "none",
        "-gravity", "Center",
        "-annotate", "+0+0", f"  {pill_txt}  ",
        pill_img
    ], check=True)

    # I. Final Composition
    subprocess.run([
        "magick", bg_canvas,
        # Badge Pill
        pill_img,
        "-gravity", "North",
        "-geometry", "+0+95",
        "-composite",
        # Title
        "-font", FONT_BOLD,
        "-pointsize", "72",
        "-fill", "#F8FAFC",
        "-gravity", "North",
        "-annotate", "+0+175", title_txt,
        # Subtitle
        "-font", FONT_MEDIUM,
        "-pointsize", "34",
        "-fill", "#94A3B8",
        "-gravity", "North",
        "-annotate", "+0+268", sub_txt,
        # Phone with shadow
        phone_with_shadow,
        "-gravity", "North",
        "-geometry", "+0+385",
        "-composite",
        "-strip",
        "-depth", "8",
        out_file
    ], check=True)

    print(f"✅ Finished: {out_file}")

for screen in screens:
    compose_premium_screenshot(screen)

print("🎉 All premium store screenshots successfully generated!")
