# Pin Mode & Navigation Buttons Design

## Overview

gfloat의 드래그 핸들 바에 세 가지 버튼을 추가한다:
1. **핀 버튼** — 포커스를 잃어도 창을 유지하는 "핀 모드" 토글
2. **새로고침 버튼** — 현재 Gemini 페이지 새로고침
3. **홈 버튼** — Gemini 메인 페이지로 이동

## Motivation

- 다른 앱을 잠깐 참조하면서 Gemini 답변을 함께 보고 싶을 때, 포커스를 잃으면 창이 사라져서 불편하다.
- 페이지 오류 복구나 새 대화 시작을 위해 새로고침/홈으로 돌아갈 방법이 없다.

## Design

### Drag Handle Bar Layout

드래그 핸들 바를 3구역으로 구성한다:

```
┌──────────────────────────────────────────────┐
│  [🏠] [↻]       ── drag pill ──        [📌]  │
│  왼쪽 버튼        가운데 드래그          오른쪽  │
└──────────────────────────────────────────────┘
```

- **왼쪽**: 홈 버튼, 새로고침 버튼 (각 20×20pt, 간격 8pt)
- **가운데**: 기존 드래그 인디케이터 (pill shape) 유지
- **오른쪽**: 핀 버튼
- **아이콘**: SF Symbols 사용 (`house`, `arrow.clockwise`, `pin` / `pin.fill`)
- **버튼 영역 외 공간**: 기존처럼 드래그 가능

### Pin Mode

**핀 OFF (기본, 현재 동작):**
- 다른 앱 클릭 시 gfloat 창 자동 숨김 (기존 `hideOnDeactivate` 동작)
- 핫키로 토글

**핀 ON:**
- `NSPanel`에 `.nonactivatingPanel` styleMask 추가
- 다른 앱 클릭 시 창은 그대로 보이고, 포커스만 다른 앱으로 이동
- `NSApplication.didResignActiveNotification`의 자동 숨김 로직을 핀 상태일 때 무시
- 핫키는 여전히 동작 (숨기기/보이기 가능)
- gfloat 창을 직접 클릭하면 다시 포커스를 얻고 Gemini에 입력 가능

**핀 아이콘 상태:**
- 핀 OFF: `pin` (빈 핀 아이콘)
- 핀 ON: `pin.fill` (채워진 핀 아이콘)

**핀 상태 지속성:**
- 앱 재시작 시 초기화 (OFF로 복귀). 임시적 용도이므로 UserDefaults에 저장하지 않음.

**ESC 동작:**
- 핀 상태에서도 더블 ESC로 창 숨김 동작. 숨기면 핀 자동 해제.

### Refresh Button

- `WKWebView.reload()` 호출
- 현재 Gemini 페이지를 그대로 새로고침 (대화 컨텍스트 유지)

### Home Button

- `WKWebView.load(URLRequest(url: URL(string: "https://gemini.google.com")!))` 호출
- Gemini 메인 페이지로 이동 (새 대화 시작 가능)

## Files to Modify

| File | Changes |
|------|---------|
| `Sources/GFloat/WebViewController.swift` | DragHandleBar에 홈/새로고침/핀 버튼 추가, 레이아웃 3구역 구성, 버튼 액션 핸들러 |
| `Sources/GFloat/FloatingWindow.swift` | 핀 모드 상태 프로퍼티, `nonactivatingPanel` styleMask 토글 메서드 |
| `Sources/GFloat/AppDelegate.swift` | `didResignActiveNotification` 핸들러에서 핀 상태 체크 추가 |

## Out of Scope

- 핀 상태의 키보드 단축키 (드래그 핸들 바 버튼만)
- 핀 상태의 UserDefaults 저장
- 뒤로가기/앞으로가기 네비게이션
