
import zipfile, plistlib, struct, io, sys
p = r"F:\MyApp\eternal\artifacts\ipa\DailyCultivation-unsigned.ipa"
z = zipfile.ZipFile(p)
names = z.namelist()
print("entries:", len(names))
print("app dir:", [n for n in names if n.endswith(".app/")][:2])
info_name = [n for n in names if n.endswith(".app/Info.plist")][0]
info = plistlib.loads(z.read(info_name))
print("bundle id:", info.get("CFBundleIdentifier"))
print("display name:", info.get("CFBundleDisplayName"))
print("min iOS:", info.get("MinimumOSVersion"))
print("camera desc:", (info.get("NSCameraUsageDescription") or "")[:20], "...")
exe = [n for n in names if n.endswith("/DailyCultivation")][0]
data = z.read(exe)
magic = struct.unpack(">I", data[:4])[0]
print("exe MB:", round(len(data)/1024/1024, 1), "magic:", hex(magic))
# fat binary magic cafebabe; thin arm64 = 0x0100000c little endian
print("arch hint:", "fat" if magic == 0xCAFEBABE else ("arm64" if magic == 0x0C000001 or magic == 0x0100000C else "other"))
