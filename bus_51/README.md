# Bus_unjewa (언제와?)

**한국 버스 도착 정보 앱** - "버스 언제와?"

실시간 GPS 위치 기반으로 주변 버스 정류장과 도착 정보를 제공하는 Flutter 앱입니다.

## 🚀 빠른 시작

### 1. 의존성 설치
```bash
make get
```

### 2. 코드 생성 (중요!)
```bash
make generate
```

### 3. 앱 실행
```bash
make run
```

## 💻 개발 명령어

```bash
make help          # 명령어 목록
make get           # 의존성 설치
make generate      # Freezed 코드 생성
make watch         # 자동 감시 모드 (권장)
make clean         # 캐시 정리
make run           # 앱 실행
make build         # APK 빌드
```

## ⚠️ 주의사항

### 모델 변경 후 필수!
```bash
# 데이터 모델(Entity/Model) 수정 후 반드시 실행
make generate
```

### 자동 감시 모드 (편함!)
```bash
# 별도 터미널에서 실행하면 파일 변경시 자동 재생성
make watch
```

### 절대 수정 금지
- `*.freezed.dart`, `*.g.dart` 파일들
- 이 파일들은 자동 생성되므로 직접 수정하면 안됨

## 🎨 주요 기능

- 🗺️ 실시간 GPS 기반 버스 정류장 검색
- 🚌 실시간 버스 도착 정보
- ⭐ 즐겨찾기 관리
- 🎨 한국 버스 색상 테마 (간선/지선/광역/급행)
- 🗺️ 네이버 지도 연동

## 🔧 기술 스택

- **Flutter 3.5.3** + **Material 3**
- **Freezed 3.0.6** - 불변 데이터 클래스
- **Provider** - 상태 관리
- **Dio** - HTTP 통신
- **네이버 지도** + **GPS**

## 🏗️ 아키텍처

**API → Entity → Mapper → Model → Provider → UI**

```
lib/
├── entity/     # API 원시 데이터 (Freezed)
├── mapper/     # 데이터 변환
├── model/      # 비즈니스 모델 (Freezed)
├── provider/   # 상태 관리
├── service/    # API & 저장소
└── screen/     # UI 화면
```

## 🔑 설정

### 네이버 지도 API
`lib/main.dart`에서 Client ID 설정 필요

### 버스 API
- Primary: `http://168.138.54.156:8000`
- Fallback: 정부 데이터포털 API

## 🆘 문제 해결

**코드 생성 충돌**
```bash
make generate  # 이거면 보통 해결됨
```

**캐시 문제**
```bash
make clean
make get
make generate
```
