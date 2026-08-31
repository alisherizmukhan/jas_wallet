/// Client-side password policy, kept in sync with the backend
/// `validate_password_strength`: at least 8 characters, including at least
/// one letter and one digit.
final RegExp _passwordRule = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

/// Whether [password] satisfies the shared password policy.
bool isPasswordValid(String password) => _passwordRule.hasMatch(password);
