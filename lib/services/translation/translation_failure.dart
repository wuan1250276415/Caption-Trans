const String translationErrorPrefix = '[Translation error';

String buildTranslationError(String message) {
  return '[Translation error: $message]';
}

bool isTranslationErrorText(String? text) {
  final normalized = text?.trimLeft().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }

  return normalized.startsWith('[translation error') ||
      normalized.startsWith('translation error');
}
