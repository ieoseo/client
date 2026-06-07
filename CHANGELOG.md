# Changelog

## [1.1.0](https://github.com/pkdee/daykit/compare/client-v1.0.0...client-v1.1.0) (2026-06-05)


### Features

* **client:** Google 웹 클라이언트 ID 기본값 배선(로그인 활성) ([#74](https://github.com/pkdee/daykit/issues/74)) ([15ea778](https://github.com/pkdee/daykit/commit/15ea7788c4503e35509a0c322cefcb8057aa95d1)), closes [#73](https://github.com/pkdee/daykit/issues/73)
* **client:** 데이터 연동 — ApiRepository로 events/tasks/debts 실연동 ([#36](https://github.com/pkdee/daykit/issues/36)) ([60352f2](https://github.com/pkdee/daykit/commit/60352f2c45b582a6332b2e038bb3672fd9ed209b)), closes [#35](https://github.com/pkdee/daykit/issues/35)
* **client:** 릴리스 배선(운영 API·INTERNET·서명) + 새 앱 아이콘 ([#72](https://github.com/pkdee/daykit/issues/72)) ([8ff6f93](https://github.com/pkdee/daykit/commit/8ff6f935985a510307afc2065e87025ae425dd5b)), closes [#71](https://github.com/pkdee/daykit/issues/71)
* **client:** 소셜 로그인·캘린더 연동 Google 우선 노출(Kakao·Apple·Notion 숨김) ([#68](https://github.com/pkdee/daykit/issues/68)) ([e837fc8](https://github.com/pkdee/daykit/commit/e837fc814be7cdb07baa7111df95a91b5ffaa60d)), closes [#67](https://github.com/pkdee/daykit/issues/67)
* **client:** 소셜 로그인(Google/Apple/Kakao) SDK 연동 ([#40](https://github.com/pkdee/daykit/issues/40)) ([716d951](https://github.com/pkdee/daykit/commit/716d9511cbc494624ba2b6a178a41ea8075c2158)), closes [#38](https://github.com/pkdee/daykit/issues/38)
* **client:** 인증 연동 — ApiClient·로그인/회원가입·토큰 게이트 ([#33](https://github.com/pkdee/daykit/issues/33)) ([e969681](https://github.com/pkdee/daykit/commit/e969681c6d991e7e5461c9a275dc2ea3082f2e28)), closes [#32](https://github.com/pkdee/daykit/issues/32)
* 계정/설정 실연동 — 회원탈퇴·프로필 수정·사용자 설정 ([#58](https://github.com/pkdee/daykit/issues/58)) ([e407d81](https://github.com/pkdee/daykit/commit/e407d81deeea0b0a8ee11a88abf2eb64005130a9)), closes [#56](https://github.com/pkdee/daykit/issues/56)
* 관측성(Sentry) 연동 (server 코어 SDK + client sentry_flutter) ([#64](https://github.com/pkdee/daykit/issues/64)) ([a30747a](https://github.com/pkdee/daykit/commit/a30747af7f880d5c6350be7d9d19af9b6018ccdd))
* 미룬 시간(부채) UX 마무리 — 제목 표시 + 자동 이월 배선 ([#44](https://github.com/pkdee/daykit/issues/44)) ([021bdd5](https://github.com/pkdee/daykit/commit/021bdd522439c735b84cb7157c95858ddde78b45)), closes [#41](https://github.com/pkdee/daykit/issues/41)
* 반복 태스크(주/월/연) — 도메인·API·클라 입력 연동 ([#47](https://github.com/pkdee/daykit/issues/47)) ([a3ad43f](https://github.com/pkdee/daykit/commit/a3ad43f8d536bd3be3ab7e18c7e022f5201c4987)), closes [#45](https://github.com/pkdee/daykit/issues/45)
* 알림(인앱) — Notification 도메인·API·NotifSheet 실연동 ([#48](https://github.com/pkdee/daykit/issues/48)) ([d6efacf](https://github.com/pkdee/daykit/commit/d6efacf2526737336b0c84376bd791b922e8d86d)), closes [#46](https://github.com/pkdee/daykit/issues/46)
* 외부 캘린더 동기화(Google/Notion, Apple 제약) ([#60](https://github.com/pkdee/daykit/issues/60)) ([45babe1](https://github.com/pkdee/daykit/commit/45babe1383c88f126bfce0a768e515555b02b580)), closes [#59](https://github.com/pkdee/daykit/issues/59)
* 인증 기동 보장 — JWT 임시 시크릿·소셜 미설정 시 수동 폴백 ([#52](https://github.com/pkdee/daykit/issues/52)) ([4842969](https://github.com/pkdee/daykit/commit/48429697922b7147c5bb30db2de38bfaf771ed44)), closes [#51](https://github.com/pkdee/daykit/issues/51)


### Bug Fixes

* **client:** 로고 정상화·스플래시 3초·매니페스트 빌드 수정 (배포 체크포인트) ([#75](https://github.com/pkdee/daykit/issues/75)) ([8aaf31a](https://github.com/pkdee/daykit/commit/8aaf31ae2527b9d205eaedc8141e4e65c90a6baa))

## [1.0.0](https://github.com/pkdee/daykit/compare/client-v1.0.0...client-v1.0.0) (2026-06-03)


### Features

* **client:** 4탭 화면·시트·서브화면 구현 ([#18](https://github.com/pkdee/daykit/issues/18)) ([62c76e2](https://github.com/pkdee/daykit/commit/62c76e224eaa5e00295431454755436e1642a4d6)), closes [#11](https://github.com/pkdee/daykit/issues/11)
* **client:** Flutter 앱 기반 구축 — 토큰·데이터·위젯·진입 플로우 ([#9](https://github.com/pkdee/daykit/issues/9)) ([b0b7646](https://github.com/pkdee/daykit/commit/b0b7646b3b80667a9065ac3bd308e00d538d6a66)), closes [#5](https://github.com/pkdee/daykit/issues/5)
* **client:** 앱 아이콘·기본 회원가입·1.0.0 릴리스 준비 ([#19](https://github.com/pkdee/daykit/issues/19)) ([8fc3f54](https://github.com/pkdee/daykit/commit/8fc3f546c42c20e2d90d94425959f9ac1a77cfa0))
