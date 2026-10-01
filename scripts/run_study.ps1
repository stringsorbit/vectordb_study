# [제6장] SQLite VSS & Ollama 로컬 RAG 실습 (Windows PowerShell)
$ErrorActionPreference = "Stop"

# 스크립트 실행 위치와 무관하게 프로젝트 루트 디렉터리로 이동
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$ScriptDir\.."

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [제6장] SQLite VSS & Ollama 로컬 RAG 실습 (Windows)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ollama 컨테이너 시작
Write-Host "1. Ollama 컨테이너 기동 중..." -ForegroundColor Yellow
docker compose up -d ollama

# 2. Ollama 헬스체크
Write-Host "2. Ollama 서비스 헬스체크..." -ForegroundColor Yellow
while ($true) {
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -ErrorAction Stop
        break
    } catch {
        Write-Host "   Ollama 준비 대기 중..."
        Start-Sleep -Seconds 2
    }
}

# 3. 모델 확인 및 사전 pull
$model = "llama3.1:8b"
Write-Host "3. Ollama 모델 확인 ($model)..." -ForegroundColor Yellow
$models = docker exec ollama ollama list
if ($models -match "llama3.1:8b") {
    Write-Host "   ✓ 모델이 이미 준비되어 있습니다." -ForegroundColor Green
} else {
    Write-Host "   ⚠️ 모델이 없습니다. 다운로드를 시작합니다 (약 4.9GB)..." -ForegroundColor Yellow
    docker exec -it ollama ollama pull $model
}

# 4. 실습 앱 빌드
Write-Host "4. RAG 실습 컨테이너 빌드 중..." -ForegroundColor Yellow
docker compose build rag-app

# 5. 대화형 질의응답 실행
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🚀 책 원본 RAG 애플리케이션 실행 (종료하려면 'quit' 입력)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
docker compose run --rm rag-app
