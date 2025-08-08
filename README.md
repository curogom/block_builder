# Flutter × Flame 블록 쌓기 게임 – GPT-5 Codex 작업 스펙 (Web 우선 / Standalone)

> **목적**: GitHub Codespaces 또는 OpenAI Codex(GPT-5)에서 이 문서만 참고해 바로 **웹 실행 가능한** 스택 게임을 구현한다. **저장/네트워크/백엔드 없음**을 전제로 한다. (추후 다수 미니게임을 묶어 모바일 앱으로 별도 출시할 예정)

## 1. 프로젝트 개요
- **장르**: 원탭 물리 퍼즐(스택)
- **플랫폼**: **Web 우선** (Flutter 3.22+ web, Flame 1.x)
- **세션 길이**: 최대 3분
- **코어 루프**: 블록 좌우 이동 → 탭 시 낙하 → 기존 블록과 겹친 면적만 다음 층 유지 → 제한 시간 내 최대 높이 달성

## 2. 핵심 규칙
1. **드랍 타이밍**: 화면 탭 시 낙하
2. **유효 면적 계산**: 겹치는 면적만 다음 층 유지(나머지는 파편 이펙트로 낙하)
3. **게임오버**: 겹치는 면적이 0일 때
4. **시간 제한**: 3분 카운트다운
5. **점수 구조**: 높이 점수, 정밀 보너스, 콤보 시스템 (세션 내 계산만, 저장 없음)
6. **난이도 조절**: 이동 속도 증가, 미세 랜덤 오프셋 이벤트

## 3. 기술 스택
- **엔진**: Flame
- **물리**: AABB 충돌 + 커스텀 트리밍 로직
- **오디오**: Flame Audio
- **상태관리**: Riverpod 또는 ValueNotifier(경량)

## 4. 시스템 구조
- 상태 흐름: Boot → MainMenu → Playing ↔ Paused → GameOver
- 주요 클래스:
    - `StackGame`: 게임 루프, 상태 관리, 타이머
    - `Block`: 이동·낙하·크기 데이터
    - `StackManager`: 블록 리스트, 트리밍 로직, 높이 계산
    - `UiOverlay`: 타이머·점수 표시
    - `Effects`: 파티클 및 피드백
- 카메라: y-축 성장에 맞춰 상단 따라가기

## 5. 트리밍 알고리즘 예시
```dart
overlapX1 = max(A.x1, B.x1);
overlapX2 = min(A.x2, B.x2);
if (overlapX2 <= overlapX1) gameOver();
else {
  width = overlapX2 - overlapX1;
  height = B.height; // 수직 정렬 전제
  // 블록 B를 겹치는 영역으로 재설정하고 스냅
}
```

6. 주요 파라미터
	•	초기 블록 크기: 240×40 px
	•	수평 속도: 120 px/s → 층마다 2% 증가 (상한 380 px/s)
	•	낙하 속도: 900 px/s
	•	제한 시간: 180초 (30초 남으면 경고)

7. UI/UX
	•	원탭 조작(전체 화면 탭 = 드랍)
	•	정밀 드랍 시 진동(웹은 haptics 없음 → 비주얼/사운드로 대체), 파티클, 보너스 점수 팝업
	•	점수·타이머 상단 고정 표시

8. 아트/사운드
	•	단색 + 그라디언트 블록
	•	배경: 패럴랙스 효과(느린 속도)
	•	사운드: 드랍, 충돌, 콤보, 타임 경고, 게임오버

9. 배포/플랫폼 전략
	•	웹(우선): flutter build web → 정적 호스팅(예: GitHub Pages, Cloudflare Pages, Firebase Hosting 등). 네트워크 권한·서버 구성 불필요.
	•	모바일(후행 계획): 여러 미니게임 번들 앱으로 별도 출시. 공통 런처/설정/튜토리얼만 포함하고, 각 미니게임은 독립 동작(저장/네트워크 기본 미사용).

10. 마일스톤
	1.	MVP: 이동, 드랍, 트리밍, 타이머, 게임오버 구현
	2.	폴리싱: 콤보·이펙트·난이도 곡선 적용, 카메라 연출
	3.	제품화(웹): 튜토리얼·파비콘·메타 태그·배포 스크립트

11. 코드 스캐폴드 예시

class StackGame extends FlameGame with HasCollisionDetection {
  // TODO: camera, timer, score, overlays
  void spawnMovingBlock() { /* 초기 블록 생성 */ }
  @override
  void onTapDown(TapDownInfo info) { /* 드랍 로직 */ }
  void onBlockLanded(Block b) { /* 트리밍 + 스코어 */ }
}

12. 테스트 체크리스트
	•	오버랩=0 → 즉시 게임오버
	•	정밀 드랍 시 콤보 및 보너스 동작
	•	속도 상한 정상 작동
	•	카메라·UI 정상 표시
	•	타이머 경고 정상 작동

13. Codex/GPT-5 즉시 착수 가이드
	•	pubspec.yaml에 Flame, Flame Audio, Riverpod 추가
	•	lib/game 디렉토리에 stack_game.dart, block.dart, stack_manager.dart 생성
	•	assets/ 폴더에 테스트용 이미지/사운드 배치
	•	로컬 실행(웹):

flutter run -d chrome # Web 우선 타겟

	•	Codex 프롬프트 예시:

프로젝트 구조를 설정하고, MVP 기능(이동/드랍/트리밍)을 구현해 주세요. Flutter 3.22 web, Flame 1.x 기준입니다. 저장/네트워크 기능은 포함하지 마세요. 주어진 SPEC.md를 준수하세요.

14. 출시 준비(웹)
	•	파비콘/메타 태그/OG 이미지
	•	스토어·마켓 비해상(웹 소개 페이지) 스크린샷
	•	배포 스크립트(make build-web 등)

15. 다음 단계
	1.	Web MVP 구현 및 배포
	2.	미니게임 번들 앱의 런처·공통 UI 설계(후행)
	3.	번들 앱에 현재 게임을 모듈로 이식

---

## 사용법(FVM)

이 프로젝트는 FVM(Flutter Version Management)으로 SDK 버전을 고정합니다.

### 사전 준비
- FVM 설치: `dart pub global activate fvm` 또는 `brew tap leoafarias/fvm && brew install fvm`
- 프로젝트 루트에 FVM 설정 존재: `.fvm/fvm_config.json` (예: `3.32.8`)

### 빠른 실행
1) FVM으로 SDK 설치/선택
```
fvm use 3.32.8 --install
```
2) 웹 실행(Chrome)
```
fvm flutter pub get
fvm flutter run -d chrome --web-renderer canvaskit
```

또는 제공 스크립트를 사용할 수 있습니다.
```
./scripts/dev.sh                 # 기본: chrome + canvaskit
./scripts/build_web.sh           # build/web 산출
```

옵션
- 다른 디바이스: `./scripts/dev.sh -d edge` 등
- 렌더러 변경: `--renderer html`

### 참고
- 사운드 파일(assets/audio)은 비어 있습니다. 필요 시 `drop.mp3`, `land.mp3`, `trim.mp3`, `warn.mp3`, `gameover.mp3`를 추가하세요.
- Git 사용 시 `.fvm/flutter_sdk/`는 무시되며, `.fvm/fvm_config.json`만 커밋합니다.

### 로컬 SFX 생성(플레이스홀더)
- 네트워크 없이 간단한 플레이스홀더 효과음을 생성할 수 있습니다.
```
python3 tools/gen_sfx.py  # assets/audio/*.wav 생성
```
- 코드에서는 MP3 우선, 없으면 같은 이름의 WAV로 자동 폴백합니다.
