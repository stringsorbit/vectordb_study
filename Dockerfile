FROM python:3.11-slim

WORKDIR /app

# PyTorch 및 C 확장 모듈 실행에 필요한 필수 라이브러리 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    libgomp1 \
    libblas3 \
    liblapack3 \
    && rm -rf /var/lib/apt/lists/*

# 파이썬 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# sqlite-vss 라이브러리 내부의 vector0.so, vss0.so 바이너리를 /app 에 복사 및 링크 생성
# 책의 원본 코드인 conn.load_extension("./vector0"), conn.load_extension("./vss0") 가 무수정으로 동작하도록 함
RUN python -c "import sqlite_vss, shutil, os, glob; \
    src_dir = os.path.dirname(sqlite_vss.__file__); \
    [shutil.copy(f, '/app/' + os.path.basename(f)) for f in glob.glob(os.path.join(src_dir, '*.*')) if f.endswith(('.so', '.dylib'))]" && \
    ln -sf /app/vector0.so /app/vector0 2>/dev/null || true && \
    ln -sf /app/vss0.so /app/vss0 2>/dev/null || true

# 책의 원본 애플리케이션 코드 복사
COPY app.py .

CMD ["python", "app.py"]
