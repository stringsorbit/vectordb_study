#!/usr/bin/env bash
set -e

# 스크립트 실행 위치와 무관하게 프로젝트 루트 디렉터리로 이동
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=========================================================="
echo " [제6장] SQLite VSS & Ollama 로컬 RAG 실습 (Mac/Linux)"
echo "=========================================================="

# 1. Ollama 컨테이너 시작
echo "1. Ollama 컨테이너 기동 중..."
docker compose up -d ollama

# 2. Ollama 준비 대기
echo "2. Ollama 서비스 헬스체크..."
until curl -s http://localhost:11434/api/tags > /dev/null; do
    echo "   Ollama 준비 대기 중..."
    sleep 2
done

# 3. 모델 확인 및 사전 pull
MODEL="llama3.1:8b"
echo "3. Ollama 모델 확인 ($MODEL)..."
if docker exec ollama ollama list | grep -q "$MODEL"; then
    echo "   ✓ 모델이 이미 준비되어 있습니다."
else
    echo "   ⚠️ 모델이 없습니다. 다운로드를 시작합니다 (약 4.9GB)..."
    docker exec -it ollama ollama pull "$MODEL"
fi

# 4. 실습 앱 빌드
echo "4. RAG 실습 컨테이너 빌드 중..."
docker compose build rag-app

# 5. 대화형 질의응답 실행
echo "=========================================================="
echo " 🚀 책 원본 RAG 애플리케이션 실행 (종료하려면 'quit' 입력)"
echo "=========================================================="
docker compose run --rm rag-app
