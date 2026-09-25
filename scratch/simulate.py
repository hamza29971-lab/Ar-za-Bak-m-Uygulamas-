import urllib.request
import json

url = "https://mining-be.ndmo.com.tr/vehicle-events/"

dummy_jpeg_base64 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="

payload = {
    "title": "Servis Raporu",
    "type": "genel",
    "note": "Test Raporu",
    "vehicleUUID": "84a287d8-99c0-406f-b2d9-e94df59e2e2f",
    "operatorLabel": "Hamza Ünlü (95674DBC93)",
    "occurredAt": "2026-09-10T07:15:00Z",
    "source": "tablet",
    "fields": {
        "raporTuru": "Servis Raporu",
        "gorselSayisi": 1,
        "baslangicSaati": "08:30",
        "bitisSaati": "10:15",
        "gorseller": [dummy_jpeg_base64]
    }
}

headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer nimo-fleet-test-tablet-key",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}

req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        print("Status:", response.status)
        print("Body:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print("Body:", e.read().decode('utf-8'))
