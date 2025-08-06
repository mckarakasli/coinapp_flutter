import time
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
import mysql.connector
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
from datetime import datetime
import pytz
import threading
import requests
from mysql.connector import Error


# FastAPI uygulaması başlatılıyor
app = FastAPI()

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tüm domainlere izin veriyoruz
    allow_credentials=True,
    allow_methods=["*"],  # Tüm HTTP methodlarına izin ver
    allow_headers=["*"],  # Tüm header'lara izin ver
)

# MySQL veritabanı bağlantı bilgileri
db_config = {
    "host": "127.0.0.1",
    "user": "admin",  # Veritabanı kullanıcı adı
    "password": "Mcka199090@@",  # Veritabanı şifresi
    "database": "coinapp"  # Veritabanı adı
}

# Türkiye saati ayarı
turkey_tz = pytz.timezone("Europe/Istanbul")


class CoinTransaction(BaseModel):
    user_id: int
    symbol: str
    entry_price: float
    target_price: float
    stop_loss: float
    status: int
    rate: Optional[float] = None
    direction: str
    closed_price: Optional[float] = None
    result: Optional[float] = None
    binance_price: Optional[float] = None  # Binance fiyatı

    class Config:
        from_attributes = True  # Eski orm_mode'ın yerine kullanılacak

# Veritabanı bağlantısını sağlayan fonksiyon
def get_db_connection():
    try:
        conn = mysql.connector.connect(**db_config)
        print("Veritabanı bağlantısı başarılı.")
        return conn
    except mysql.connector.Error as err:
        print(f"Veritabanı bağlantısı hatası: {err}")
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı hatası")

# UTC zamanını al
def get_utc_now():
    utc_now = datetime.now(pytz.utc)  # UTC saatini al
    return utc_now


@app.post("/create_trade")
async def create_coin_transaction(transaction: CoinTransaction):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Türkiye saati ile zaman al
        created_at = datetime.now(tz=turkey_tz).strftime("%Y-%m-%d %H:%M:%S")

        # Veriyi MySQL'e ekleme
        sql = """
        INSERT INTO trades (user_id, status, symbol, entry_price, stop_loss, target_price, rate, direction, closed_price, result, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s ,%s, %s)
        """
        cursor.execute(sql, (
            transaction.user_id,
            transaction.status,
            transaction.symbol,
            transaction.entry_price,
            transaction.stop_loss,
            transaction.target_price,
            transaction.rate,
            transaction.direction,
            transaction.closed_price,
            transaction.result,
            created_at  # Yeni eklenen tarih
        ))

        conn.commit()

        transaction_id = cursor.lastrowid
        print(f"Yeni işlem başarıyla eklendi. ID: {transaction_id}")
        return {
            "id": transaction_id,
            "user_id": transaction.user_id,
            "status": transaction.status,
            "symbol": transaction.symbol,
            "entry_price": transaction.entry_price,
            "stop_loss": transaction.stop_loss,
            "target_price": transaction.target_price,
            "rate": transaction.rate,
            "direction": transaction.direction,
            "result": transaction.result,
            "created_at": created_at,  # Dönüşte eklenen tarih
        }

    except mysql.connector.Error as err:
        print(f"Veritabanı hatası: {err}")
        return {"error": str(err)}

    finally:
        cursor.close()
        conn.close()

class CommentData(BaseModel):
    user_id: int
    trade_id: int
    comment: str

# Trade modeli
class TradeData(BaseModel):
    trade_id: int
    closed_price: float
@app.post("/add_comment")
async def add_comment(data: CommentData):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        created_at = datetime.now(tz=turkey_tz).strftime("%Y-%m-%d %H:%M:%S")

        sql = """
        INSERT INTO comments (user_id, trade_id, comment, created_at)
        VALUES (%s, %s, %s, %s)
        """
        cursor.execute(sql, (data.user_id, data.trade_id, data.comment, created_at))
        conn.commit()

        comment_id = cursor.lastrowid
        return {
            "comment_id": comment_id,
            "user_id": data.user_id,
            "trade_id": data.trade_id,
            "comment": data.comment,
            "created_at": created_at
        }

    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {e}")

    finally:
        cursor.close()
        conn.close()

@app.post("/close_trade/")
async def close_trade(data: TradeData):
    trade_id = data.trade_id
    closed_price = data.closed_price

    print(f"Gelen trade_id: {trade_id}")
    print(f"Gelen closed_price: {closed_price}")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # İşlem bilgilerini al
        sql = "SELECT * FROM trades WHERE id = %s"
        cursor.execute(sql, (trade_id,))
        transaction = cursor.fetchone()

        if not transaction:
            print(f"İşlem {trade_id} bulunamadı.")
            raise HTTPException(status_code=404, detail=f"İşlem {trade_id} bulunamadı.")

        # Hesaplama
        updated_status = 0  # Kapalı
        entry_price = transaction['entry_price']
        direction = transaction['direction']

        result = (closed_price - entry_price) if direction == 'up' else (entry_price - closed_price)
        rate = ((closed_price - entry_price) / entry_price) * 100 if direction == 'up' else ((entry_price - closed_price) / entry_price) * 100

        # Türkiye saati ile kapanış zamanı al
        closed_time = datetime.now(tz=turkey_tz).strftime("%Y-%m-%d %H:%M:%S")

        # Veritabanını güncelle
        update_sql = """
        UPDATE trades SET closed_price = %s, result = %s, status = %s, rate = %s, closed_time = %s WHERE id = %s
        """
        cursor.execute(update_sql, (closed_price, result, updated_status, round(rate, 2), closed_time, trade_id))
        conn.commit()

        return {"message": "İşlem başarıyla kapatıldı", "trade_id": trade_id}

    except mysql.connector.Error as err:
        print(f"Veritabanı hatası: {err}")
        raise HTTPException(status_code=500, detail=f"Veritabanı hatası: {err}")
    except Exception as e:
        print(f"Genel hata: {e}")
        raise HTTPException(status_code=500, detail=f"Beklenmeyen hata: {str(e)}")

    finally:
        cursor.close()
        conn.close()