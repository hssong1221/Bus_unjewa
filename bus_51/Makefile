# 개인 프로젝트용 심플 Makefile

.PHONY: help get generate watch clean build run

# 도움말
help:
	@echo "Bus_51 개발 명령어:"
	@echo ""
	@echo "  make get        - 의존성 설치"
	@echo "  make generate   - 코드 생성"
	@echo "  make watch      - 자동 감시 모드"
	@echo "  make clean      - 캐시 정리"
	@echo "  make run        - 앱 실행"
	@echo "  make build      - APK 빌드"

# 의존성 설치
get:
	flutter pub get

# Freezed 코드 생성
generate:
	flutter packages pub run build_runner build --delete-conflicting-outputs

# 파일 변경 감지하여 자동 코드 생성
watch:
	flutter packages pub run build_runner watch

# 캐시 정리
clean:
	flutter packages pub run build_runner clean
	flutter clean

# 앱 실행
run:
	flutter run

# APK 빌드
build:
	flutter build apk