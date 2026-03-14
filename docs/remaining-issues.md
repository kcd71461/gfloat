# Remaining Issues (Medium/Low)

Issues deferred from the 2026-03-13 review. Critical/High issues have been resolved.

---

## UI/UX

### Medium
- **F1-3**: show/hide 시 애니메이션 부재 — `NSWindow.animator()` 활용한 페이드인/아웃 추가
- **F3-2**: 핫키 등록 실패 시 사용자 피드백 없음 — `RegisterEventHotKey` 반환값 확인 후 알림
- **F3-3**: 핫키 녹음 취소 불가 — ESC로 취소 기능 + "(ESC to cancel)" 안내 추가
- **F4-3**: 온보딩 접근성 폴링 타이머 미해제 — 타이머를 프로퍼티로 저장, `completeOnboarding()`에서 invalidate
- **F5-1**: 윈도우 크기 입력값 최대값 제한 없음, 높이 최소값 320/400 불일치
- **F5-2**: 환경설정 윈도우 재사용 시 필드 값 미갱신
- **F6-2**: 네비게이션 정책에서 linkActivated 외 타입은 도메인 무관 허용
- **F6-3**: WebView 로딩 상태 표시 없음 — 로딩 인디케이터 추가
- **F7-2**: 자동 숨김 시 복구 방법 안내 부재 — 온보딩에 설명 추가
- **F8-1**: 메뉴바 아이콘 `isTemplate = false` — 라이트 모드에서 안 보일 수 있음
- **F10-2**: Mission Control / Space 전환 시 "Show on all Spaces" 토글 옵션 없음
- **F10-3**: 전체화면 앱 위에서의 동작 문서화 필요

### Low
- **F2-3**: 드래그 핸들 배경색 하드코딩 — 다크/라이트 모드 대응
- **F3-4**: 메뉴 keyEquivalent "g"와 실제 글로벌 핫키 불일치
- **F6-4**: 네트워크 오류 시 복구 방법 없음 — 에러 페이지 + "Reload" 옵션
- **F8-2**: fallback 아이콘 `bubble.left.fill` — 앱 정체성 불명확
- **F8-3**: "Launch at Login" 등록 실패 시 오류 무시
- **F10-4**: 앱 재시작 시 윈도우 위치 미복원 — **해결됨 (windowX/Y 추가)**
- **F5-3**: "Record New Shortcut" 버튼 녹음 중 시각적 상태 없음
- **F9-2**: 키보드만으로 온보딩 완료 어려움 — "Open System Settings" 버튼에 keyEquivalent 추가
- **F9-3**: 드래그 핸들 필 대비율 부족 — **개선됨 (0.3→0.5)**

---

## Legal

### Medium
- **MIT License 저작권자**: "GFloat Contributors" → 실제 개인/법인으로 명시
- **개인정보 처리방침 부재**: Privacy Policy 작성 및 README 링크
- **도메인 화이트리스트**: `hasSuffix("google.com")`이 `evil-google.com`도 통과 — `host == domain || host.hasSuffix("." + domain)` 으로 수정
- **Info.plist 저작권 불일치**: LICENSE 파일과 일치시키기

### Low
- **번들 식별자**: `com.gfloat.app` — 실제 소유 도메인 기반으로 변경 검토

---

## Documentation

### Medium
- **GitHub Releases 링크**: 상대경로 `../../releases` → 절대 URL로 변경
- **환경설정 스크린샷**: 주석 처리 상태 — 스크린샷 생성 또는 주석 삭제
- **버전 배지 부재**: README 상단에 version/license/macOS 배지 추가
- **LICENSE 저작권자**: "GFloat Contributors" 모호
- **누락 문서**: CONTRIBUTING.md, CHANGELOG.md, CI/CD workflows
- **구현 계획 vs 실제 이름 불일치**: 내부 문서에 리네이밍 주석 추가

### Low
- **ESC 표기**: `ESC` → `Esc` (macOS 관례)
- **한국어 기술 용어 혼용**: "플로팅 윈도우/패널 윈도우/창" 통일
- **한국어 태그라인 미완결**: "언제든지." → "언제든지 호출."
- **Contributing 섹션 부재**
