# Assets Prompts (for OpenAI / Generative Tools)

목표: Web 우선 Flame 게임(블록 스택)용 이미지/사운드 에셋을 빠르게 생성하기 위한 프롬프트 모음입니다. 생성 결과는 상업적 사용 가능한 라이선스로 확보하고, 최종 출력물은 프로젝트 규격에 맞춰 내보내세요.

## 공통 가이드
- 스타일: 미니멀, 선명, 로우노이즈, 플랫한 하이라이트. UI/웹 친화(가독성 우선)
- 색상: docs/color.dart 팔레트 또는 브랜드 대표 톤을 우선 사용
- 형식: 이미지 PNG(투명배경), 사운드 WAV/MP3 44.1kHz, -14 LUFS 목표(최종 믹스 시 조정)
- 네이밍: assets/images/*, assets/audio/* 하위에 배치

---

## 이미지

### 1) imweb 로고 2종 (흰/검)
프롬프트:
- “Create a crisp, flat monochrome logo wordmark for ‘imweb’. Two variants: pure white (#FFFFFF) and pure black (#000000). Transparent background, centered. No effects, no shadow, no gradients. Export as 1024x1024 PNG, 64px padding all sides.”
파일명:
- assets/images/logo_imweb_white.png
- assets/images/logo_imweb_black.png

체크:
- 정사각형, 투명 배경, 모노톤 컬러 1색만 사용
- 소문자 글리프 형태 유지, 문자 외 장식 불가

### 2) 파편(조각) 텍스처(선택)
프롬프트:
- “Generate a subtle flat texture tile for falling fragments. Minimal noise, soft grain, 256x256 PNG with transparency. Colors: neutral gray variants only. No logos.”
파일명:
- assets/images/fragment_tile.png (선택, 현재는 단색 렌더로 대체 가능)

### 3) 배경 패럴랙스(선택)
프롬프트:
- “Create 3 parallax background layers for a minimalist skyline. Layer1: far mountains (very soft contrast). Layer2: mid hills. Layer3: near silhouettes. Palette: cool dark blues from #10141A to #24313E. Each layer 1920x1080 PNG, transparent background, no text.”
파일명:
- assets/images/bg_far.png
- assets/images/bg_mid.png
- assets/images/bg_near.png

---

## 사운드 효과(SFX)

요건 공통(생성형 도구 최적화):
- 길이: 150–500ms(짧고 선명) — 게임오버만 1–2s 허용
- 포맷: 원본 WAV 44.1kHz 16-bit → 최종 MP3 160kbps
- 라우드니스: 피크 -1 dBFS(클립 금지), -16~-14 LUFS 목표
- 공간감: 모노 권장, 과도한 리버브·앰비언스 금지, 노이즈 게이트
- 톤: 미니멀, 모던, 저중역 위주, 거친 하이컷(>10kHz) 가능

사용 모델 가이드(중 택1):
- ElevenLabs Sound Effects: “sound effects” 모드, 텍스트 프롬프트 길이 1–2문장 권장
- Stability AI Stable Audio: prompt + duration(ms) 지정, text conditioning 간결히
- Meta AudioCraft(AudioGen): 로컬 실행 시 동일 프롬프트 사용, seed 고정으로 재현성 확보

생성 후 공통 후처리(FFmpeg 예시):
- 페이드/트림: `ffmpeg -i in.wav -af "atrim=0:0.25,afade=t=out:st=0.20:d=0.05" out.wav`
- 피크 정규화: `ffmpeg -i in.wav -filter:a "volume=-1dB" out.wav`
- MP3 변환: `ffmpeg -i in.wav -codec:a libmp3lame -b:a 160k out.mp3`

파일 네이밍(코드 연결됨):
- assets/audio/drop.mp3, assets/audio/land.mp3, assets/audio/trim.mp3, assets/audio/warn.mp3, assets/audio/gameover.mp3

### 1) 드랍(drop)
프롬프트(예시 3안):
1) “Minimal UI/game SFX for ‘drop’: soft short whoosh indicating release of a falling block, mono, dry, 220–280ms, no harsh highs, clean transient.”
2) “Subtle air ‘whoosh’ for object release, modern UX sound, mono, 250ms, low reverb, no hiss.”
3) “Compact whoosh cue, neutral timbre, 0.25s, no tonal note.”
파일명: assets/audio/drop.mp3

### 2) 착지(land)
프롬프트(예시 3안):
1) “Block landing thump: muted, soft transient, low-mid punch, mono, 180–240ms, no metallic ring, dry.”
2) “Short dull thud for soft landing, clean, 0.2s, no tail.”
3) “Low ‘thump’ with quick decay, non-metallic, neutral.”
파일명: assets/audio/land.mp3

### 3) 트림(trim)
프롬프트(예시 3안):
1) “Slicing/trimming cue: quick ‘chnk/snap’, slight high-mid click, mono, 160–220ms, tight, dry.”
2) “Short cut/snip sound, crisp transient, 0.2s, no reverb, no tonal pitch.”
3) “Clean chop accent, bright but controlled, short tail.”
파일명: assets/audio/trim.mp3

### 4) 경고(warn, 30초 남음)
프롬프트(예시 3안):
1) “Timer warning: subtle two-note beep (low→high), mono, 280–360ms total, minimal reverb, not alarming.”
2) “Gentle double beep for time alert, calm UX tone, ~0.3s, clean.”
3) “Soft paced bip-bip, minimalistic, no harsh highs.”
파일명: assets/audio/warn.mp3

### 5) 게임오버(gameover)
프롬프트(예시 3안):
1) “Game over cue: descending tone, calm and minimal, 0.8–1.2s, soft fade out, no horror vibe.”
2) “Short downward motif, neutral timbre, 1s, gentle tail, mono.”
3) “Minimal down sweep, subtle, not sad, smooth fade.”
파일명: assets/audio/gameover.mp3

---

### 고급 가이드(권장)
- 주파수 대역: UI/SFX는 150Hz–6kHz 범위를 중심으로, 필요 시 하이컷(>10kHz) 적용.
- 다이내믹스: 트랜지언트는 짧게, 서스테인은 최소로. 배경 소음/룸톤 금지.
- 부정 프롬프트: “no reverb, no ambience, no hiss, no distortion, no metallic ring, no tonal melody (except gameover).”
- 재현성: seed(고정값)와 version 명시. 실패 시 동일 프롬프트로 3회 리런 후 A/B 선택.
- 파일 관리: 원본 WAV 보관 → 최종 MP3/OGG로 경량화. 파일명은 코드 매핑과 동일 유지.

---

## 음성(옵션)

짧은 피드백 보이스(영문/한글 중 택1), 과도한 캐릭터성 없이 미니멀한 UX 톤.
- 형식: WAV/MP3, 44.1kHz, -16~-14 LUFS
- 길이: 0.5–1.5초

프롬프트 예시:
- “Minimal UI voice line: ‘Great!’ clean, neutral, friendly, no background noise.”
- “Minimal UI voice line: ‘Combo!’ short, energetic but not cheesy.”
- “Minimal UI voice line (Korean): ‘좋아!’, ‘콤보!’, ‘서둘러!’ — each separate file.”
파일명(예):
- assets/audio/voice_great.mp3
- assets/audio/voice_combo.mp3
- assets/audio/voice_hurry_ko.mp3

---

## 배포 전 체크리스트
- 길이/포맷/라벨 확인, 파일명 일치
- 파일 경로: pubspec.yaml의 assets 섹션 포함 확인
- Loudness/peaks 점검(클립 방지), 불필요 무음 제거
- 저작권/라이선스 명시(저장소 내 NOTICE or CREDITS 업데이트)
