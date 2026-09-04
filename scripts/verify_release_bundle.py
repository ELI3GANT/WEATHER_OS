import sys
import zipfile

def verify(aab_path):
    print(f"Verifying Android App Bundle: {aab_path}")
    with zipfile.ZipFile(aab_path, "r") as z:
        names = set(z.namelist())
        if "base/manifest/AndroidManifest.xml" not in names:
            print("❌ Error: base/manifest/AndroidManifest.xml not found in AAB", file=sys.stderr)
            sys.exit(1)
        if not any(n.startswith("base/dex/") for n in names):
            print("❌ Error: No DEX files found in AAB", file=sys.stderr)
            sys.exit(1)
        manifest_bytes = z.read("base/manifest/AndroidManifest.xml")
        if b"app.weatheros.app" not in manifest_bytes:
            print("❌ Error: Package app.weatheros.app not found in manifest", file=sys.stderr)
            sys.exit(1)

    print("✅ Release bundle verified: Valid AAB structure, DEX bytecode, and package app.weatheros.app confirmed.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: verify_release_bundle.py <path_to_aab>", file=sys.stderr)
        sys.exit(1)
    verify(sys.argv[1])
