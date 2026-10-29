enum AuthFailureCode {
  wrongCredentials,
  emailAlreadyInUse,
  emailNotFound,
  weakPassword,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;

  String get message => switch (code) {
        AuthFailureCode.wrongCredentials => 'Email or password is incorrect.',
        AuthFailureCode.emailAlreadyInUse =>
          'An account with this email already exists. Try logging in instead.',
        AuthFailureCode.emailNotFound =>
          'No local account was found with that email.',
        AuthFailureCode.weakPassword =>
          'Choose a password with at least 8 characters.',
        AuthFailureCode.unknown => 'Something went wrong. Please try again.',
      };

  @override
  String toString() => 'AuthFailure($code)';
}

/// Converts any error thrown by the auth layer into a message safe to show users.
String userMessageFor(Object error) => error is AuthFailure
    ? error.message
    : 'Something went wrong. Please try again.';
