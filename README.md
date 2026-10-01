# [제6장] SQLite VSS와 Ollama를 활용한 로컬 RAG 시스템 구축 실습

안녕하세요! 본 문서는 **"벡터 데이터베이스: 실용 입문" 6장** 스터디를 위한 실습 가이드입니다.  
책의 원본 예제 코드(`app.py`)를 단 1줄도 수정하지 않고, **macOS(MacBook) 및 Windows 환경 모두에서 완벽하게 동작**할 수 있도록 Docker 기반 원스톱 환경으로 구성했습니다.

---

## 💡 왜 Docker 기반으로 실습하나요?

로컬 환경(특히 Mac M시리즈나 Windows)에서 `sqlite-vss`와 딥러닝 패키지를 직접 설치하다 보면 다음과 같은 현실적인 문제들을 마주하게 됩니다:

1. **OS별 C 확장 라이브러리 차이**: `sqlite-vss`는 파이썬 순수 패키지가 아닌 C 확장 모듈(`vss0`, `vector0`)로 동작하며, 내부적으로 BLAS 선형대수 라이브러리(`libblas3`)를 요구합니다. Windows에서는 공식 컴파일 바이너리가 없고, macOS에서도 칩셋 아키텍처에 따른 빌드 이슈가 발생하기 쉽습니다.
2. **파이썬 버전 및 패키지 충돌**: PyTorch, SentenceTransformers 등의 의존 라이브러리는 최신 파이썬 버전과 호환성 문제가 생길 수 있습니다.
3. **스터디 시간 절약**: 1시간 30분의 짧은 스터디 시간에 각자의 환경 문제를 해결하느라 시간을 허비하지 않고, **RAG 아키텍처와 하이브리드 검색의 본질**에 온전히 집중하기 위해 Docker로 환경을 표준화했습니다.

---

## 📂 프로젝트 구조

```text
chapter06_docker/
├── app.py              # 책 원본 RAG 애플리케이션 (SQLite VSS + FTS5 + Ollama)
├── Dockerfile          # Python 3.11 및 sqlite-vss 바이너리 자동 구성 컨테이너 명세
├── docker-compose.yml  # Ollama LLM 서버와 RAG 앱 네트워크 통합 설정
├── requirements.txt    # 파이썬 의존 라이브러리 목록
├── scripts/
│   ├── run_study.sh    # macOS / Linux 전용 원클릭 자동 실행 스크립트
│   └── run_study.ps1   # Windows PowerShell 전용 원클릭 자동 실행 스크립트
└── README.md           # 실습 및 스터디 가이드 (본 문서)
```

---

## ⚡ 스터디 전날 준비사항 (필수!)

책의 기본 LLM인 `llama3.1:8b`는 용량이 약 **4.9GB**입니다.  
스터디 당일 현장(카페나 세미나실)의 Wi-Fi로 다운로드하면 오랜 시간이 소요되므로, **반드시 전날 집에서 미리 모델을 다운로드**해 주시기 바랍니다.

### 모델 사전 다운로드 방법 (터미널 공통)
```bash
# 1. Ollama 컨테이너 백그라운드 실행
docker run -d --name ollama -p 11434:11434 -v ollama_data:/root/.ollama ollama/ollama:latest

# 2. Llama 3.1 8B 모델 다운로드 (네트워크 환경에 따라 5~10분 소요)
docker exec -it ollama ollama pull llama3.1:8b
```

> **사양 팁**: 만약 노트북 여유 공간이나 메모리가 부족한 경우, 경량 모델인 `llama3.2:3b` (약 2GB) 또는 `llama3.2:1b` (약 1.3GB)를 다운로드하여 실습하셔도 무방합니다.

---

## 🚀 스터디 당일 원클릭 실행 방법

터미널을 열고 본 저장소 디렉터리로 이동한 후, OS에 맞는 스크립트를 실행하면 즉시 대화형 RAG 터미널로 진입합니다.

### 🍎 macOS / Linux 사용자
```bash
chmod +x scripts/run_study.sh
./scripts/run_study.sh
```

### 🪟 Windows 사용자 (PowerShell)
```powershell
.\scripts\run_study.ps1
```

*(스크립트가 자동으로 컨테이너 헬스체크 ➔ 모델 확인 ➔ 이미지 빌드 ➔ 대화형 질의응답 창까지 순차적으로 띄워줍니다.)*

---

## ⏱️ 1시간 30분 스터디 진행 타임테이블

| 시간 | 분 | 진행 주제 | 핵심 내용 |
| :---: | :---: | :--- | :--- |
| **Part 1** | 15분 | **6장 핵심 개념 리뷰** | • 로컬 RAG의 필요성 (보안, 비용 0원, 데이터 주권)<br>• 의미 기반 검색(SQLite VSS)과 키워드 검색(FTS5 BM25)의 원리 |
| **Part 2** | 35분 | **코드 분석 (`app.py`)** | • 6.1: VSS 가상 테이블(`chunk_vss`) 및 FTS5 스키마 설계<br>• 6.2: 슬라이딩 윈도우 청킹 & SentenceTransformers 임베딩<br>• 6.3: 하이브리드 점수 정규화 및 가중치 합산 알고리즘<br>• 6.4~6.5: Ollama 연동 및 환각 억제 프롬프트 구조 |
| **Part 3** | 30분 | **핸즈온 실험 & 토론** | • 아래의 3가지 실습 과제를 직접 수행하며 동작 차이 관찰 |
| **Part 4** | 10분 | **Q&A 및 마무리 회고** | • 대규모 데이터 확장 시 고려점 (PostgreSQL pgvector 전환 등) |

---

## 🧪 스터디 추천 실험 과제 (Hands-on)

### 과제 1. 하이브리드 검색 가중치 실험 (`app.py:170`)
기본 설정은 **의미 벡터 70% + 키워드 30%** (`semantic_weight=0.7`)로 융합되어 있습니다.
- `semantic_weight=1.0` (순수 벡터 검색): 동의어나 개념적 질문에는 강하지만 정확한 고유명사/약어 매칭에 어떤 차이가 생기나요?
- `semantic_weight=0.0` (순수 키워드 검색): 오타나 표현이 다른 질의에 대해 어떻게 반응하나요?

### 과제 2. 환각(Hallucination) 방어 지침 테스트
`app.py`의 시스템 프롬프트에는 **"제공된 문맥에 없는 내용은 모른다고 답할 것"**이라는 엄격한 규칙이 들어있습니다.
- DB에 없는 질문(예: *"Who won the 2026 World Cup?"*)을 질의해 보세요.
- LLM이 사전 지식을 활용해 그럴듯하게 답하는지, 지침대로 *"I do not know"*를 반환하는지 확인해 봅니다.

### 과제 3. 출처 인용(Citation) 메커니즘 확인
답변 생성 결과 끝에 `[Source 1]`, `[Source 2]`와 같이 인용 출처가 제대로 붙는지 확인하고, RAG 시스템에서 신뢰성을 담보하기 위해 출처 표기가 왜 중요한지 함께 토론해 봅니다.
