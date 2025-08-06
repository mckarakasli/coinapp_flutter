import requests
import json

# CoinGecko API endpoint to get the list of the top 100 coins
url = "https://api.coingecko.com/api/v3/coins/markets"
params = {
    'vs_currency': 'usd',
    'order': 'market_cap_desc',
    'per_page': 100,
    'page': 1
}

# API'den veri çekme
response = requests.get(url, params=params)

# Veriyi JSON formatında al
coins = response.json()

# Coin'lerin sembollerini çekip 'USDT' ile birleştirme
symbols = [coin['symbol'].upper() + 'USDT' for coin in coins]

# JSON çıktısı oluşturma
json_output = {"symbols": symbols}

# JSON dosyasına kaydetme
try:
    with open("coin_symbols.json", "w") as file:
        json.dump(json_output, file, indent=4)
    print("coin_symbols.json dosyası başarıyla kaydedildi.")
except Exception as e:
    print(f"JSON dosyası kaydedilirken hata oluştu: {e}")
