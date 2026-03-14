# GFloat

**macOS용 플로팅 Google Gemini 창 — 단축키 하나로 언제든지.**

<!-- ![GFloat 데모](assets/demo.gif) -->

[English](README.md)

## 기능

- **글로벌 단축키 토글** — `Cmd+Shift+G`로 표시/숨기기 (커스터마이징 가능)
- **플로팅 윈도우** — 모든 앱 위에 항상 표시
- **대화 상태 유지** — 표시/숨기기 간에 대화 내용 보존
- **드래그 핸들** — 화면 어디든 쉽게 위치 변경
- **창 크기 설정** — 원하는 크기로 조정 가능 (기본값 800×800)
- **자동 숨기기** — 다른 앱으로 전환 시 자동으로 숨기기
- **로그인 시 실행** — 로그인할 때 GFloat 자동 시작
- **메뉴바 전용** — Dock 아이콘 없이 메뉴바에서 조용히 실행

## 설치

### 다운로드

> 미리 빌드된 바이너리는 [GitHub Releases](../../releases) 페이지에서 제공될 예정입니다.

### 소스에서 빌드

```bash
git clone https://github.com/kcd71461/gfloat.git
cd gfloat
swift build -c release
bash scripts/bundle.sh
open build/GFloat.app
```

### 요구 사항

- macOS 14 (Sonoma) 이상
- Xcode Command Line Tools (`xcode-select --install`)
- 손쉬운 사용 권한 (첫 실행 시 안내)

## 사용법

### 첫 실행

첫 실행 시 GFloat는 온보딩 과정을 통해 **손쉬운 사용 권한** 설정을 안내합니다. 이 권한은 글로벌 단축키가 시스템 전체에서 동작하기 위해 필요합니다.

### 키보드 단축키

| 단축키 | 동작 |
|---|---|
| `Cmd+Shift+G` | GFloat 창 토글 |
| `Cmd+,` | 환경설정 열기 |
| `ESC` `ESC` | 창 숨기기 (두 번 누르기) |
| `Cmd+Q` | GFloat 종료 |

### 메뉴바 메뉴

메뉴바의 GFloat 아이콘을 클릭하여 다음에 접근할 수 있습니다:

- **표시/숨기기** — 플로팅 창 토글
- **환경설정…** — 환경설정 창 열기
- **로그인 시 실행** — 자동 시작 토글
- **GFloat 종료** — 앱 종료

<!-- ![환경설정 창](assets/preferences.png) -->

## 설정

모든 설정은 **환경설정** (`Cmd+,`)에서 변경할 수 있습니다:

| 설정 | 기본값 | 설명 |
|---|---|---|
| 단축키 | `Cmd+Shift+G` | 창 토글 글로벌 단축키 |
| 창 너비 | 800 | 창 너비 (픽셀, 최소 320) |
| 창 높이 | 800 | 창 높이 (픽셀, 최소 400) |
| 비활성화 시 숨기기 | 켜짐 | 다른 앱이 포커스를 받으면 자동 숨기기 |
| 로그인 시 실행 | 꺼짐 | 로그인할 때 GFloat 자동 시작 |

## 개발

### 프로젝트 구조

```
gfloat/
├── Sources/GFloat/
│   ├── main.swift              # 앱 진입점
│   ├── AppDelegate.swift       # 앱 생명주기 및 메뉴바 설정
│   ├── FloatingWindow.swift    # 플로팅 패널 윈도우
│   ├── WebViewController.swift # Google Gemini 로드 WebView
│   ├── HotkeyManager.swift     # 글로벌 단축키 등록
│   ├── Config.swift             # UserDefaults 기반 설정
│   ├── OnboardingWindow.swift   # 첫 실행 온보딩 흐름
│   └── PreferencesWindow.swift  # 환경설정 UI
├── Resources/
│   ├── Info.plist               # 앱 번들 메타데이터
│   ├── AppIcon.icns             # 앱 아이콘
│   └── MenuBarIcon/             # 메뉴바 아이콘 에셋
├── scripts/
│   ├── bundle.sh                # 빌드 및 .app 번들 생성
│   ├── generate-icons.swift     # 아이콘 생성 유틸리티
│   └── debug-window.swift       # 윈도우 디버깅 헬퍼
├── docs/                        # 문서
└── Package.swift                # Swift Package Manager 매니페스트
```

### 주요 컴포넌트

| 컴포넌트 | 설명 |
|---|---|
| `AppDelegate` | 앱 생명주기, 메뉴바 관리 및 전체 컴포넌트 조율 |
| `FloatingWindow` | 항상 위에 표시되고 드래그 이동을 지원하는 `NSPanel` 서브클래스 |
| `WebViewController` | Google Gemini를 로드하는 `WKWebView` 호스트 |
| `HotkeyManager` | Carbon 기반 글로벌 단축키 등록/해제 |
| `Config` | 모든 앱 설정을 위한 `UserDefaults` 래퍼 싱글톤 |
| `OnboardingWindow` | 손쉬운 사용 권한 설정 안내 |
| `PreferencesWindow` | 단축키, 창 크기, 동작 설정 커스터마이징 UI |

### 빌드 명령어

```bash
# 디버그 빌드
swift build

# 직접 실행
swift run GFloat

# 릴리스 빌드 + 앱 번들
bash scripts/bundle.sh
```

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다 — 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 면책 조항

이 프로젝트는 Google LLC와 관련이 없으며, Google LLC의 후원이나 승인을 받지 않았습니다. Google 및 Gemini는 Google LLC의 상표입니다.
