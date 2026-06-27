# Changelog

## [0.8.0](https://github.com/ieoseo/client/compare/ieoseo-client-v0.7.0...ieoseo-client-v0.8.0) (2026-06-27)


### Features

* iOS Apple 로그인 네이티브 처리 ([#116](https://github.com/ieoseo/client/issues/116)) ([2e24ba6](https://github.com/ieoseo/client/commit/2e24ba6bb93a965709617621e3ac12b71f9f4b48)), closes [#115](https://github.com/ieoseo/client/issues/115)


### Bug Fixes

* 긴 휴식 설정·외부 URL 검증·릴리스 난독화·ATS(F4·S2·S7·S8) ([#114](https://github.com/ieoseo/client/issues/114)) ([fc35ed7](https://github.com/ieoseo/client/commit/fc35ed78272cd562fb7465071c44fa561fc84ce9))
* 인증 흐름 조용한 실패 보강(C1·C3) ([#111](https://github.com/ieoseo/client/issues/111)) ([7abff44](https://github.com/ieoseo/client/commit/7abff44139d5186bbc24bb5abc7f3d274a8ab22f))
* 주간 리뷰 단위·미룬시간 롤백·목 상수 차단(F10·F6·F11·F12) ([#113](https://github.com/ieoseo/client/issues/113)) ([8ec98cc](https://github.com/ieoseo/client/commit/8ec98cc8ee93e9c4a61e5b242867c7abc3bb9210))
* 컨트롤러 예외 관측성·PKCE 명시(C4·S5) ([#112](https://github.com/ieoseo/client/issues/112)) ([7c22b71](https://github.com/ieoseo/client/commit/7c22b717f7c1b7c2a96364c9c602f3608b1af618))

## [0.7.0](https://github.com/ieoseo/client/compare/ieoseo-client-v0.6.1...ieoseo-client-v0.7.0) (2026-06-26)


### Features

* 로그인 화면 DayKit 핸드오프 반영·소셜 3종 ([#101](https://github.com/ieoseo/client/issues/101)) ([0db94f7](https://github.com/ieoseo/client/commit/0db94f7df765deeddf5f89d6c2bfecc1de763189))
* 오늘 탭 D-Day 전환·하단 네비 가운데 + 버튼 ([#98](https://github.com/ieoseo/client/issues/98)) ([77b6821](https://github.com/ieoseo/client/commit/77b6821eb852391d2e1d9ef900391687157a68af))

## [0.6.1](https://github.com/ieoseo/client/compare/ieoseo-client-v0.6.0...ieoseo-client-v0.6.1) (2026-06-19)


### Features

* 캘린더 오늘버튼·주/일 슬라이드 + 범위 표시 + D-day 수치 ([#94](https://github.com/ieoseo/client/issues/94)) ([f45c458](https://github.com/ieoseo/client/commit/f45c458db044841206a0c69ccf6e5c33c285a4bf))


### Miscellaneous Chores

* 0.6.1 패치 릴리스로 지정 ([7f72dfa](https://github.com/ieoseo/client/commit/7f72dfa3a713c816a41762143e0e8ffb6b59718c))

## [0.6.0](https://github.com/ieoseo/client/compare/ieoseo-client-v0.5.1...ieoseo-client-v0.6.0) (2026-06-19)


### Features

* 소셜 로그인 버튼 로고 + 데이터 로딩 스켈레톤 ([#91](https://github.com/ieoseo/client/issues/91)) ([73dae11](https://github.com/ieoseo/client/commit/73dae11c3f74fb039ead19af15355d5469a6a71f))

## [0.5.1](https://github.com/ieoseo/client/compare/ieoseo-client-v0.5.0...ieoseo-client-v0.5.1) (2026-06-19)


### Bug Fixes

* 로그인 로딩 화면·주간 시작 요일 드롭다운·미룬시간 아이콘 통일 ([#88](https://github.com/ieoseo/client/issues/88)) ([bf11f53](https://github.com/ieoseo/client/commit/bf11f5309d090171254a898b7c85c06da96dcaf2))

## [0.5.0](https://github.com/ieoseo/client/compare/ieoseo-client-v1.1.0...ieoseo-client-v0.5.0) (2026-06-17)


### Miscellaneous Chores

* 릴리스 버전을 0.5.0 으로 지정 ([58d886d](https://github.com/ieoseo/client/commit/58d886d43df86254e4858b9c687db9a466daaec6))

## [1.1.0](https://github.com/ieoseo/client/compare/ieoseo-client-v1.0.0...ieoseo-client-v1.1.0) (2026-06-17)


### Features

* 태스크 범위(시작~종료) 날짜 — client ([#50](https://github.com/ieoseo/client/issues/50)) ([#82](https://github.com/ieoseo/client/issues/82)) ([dbdde7d](https://github.com/ieoseo/client/commit/dbdde7d154b34b9b52bb50d6422c27842a42e313))


### Bug Fixes

* 플랜 계획 시간 합계 + 다크모드 영속화 ([#83](https://github.com/ieoseo/client/issues/83)) ([f552861](https://github.com/ieoseo/client/commit/f552861a427477e9ce2ca0448a6e5a1ff974c432))

## [1.0.0](https://github.com/ieoseo/client/compare/ieoseo-client-v0.1.0...ieoseo-client-v1.0.0) (2026-06-16)


### ⚠ BREAKING CHANGES

* 이메일 로그인/가입 제거. 로그인은 Google·Kakao 만(Apple 후속).

### Features

* 연동 계정·캘린더에 브랜드(심플) 아이콘 ([#60](https://github.com/ieoseo/client/issues/60)) ([05f9e27](https://github.com/ieoseo/client/commit/05f9e27a55ab56bbeb9e634338c0b3c116e2a5f4)), closes [#59](https://github.com/ieoseo/client/issues/59)
* 이메일 로그인 제거(소셜 전용으로 단순화) ([#49](https://github.com/ieoseo/client/issues/49)) ([1a68b91](https://github.com/ieoseo/client/commit/1a68b9114c24be24917061e2c78952e027303ff7)), closes [#48](https://github.com/ieoseo/client/issues/48)
* 이벤트 기간 단일 달력 범위 선택(시작~종료 하이라이트) ([#75](https://github.com/ieoseo/client/issues/75)) ([f988a18](https://github.com/ieoseo/client/commit/f988a18b380b60842832344a2c08656c5d6d80f2)), closes [#74](https://github.com/ieoseo/client/issues/74)
* 태스크 예정일 달력 피커 ([#58](https://github.com/ieoseo/client/issues/58)) ([2c9febd](https://github.com/ieoseo/client/commit/2c9febd3213b6002ef142cd6c94c9574820c5f77)), closes [#57](https://github.com/ieoseo/client/issues/57)
* 태스크 카테고리 색점 → 아이콘 ([#62](https://github.com/ieoseo/client/issues/62)) ([37d46e5](https://github.com/ieoseo/client/commit/37d46e5677ac4d447b20192f4b197016ede11638)), closes [#61](https://github.com/ieoseo/client/issues/61)
* 플랜 캘린더 월 이동 + 오늘 복귀 ([#71](https://github.com/ieoseo/client/issues/71)) ([e99c99e](https://github.com/ieoseo/client/commit/e99c99e84ff2201f78f6424f4ae3e86f0591a76e)), closes [#70](https://github.com/ieoseo/client/issues/70)


### Bug Fixes

* Play 내부 트랙 versionCode를 4로 상향 ([#40](https://github.com/ieoseo/client/issues/40)) ([df2472c](https://github.com/ieoseo/client/commit/df2472cfeb1d050e0fe386c57ddfa6326ab5d22c)), closes [#39](https://github.com/ieoseo/client/issues/39)
* 릴리스 빌드에 앱설정 env(dart-define) 주입해 스플래시 멈춤 해소 ([#44](https://github.com/ieoseo/client/issues/44)) ([7748e4f](https://github.com/ieoseo/client/commit/7748e4f6b4d2257b49ff746c0ac1c578c93e433a)), closes [#43](https://github.com/ieoseo/client/issues/43)
* 안드로이드 UI 버그 2건(탭바 겹침 + 키보드 재표시) ([#47](https://github.com/ieoseo/client/issues/47)) ([1b2f4e6](https://github.com/ieoseo/client/commit/1b2f4e6377cac4fbc3eab479b81b544cf52a9f5a)), closes [#46](https://github.com/ieoseo/client/issues/46)
* 안드로이드 뒤로가기 + 포모도로 설정 집중 탭 이동 ([#56](https://github.com/ieoseo/client/issues/56)) ([540040e](https://github.com/ieoseo/client/commit/540040e4d746f3848b9c70fe6d54314ca3eea0f1))
* 앱 전체 '오늘'을 고정값(2026-06-01)에서 실제 날짜로 ([#63](https://github.com/ieoseo/client/issues/63)) ([86a357d](https://github.com/ieoseo/client/commit/86a357d47b3269f885db4004e06bdbbba21edef2)), closes [#52](https://github.com/ieoseo/client/issues/52)
* 오늘·플랜·집중·프로필 UI 버그 일괄 수정 ([#67](https://github.com/ieoseo/client/issues/67)) ([2531a90](https://github.com/ieoseo/client/commit/2531a90315d3a8674cbed96276c0675a07cdbb2c)), closes [#66](https://github.com/ieoseo/client/issues/66)
* 완료 취소(체크 해제) 실제 반영 — reopen 호출 ([#73](https://github.com/ieoseo/client/issues/73)) ([81ff928](https://github.com/ieoseo/client/commit/81ff928b9c3f423837919d841d440816be8af90d)), closes [#72](https://github.com/ieoseo/client/issues/72)
* 캘린더 출처 표시 정리 + 릴리스 artifact 제거(vc8) ([#69](https://github.com/ieoseo/client/issues/69)) ([50bfd1a](https://github.com/ieoseo/client/commit/50bfd1a1b3f5c43535aefa8bdc39aa101624b00d)), closes [#68](https://github.com/ieoseo/client/issues/68)
* 코드 감사 후속 — 날짜 옮기기 실제 연결·롤백·copyWith 등 ([#77](https://github.com/ieoseo/client/issues/77)) ([c5c1785](https://github.com/ieoseo/client/commit/c5c178593e8d8f829ca82729775711e6de670d82)), closes [#76](https://github.com/ieoseo/client/issues/76)
* 플랜/프로필/태스크 빠른 버그·정리 ([#53](https://github.com/ieoseo/client/issues/53)) ([666f87e](https://github.com/ieoseo/client/commit/666f87ebc9ee2c4f8044eab5db4392fc6a284188)), closes [#51](https://github.com/ieoseo/client/issues/51)

## [0.1.0](https://github.com/ieoseo/client/compare/ieoseo-client-v0.0.1...ieoseo-client-v0.1.0) (2026-06-13)


### Features

* Google 캘린더 연동 서버 OAuth 클라이언트 배선 (Phase B) ([#13](https://github.com/ieoseo/client/issues/13)) ([2db6647](https://github.com/ieoseo/client/commit/2db66475e36364e8c015b2792d1d041e39e2bd73)), closes [#9](https://github.com/ieoseo/client/issues/9)
* 나 탭→프로필 개편(아바타·구독 일정 관리 coming-soon) ([#20](https://github.com/ieoseo/client/issues/20)) ([3d24b13](https://github.com/ieoseo/client/commit/3d24b1317146a1416c34efc6ca233e6a5072adae)), closes [#19](https://github.com/ieoseo/client/issues/19)
* 로그인 화면에 Google·Kakao 소셜 버튼 노출 ([#7](https://github.com/ieoseo/client/issues/7)) ([3aba229](https://github.com/ieoseo/client/commit/3aba2290a78a07e0ae85f30079debe442f29eac9)), closes [#6](https://github.com/ieoseo/client/issues/6)
* 마이페이지 연동 계정 관리(연결/해제) ([#12](https://github.com/ieoseo/client/issues/12)) ([54df52b](https://github.com/ieoseo/client/commit/54df52bdbb254ace5f92b181f88bcf33bed1c8b8)), closes [#10](https://github.com/ieoseo/client/issues/10)
* 미룬 시간·하루 최대 예약 아이콘을 달력+이월 화살표로 교체 ([#27](https://github.com/ieoseo/client/issues/27)) ([1ad04bb](https://github.com/ieoseo/client/commit/1ad04bb9d3a8a22af0a026b69e7595117cccea75)), closes [#26](https://github.com/ieoseo/client/issues/26)
* 선택 칩 DkChoiceChip 추출 + seed 소비 ([#38](https://github.com/ieoseo/client/issues/38)) ([e682c52](https://github.com/ieoseo/client/commit/e682c52555af0c39957d62c89209b3b58e63afb1))
* 준비 중 기능 회색 어포던스 + 공통 안내 통일 ([#25](https://github.com/ieoseo/client/issues/25)) ([64ad61a](https://github.com/ieoseo/client/commit/64ad61a7d90c81ed002a8093f2f7778da07acbfe)), closes [#24](https://github.com/ieoseo/client/issues/24)
* 클라이언트 인증 Supabase Auth로 전환 ([#4](https://github.com/ieoseo/client/issues/4)) ([f324b37](https://github.com/ieoseo/client/commit/f324b37b15c5b69b300440589b3b4ed534114232))


### Bug Fixes

* iOS 소셜 로그인 딥링크 복귀 흐름 안정화 ([#11](https://github.com/ieoseo/client/issues/11)) ([3b66a5a](https://github.com/ieoseo/client/commit/3b66a5a7799002f9da547fca213a0d218c25d871)), closes [#8](https://github.com/ieoseo/client/issues/8)
* 로그인 흐름 — API base URL env 외부화 + OAuth 복귀 로딩 ([#21](https://github.com/ieoseo/client/issues/21)) ([a887589](https://github.com/ieoseo/client/commit/a887589504dbd7c7d89e03d3bb171e6ab8d57f6c))
* 빈 주 리뷰 화면 막대 높이 0 division 크래시 가드 ([#23](https://github.com/ieoseo/client/issues/23)) ([859b38b](https://github.com/ieoseo/client/commit/859b38b115796edb42614850511d5e8ce47b0555)), closes [#22](https://github.com/ieoseo/client/issues/22)
* 운영 하드코딩 데이터 제거(주간 리뷰 실데이터 파생) + 미룬 시간 아이콘 ([#18](https://github.com/ieoseo/client/issues/18)) ([7b6ba79](https://github.com/ieoseo/client/commit/7b6ba79da6067af93b6eaeb5a875bb5fcce387e7))

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
