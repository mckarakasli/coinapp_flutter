import time
import threading
import requests
import pytz
from datetime import datetime
from typing import List, Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import mysql.connector
import logging

app = FastAPI()

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

db_config = {
    "host": "127.0.0.1",
    "user": "admin",
    "password": "Mcka199090@@",
    "database": "coinapp"
}

class CloseTradeRequest(BaseModel):
    trade_id: int
    closed_price: float

class CoinTransaction(BaseModel):
    id: int
    symbol: str
    user_id: int
    entry_price: float
    target_price: float
    stop_loss: Optional[float] = 0
    status: int
    direction: Optional[str] = "up"
    closed_price: Optional[float] = None
    rate: Optional[float] = None
    closed_time: Optional[datetime] = None
    created_at: Optional[datetime] = None
    username: Optional[str] = "Bilinmiyor"
    binance_price: Optional[float] = None
    trade_id: Optional[int] = None
    userstop: Optional[int] = 0
    comment: Optional[dict] = None

    class Config:
        from_attributes = True

def get_db_connection():
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as err:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantısı hatası")

def get_binance_price(symbol: str):
    full_symbol = f"{symbol.upper()}USDT"
    url = f"https://api.binance.com/api/v3/ticker/price?symbol={full_symbol}"
    try:
        response = requests.get(url)
        data = response.json()
        return float(data['price']) if 'price' in data else None
    except:
        return None

def background_task():
    while True:
        try:
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT * FROM trades WHERE status != 0")
            trades = cursor.fetchall()
            for trade in trades:
                symbol = trade['symbol']
                entry_price = trade['entry_price']
                direction = trade.get('direction', 'up')
                binance_price = get_binance_price(symbol)
                if binance_price and entry_price:
                    rate = ((binance_price - entry_price) / entry_price) * 100 if direction=="up" else ((entry_price - binance_price)/entry_price)*100
                    print(f"{symbol} canlı rate: %{round(rate,2)}")
            cursor.close(); conn.close()
        except Exception as e:
            print(f"Arka plan hatası: {e}")
        time.sleep(2)

@app.on_event("startup")
def start_background_thread():
    thread = threading.Thread(target=background_task, daemon=True)
    thread.start()

