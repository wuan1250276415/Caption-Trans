enum WhisperDownloadSource {
  global('global'),
  mainlandChina('mainland_china');

  const WhisperDownloadSource(this.id);

  final String id;

  static WhisperDownloadSource? tryParse(String? raw) {
    for (final WhisperDownloadSource value in WhisperDownloadSource.values) {
      if (value.id == raw) {
        return value;
      }
    }
    return null;
  }
}
