import os
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel, EmailStr
import mysql.connector
import hashlib
from passlib.context import CryptContext
import jwt
from datetime import datetime, timedelta
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# .env dosyasını yükle
load_dotenv()

# FastAPI uygulaması oluştur
app = FastAPI()

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Geliştirme aşamasında tüm domainlere izin veriyoruz
    allow_credentials=True,
    allow_methods=["*"],  # Tüm HTTP methodlarına izin ver
    allow_headers=["*"],  # Tüm header'lara izin ver
)

# SECRET_KEY çevresel değişkenden alınır
SECRET_KEY = os.getenv("SECRET_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")

# Şifreleme aracı
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Veritabanı bağlantı bilgileri
db_config = {
    "host": "127.0.0.1",
    "user": "admin",
    "password": "Mcka199090@@",
    "database": "coinapp"
}

# Kullanıcı veri modeli
class User(BaseModel):
    username: str
    email: EmailStr
    password: str
    
class LoginUser(BaseModel):
    email: EmailStr
    password: str

# Şifreyi hash'le
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

# Şifreyi kontrol et
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# JWT token oluştur
def create_access_token(data: dict, expires_delta: timedelta = timedelta(hours=1)) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + expires_delta
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")
    return encoded_jwt

# Kullanıcı kaydı
@app.post("/register")
async def register_user(user: User):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        # Şifreyi hash'le
        hashed_pw = hash_password(user.password)

        # Kullanıcıyı ekle
        sql = "INSERT INTO users (username, email, password) VALUES (%s, %s, %s)"
        val = (user.username, user.email, hashed_pw)
        cursor.execute(sql, val)
        conn.commit()

        # Son eklenen kullanıcının ID'sini al
        user_id = cursor.lastrowid

        return {
            "id": user_id,
            "username": user.username,
            "email": user.email
        }

    except mysql.connector.Error as err:
        return {"error": str(err)}
    finally:
        cursor.close()
        conn.close()

# Kullanıcı girişi
@app.post("/login")
async def login_user(login: LoginUser):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)

        # Email'e göre kullanıcıyı bul
        sql = "SELECT id, username, password FROM users WHERE email = %s"
        cursor.execute(sql, (login.email,))
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=401, detail="Kullanıcı bulunamadı")

        # Şifreyi doğrula
        if not verify_password(login.password, user["password"]):
            raise HTTPException(status_code=401, detail="Şifre yanlış")

        # JWT token oluştur
        access_token = create_access_token(
            data={"sub": user["email"]}
        )

        return {
            "id": user["id"],
            "username": user["username"],
            "email": login.email,
            "access_token": access_token,
            "token_type": "bearer"
        }

    except mysql.connector.Error as err:
        return {"error": str(err)}
    finally:
        cursor.close()
        conn.close()

