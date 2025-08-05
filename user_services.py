from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import mysql.connector
import bcrypt
import jwt
import datetime
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
import logging
from fastapi import APIRouter
from typing import List

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


app = FastAPI()
router = APIRouter()
# CORS Middleware (gerekliyse Flutter için)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Güvenlik için domain belirtebilirsin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# JWT secret
SECRET_KEY = "your_secret_key"

# Kullanıcı veri modeli
class User(BaseModel):
    username: Optional[str] = None  # Opsiyonel hale geldi
    email: str
    password: str

# Veritabanı bağlantı fonksiyonu
def get_db_connection():
    return mysql.connector.connect(
        host="127.0.0.1",
        user="admin",
        password="Mcka199090@@",
        database="coinapp"
    )

# ✅ Kayıt işlemi
@app.post("/register")
async def register(user: User):
    conn = get_db_connection()
    cursor = conn.cursor()

    # Aynı email var mı kontrol et
    cursor.execute("SELECT * FROM users WHERE email = %s", (user.email,))
    existing = cursor.fetchone()
    if existing:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=400, detail="Email already registered")

    # Şifreyi hashle
    hashed_pw = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    # Kaydı yap
    cursor.execute(
        "INSERT INTO users (username, email, password) VALUES (%s, %s, %s)",
        (user.username, user.email, hashed_pw)
    )
    conn.commit()

    # Yeni oluşturulan kullanıcının ID'sini al
    user_id = cursor.lastrowid

    cursor.close()
    conn.close()

    # Kullanıcı bilgilerini döndür
    return {
        "user_id": user_id,
        "username": user.username,
        "email": user.email,
        "message": "User registered successfully"
    }

@app.post("/login")
async def login(user: User):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM users WHERE email = %s", (user.email,))
    db_user = cursor.fetchone()

    if not db_user:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid email or password")

    hashed_password = db_user[3]  # Bu string, veritabanına decode edilmiş haliyle kaydedilmiş olmalı

    # Hash formatı uygun mu kontrol et
    if not hashed_password or not hashed_password.startswith("$2b$"):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=500, detail="Invalid password format in DB")

    # Şifreyi kontrol et
    if not bcrypt.checkpw(user.password.encode('utf-8'), hashed_password.encode('utf-8')):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # JWT token oluştur
    payload = {
        "user_id": db_user[0],
        "username" : db_user[1],
        "email": db_user[2],
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

    cursor.close()
    conn.close()

    # Log ile terminale yazdırma
    logger.info(f"Login successful! Token: {token}, User ID: {db_user[0]}, Username: {db_user[1]}, Email: {db_user[2]}")

    # API yanıtı olarak döndür
    return {"token": token, "user_id": db_user[0], "username": db_user[1], "email": db_user[2]}

class UserTradeSummary(BaseModel):
    user_id: int
    username: str
    total_rate: float

@router.get("/user_rate_summaries/", response_model=List[UserTradeSummary])
async def user_rate_summaries():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        query = """
            SELECT u.id as user_id, u.username, SUM(t.rate) as total_rate
            FROM users u
            LEFT JOIN trades t ON u.id = t.user_id AND t.rate IS NOT NULL
            GROUP BY u.id, u.username
            ORDER BY total_rate DESC
        """
        cursor.execute(query)
        results = cursor.fetchall()

        for r in results:
            if r['total_rate'] is None:
                r['total_rate'] = 0.0

        response = [
            UserTradeSummary(
                user_id=r['user_id'],
                username=r['username'],
                total_rate=float(r['total_rate'])
            )
            for r in results
        ]

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        cursor.close()
        conn.close()