@app.get("/trade_list/", response_model=List[CoinTransaction])
async def get_coin_transactions(skip: int = 0, limit: int = 10):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    logging.basicConfig(filename='service.log', level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
    turkey_tz = pytz.timezone("Europe/Istanbul")

    try:
        cursor.execute("SELECT * FROM trades LIMIT %s OFFSET %s", (limit, skip))
        transactions = cursor.fetchall()

        for transaction in transactions:
            trade_id = transaction['id']
            symbol = transaction['symbol']
            user_id = transaction['user_id']
            direction = transaction.get('direction', 'up')
            entry_price = transaction['entry_price']
            target_price = transaction.get('target_price', 0)
            stop_loss = transaction.get('stop_loss', 0)
            status = transaction.get('status', 1)

            cursor.execute("SELECT username FROM users WHERE id = %s", (user_id,))
            user = cursor.fetchone()
            transaction['username'] = user['username'] if user and user.get('username') else "Bilinmiyor"

            # Tek yorum varsa LIMIT 1 ile çekiyoruz
            cursor.execute("SELECT * FROM comments WHERE trade_id = %s LIMIT 1", (trade_id,))
            comment = cursor.fetchone()
            transaction['comment'] = comment if comment else None

            if status != 0:
                binance_price = get_binance_price(symbol)
                transaction['binance_price'] = binance_price
                if binance_price and entry_price:
                    rate = ((binance_price - entry_price)/entry_price)*100 if direction=="up" else ((entry_price - binance_price)/entry_price)*100
                    transaction['rate'] = round(rate,2)
                else:
                    transaction['rate'] = None

                if direction=="up" and binance_price >= target_price:
                    close_rate = ((target_price - entry_price)/entry_price)*100
                    closed_time = datetime.now(tz=turkey_tz).strftime("%Y-%m-%d %H:%M:%S")
                    cursor.execute(
                        "UPDATE trades SET closed_price=%s, result=%s, status=%s, rate=%s, closed_time=%s WHERE id=%s",
                        (target_price, target_price-entry_price, 0, round(close_rate,2), closed_time, trade_id)
                    )
                    conn.commit()
                    transaction.update({'status':0, 'closed_price':target_price, 'rate':round(close_rate,2), 'closed_time':closed_time})

                elif direction=="down" and binance_price <= target_price:
                    close_rate = ((entry_price - target_price)/entry_price)*100
                    closed_time = datetime.now(tz=turkey_tz).strftime("%Y-%m-%d %H:%M:%S")
                    cursor.execute(
                        "UPDATE trades SET closed_price=%s, result=%s, status=%s, rate=%s, closed_time=%s WHERE id=%s",
                        (target_price, entry_price-target_price, 0, round(close_rate,2), closed_time, trade_id)
                    )
                    conn.commit()
                    transaction.update({'status':0, 'closed_price':target_price, 'rate':round(close_rate,2), 'closed_time':closed_time})

                elif stop_loss and ((direction=="up" and binance_price <= stop_loss) or (direction=="down" and binance_price >= stop_loss)):
                    stop_result = stop_loss-entry_price if direction=="up" else entry_price-stop_loss
                    stop_rate = (stop_result/entry_price)*100
                    closed_time = datetime.now(tz=turkey_tz).strftime("%Y-%m-%d %H:%M:%S")
                    cursor.execute(
                        "UPDATE trades SET closed_price=%s, result=%s, status=%s, rate=%s, closed_time=%s, userstop=1 WHERE id=%s",
                        (stop_loss, stop_result, 0, round(stop_rate,2), closed_time, trade_id)
                    )
                    conn.commit()
                    transaction.update({'status':0, 'closed_price':stop_loss, 'rate':round(stop_rate,2), 'closed_time':closed_time, 'userstop':1})
            else:
                transaction['binance_price'] = transaction.get('closed_price')
                transaction['rate'] = round(transaction.get('rate',0),2)

            transaction['trade_id'] = trade_id
            transaction['stop_loss'] = stop_loss

        return transactions

    except mysql.connector.Error as err:
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        cursor.close()
        conn.close()

@app.post("/close_trade/")
async def close_trade(data: CloseTradeRequest):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    turkey_tz = pytz.timezone("Europe/Istanbul")
    closed_time = datetime.now(tz=turkey_tz).strftime("%Y-%m-%d %H:%M:%S")
    try:
        cursor.execute("SELECT * FROM trades WHERE id = %s", (data.trade_id,))
        trade = cursor.fetchone()
        if not trade:
            raise HTTPException(status_code=404, detail="Trade bulunamadı.")
        if trade['status'] == 0:
            raise HTTPException(status_code=400, detail="Trade zaten kapalı.")
        entry_price = trade['entry_price']
        if entry_price == 0:
            raise HTTPException(status_code=400, detail="Geçersiz giriş fiyatı.")
        rate = ((data.closed_price - entry_price)/entry_price)*100
        cursor.execute(
            "UPDATE trades SET userclosed=1, closed_price=%s, closed_time=%s, rate=%s, status=0 WHERE id=%s",
            (data.closed_price, closed_time, round(rate,2), data.trade_id)
        )
        conn.commit()
        return {"detail": "İşlem başarıyla kapatıldı."}
    except mysql.connector.Error as err:
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        cursor.close()
        conn.close()

@app.get("/top_trades/", response_model=List[dict])
async def get_top_trades(skip: int = 0, limit: int = 10):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT t.*, u.username FROM trades t
            LEFT JOIN users u ON t.user_id = u.id
            WHERE t.status = 1
            ORDER BY t.rate DESC
            LIMIT %s OFFSET %s
        """, (limit, skip))
        transactions = cursor.fetchall()
        for transaction in transactions:
            trade_id = transaction['id']
            symbol = transaction['symbol']
            direction = transaction.get('direction', 'up')
            entry_price = transaction['entry_price']
            target_price = transaction.get('target_price', 0)
            stop_loss = transaction.get('stop_loss', 0)
            binance_price = get_binance_price(symbol)
            if transaction.get('status', 1) != 0 and binance_price and entry_price:
                rate = ((binance_price - entry_price)/entry_price)*100 if direction=="up" else ((entry_price - binance_price)/entry_price)*100
                transaction['rate'] = round(rate,2)
                transaction['binance_price'] = binance_price
            else:
                transaction['binance_price'] = transaction.get('closed_price')
                transaction['rate'] = round(transaction.get('rate',0),2)
            transaction['trade_id'] = trade_id
            transaction['stop_loss'] = stop_loss
        return transactions
    except mysql.connector.Error as err:
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        cursor.close()
        conn.close()
