class CreateMemberRequest {
  const CreateMemberRequest({
    required this.email,
    required this.nickname,
    required this.password,
  });
  final String email;
  final String nickname;
  final String password;
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'nickname': nickname.trim(),
    'password': password,
  };
}

String? validatePasswordFormat(String? value) {
  final password = value ?? '';
  if (password.length < 8) return '비밀번호는 8자 이상 입력해 주세요.';
  if (!RegExp(r'[a-z]').hasMatch(password) ||
      !RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password) ||
      !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
    return '대문자·소문자·숫자·특수문자(!@#\$%^&*)를 포함해 주세요.';
  }
  return null;
}
