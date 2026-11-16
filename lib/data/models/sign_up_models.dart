class SignUpResult {
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });
  final int memberId;
  final String email;
  final String nickname;
  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    final id = json['memberId'];
    if (id is! num || !id.isFinite || id != id.round() || id < 1) {
      throw const FormatException('회원가입 응답의 memberId가 올바르지 않습니다.');
    }
    return SignUpResult(
      memberId: id.toInt(),
      email: json['email'] as String,
      nickname: json['nickname'] as String,
    );
  }
}
