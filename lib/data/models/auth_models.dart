class LoginRequest {
  const LoginRequest(this.email, this.password);
  final String email;
  final String password;
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});
  final String nickname;
  final String accessToken;
  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] as String;
    if (token.isEmpty) throw const FormatException('빈 토큰 응답');
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: token,
    );
  }
}

class MemberInfo {
  const MemberInfo({
    required this.email,
    required this.nickname,
    required this.createdAt,
  });
  final String email;
  final String nickname;
  final DateTime createdAt;
  factory MemberInfo.fromJson(Map<String, dynamic> json) => MemberInfo(
    email: json['email'] as String,
    nickname: json['nickname'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
