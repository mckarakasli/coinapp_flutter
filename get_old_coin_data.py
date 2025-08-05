from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import requests
import pandas as pd
import json
import os
import threading
import time

app = FastAPI()

# CORS ayarları (istersen kaldırabilirsin)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Binance verisi çekme
def fetch_klines(symbol, interval, limit=200):
    url = "https://api.binance.com/api/v3/klines"
    params = {
        "symbol": symbol,
        "interval": interval,
        "limit": limit
    }
    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()
    data = response.json()
    df = pd.DataFrame(data, columns=[
        "open_time", "open", "high", "low", "close", "volume",
        "close_time", "quote_asset_volume", "number_of_trades",
        "taker_buy_base_asset_volume", "taker_buy_quote_asset_volume", "ignore"
    ])
    df["close"] = df["close"].astype(float)
    return df

# EMA hesapla
def calculate_emas(df):
    df["EMA20"] = df["close"].ewm(span=20, adjust=False).mean()
    df["EMA50"] = df["close"].ewm(span=50, adjust=False).mean()
    df["EMA100"] = df["close"].ewm(span=100, adjust=False).mean()
    df["EMA200"] = df["close"].ewm(span=200, adjust=False).mean()
    return df

def calculate_rsi(df, period=14):
    delta = df["close"].diff()
    gain = delta.where(delta > 0, 0)
    loss = -delta.where(delta < 0, 0)
    
    avg_gain = gain.rolling(window=period, min_periods=period).mean()
    avg_loss = loss.rolling(window=period, min_periods=period).mean()
    
    rs = avg_gain / avg_loss
    rsi = 100 - (100 / (1 + rs))
    df["RSI"] = rsi
    return df

def check_rsi_signal(df):
    last = df.iloc[-1]
    rsi = last["RSI"]
    if pd.isna(rsi):
        return {"signal": "Bilinmiyor", "value": None}
    signal = "AL" if rsi < 30 else "SAT" if rsi > 70 else "Nötr"
    return {"signal": signal, "value": round(rsi, 2)}
def calculate_macd(df, fast=12, slow=26, signal=9):
    ema_fast = df["close"].ewm(span=fast, adjust=False).mean()
    ema_slow = df["close"].ewm(span=slow, adjust=False).mean()
    macd_line = ema_fast - ema_slow
    signal_line = macd_line.ewm(span=signal, adjust=False).mean()
    histogram = macd_line - signal_line
    df["MACD"] = macd_line
    df["MACD_signal"] = signal_line
    df["MACD_histogram"] = histogram
    return df

def check_macd_signal(df):
    if len(df) < 2:
        return "Nötr"
    prev_macd = df.iloc[-2]["MACD"]
    prev_signal = df.iloc[-2]["MACD_signal"]
    curr_macd = df.iloc[-1]["MACD"]
    curr_signal = df.iloc[-1]["MACD_signal"]

    if prev_macd < prev_signal and curr_macd > curr_signal:
        return "AL"
    elif prev_macd > prev_signal and curr_macd < curr_signal:
        return "SAT"
    else:
        return "Nötr"
# EMA sinyali üret
def check_ema_signals(df):
    last = df.iloc[-1]
    close = last["close"]
    signals = {}
    for ema in ["EMA20", "EMA50", "EMA100", "EMA200"]:
        signals[ema] = {
            "signal": "AL" if close > last[ema] else "SAT",
            "price": round(last[ema], 6)
        }
    return signals

# Coin listesini yükle
def load_symbols():
    file_path = os.path.join(os.path.dirname(__file__), "coin_symbols.json")
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data["symbols"]
    except Exception as e:
        print(f"coin_symbols.json okunamadı: {e}")
        return []

# signals_ema.json'a veri kaydet
def update_signals_file():
    symbols = load_symbols()
    intervals = ["15m", "1h", "4h", "1d"]
    results = {}
    errors = []

    for symbol in symbols:
        symbol_signals = {}
        try:
            for interval in intervals:
                df = fetch_klines(symbol, interval)
                df = calculate_emas(df)
                df = calculate_macd(df)
                df = calculate_rsi(df)  # RSI hesapla

                ema_signals = check_ema_signals(df)
                macd_signal = check_macd_signal(df)
                rsi_signal = check_rsi_signal(df)  # RSI sinyalini hesapla

                symbol_signals[interval] = {
                    "ema": ema_signals,
                    "macd": macd_signal,
                    "rsi": rsi_signal,   # RSI'yı ekle
                }
            results[symbol] = symbol_signals
        except Exception:
            errors.append(symbol)

    data = {
        "results": results,
        "errors": errors,
        "updated_at": int(time.time())
    }

    with open("signals_ema.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
# Arka planda 15 dakikada bir güncelleme yapan thread
def background_updater():
    # Hemen başta ilk kez güncelleme yap
    print("[INFO] İlk EMA verisi güncelleniyor...")
    try:
        update_signals_file()
        print("[INFO] İlk veri kaydedildi.")
    except Exception as e:
        print(f"[ERROR] İlk güncelleme hatası: {e}")
    
    # Sonra 15 dakikada bir devam et
    while True:
        print("[INFO] EMA verileri güncelleniyor...")
        try:
            update_signals_file()
            print("[INFO] Güncelleme tamamlandı.")
        except Exception as e:
            print(f"[ERROR] Güncelleme sırasında hata: {e}")
        time.sleep(15 * 60)  # 15 dakika

# Thread'i başlat
threading.Thread(target=background_updater, daemon=True).start()

# API sadece json dosyasını okur
@app.get("/signals")
def get_signals():
    try:
        with open("signals_ema.json", "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        return {"error": f"signals_ema.json okunamadı: {e}"}
