import 'dart:math';

/// 신규 가입 시 제안할 랜덤 닉네임 생성기(형용사 + 동물, 예: "행복한하마").
///
/// 닉네임 설정 화면의 **기본 제안값(placeholder/초깃값)** 으로 쓰고, 사용자는 그대로 쓰거나
/// 직접 바꿀 수 있다. 사전 단어 조합이라 항상 닉네임 최대 길이(20자) 이내다.

/// 형용사(모두 "~한" 형태 — 동물에 자연스럽게 붙는다).
const List<String> kNicknameAdjectives = <String>[
  '행복한',
  '용감한',
  '느긋한',
  '엉뚱한',
  '다정한',
  '씩씩한',
  '포근한',
  '재빠른',
  '차분한',
  '유쾌한',
  '당당한',
  '총명한',
  '상냥한',
  '명랑한',
  '진지한',
  '의젓한',
  '깜찍한',
  '부지런한',
  '따뜻한',
  '단단한',
];

/// 동물(2~3자, 형용사와 합쳐도 20자 이내).
const List<String> kNicknameAnimals = <String>[
  '하마',
  '여우',
  '너구리',
  '사자',
  '호랑이',
  '펭귄',
  '코알라',
  '다람쥐',
  '고양이',
  '강아지',
  '토끼',
  '거북이',
  '부엉이',
  '수달',
  '판다',
  '곰',
  '늑대',
  '사슴',
  '고래',
  '두더지',
];

/// 형용사 1개 + 동물 1개를 랜덤으로 골라 이어 붙인다(예: "행복한하마").
/// [random] 을 주입하면 결정적으로 동작한다(테스트용). 생략 시 보안 난수.
String suggestNickname([Random? random]) {
  final Random r = random ?? Random.secure();
  final String adjective =
      kNicknameAdjectives[r.nextInt(kNicknameAdjectives.length)];
  final String animal = kNicknameAnimals[r.nextInt(kNicknameAnimals.length)];
  return '$adjective$animal';
}
