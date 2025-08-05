# -*- coding: utf-8 -*-
import os
import json
import requests
from PIL import Image
from io import BytesIO
from tqdm import tqdm

# Klasörleri oluştur
os.makedirs("images", exist_ok=True)

# Coingecko'dan ilk 100 coin verisi
url = "https://api.coingecko.com/api/v3/coins/markets"
params = {
    "vs_currency": "usd",
    "order": "market_cap_desc",
    "per_page": 100,
    "page": 1,
    "sparkline": False
}

response = requests.get(url, params=params)
coins = response.json()

# Kaydedilecek coin verileri için liste
coins_data = []

# Her coin için isim, sembol, görsel al ve kaydet
for coin in tqdm(coins, desc="Coinler indiriliyor"):
    name = coin['name']
    symbol = (coin['symbol'] + 'usdt').upper()  # BÜYÜK HARF: BTCUSDT
    image_url = coin['image']

    # Coin bilgisini kaydetmek için dict
    coins_data.append({
        "name": name,
        "symbol": symbol
    })

    try:
        img_response = requests.get(image_url)
        img = Image.open(BytesIO(img_response.content)).convert("RGBA")

        img_path = os.path.join("images", f"{symbol}.png")
        img.save(img_path)

    except Exception as e:
        print(f"{symbol} resmi indirilemedi: {e}")

# coinler.json dosyasına yaz
with open("coinler.json", "w", encoding="utf-8") as f:
    json.dump(coins_data, f, ensure_ascii=False, indent=2)

print("Coin bilgileri ve resimler başarıyla kaydedildi.")
