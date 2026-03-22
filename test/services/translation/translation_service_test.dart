import 'package:caption_trans/models/subtitle_segment.dart';
import 'package:caption_trans/models/translation_config.dart';
import 'package:caption_trans/services/translation/translation_provider.dart';
import 'package:caption_trans/services/translation/translation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslationService', () {
    test(
      'retryFailedOnly retranslates failed subtitles in batches without overwriting successes',
      () async {
        final provider = _FakeTranslationProvider(
          queuedResults: const [
            ['beta fixed', 'gamma fixed'],
            ['zeta fixed'],
          ],
        );
        final service = TranslationService(providerFactory: (_) => provider);
        const config = TranslationConfig(
          providerId: 'OpenAI',
          apiKey: 'test-key',
          baseUrl: 'https://example.com/v1',
          sourceLanguage: 'en',
          targetLanguage: 'zh',
          batchSize: 3,
        );
        final segments = [
          _segment(0, 'alpha', translatedText: 'alpha ok'),
          _segment(
            1,
            'beta',
            translatedText: '[Translation error: blocked output]',
          ),
          _segment(
            2,
            'gamma',
            translatedText: '[Translation error: blocked output]',
          ),
          _segment(3, 'delta', translatedText: 'delta ok'),
          _segment(4, 'epsilon', translatedText: 'epsilon ok'),
          _segment(
            5,
            'zeta',
            translatedText: '[Translation error: blocked output]',
          ),
        ];
        final progressUpdates = <int>[];

        service.configure(config);
        final result = await service.translateAll(
          segments: segments,
          config: config,
          retryFailedOnly: true,
          onProgress: (completed, total, partials) {
            progressUpdates.add(completed);
          },
        );

        expect(provider.translateBatchCalls, hasLength(2));
        expect(provider.translateBatchCalls[0].texts, ['beta', 'gamma']);
        expect(provider.translateBatchCalls[0].contextBefore, ['alpha ok']);
        expect(provider.translateBatchCalls[0].contextAfter, [
          'delta',
          'epsilon',
          'zeta',
        ]);
        expect(provider.translateBatchCalls[1].texts, ['zeta']);
        expect(provider.translateBatchCalls[1].contextBefore, [
          'gamma fixed',
          'delta ok',
          'epsilon ok',
        ]);
        expect(provider.translateBatchCalls[1].contextAfter, isEmpty);

        expect(result[0].translatedText, 'alpha ok');
        expect(result[1].translatedText, 'beta fixed');
        expect(result[2].translatedText, 'gamma fixed');
        expect(result[3].translatedText, 'delta ok');
        expect(result[4].translatedText, 'epsilon ok');
        expect(result[5].translatedText, 'zeta fixed');
        expect(progressUpdates, [3, 5, 6]);
      },
    );
  });
}

SubtitleSegment _segment(int index, String text, {String? translatedText}) {
  return SubtitleSegment(
    index: index,
    startTime: Duration(seconds: index),
    endTime: Duration(seconds: index + 1),
    text: text,
    translatedText: translatedText,
  );
}

class _FakeTranslationProvider implements TranslationProvider {
  final List<List<String>> queuedResults;
  final List<_TranslateBatchCall> translateBatchCalls = [];
  int _callIndex = 0;

  _FakeTranslationProvider({required this.queuedResults});

  @override
  String get name => 'Fake Provider';

  @override
  Future<String> buildContextSummary({
    required List<String> allTexts,
    required String sourceLanguage,
    required String targetLanguage,
    String? model,
    Future<void>? abortTrigger,
  }) async {
    return 'summary';
  }

  @override
  void dispose() {}

  @override
  Future<List<String>> listModels(String apiKey, {String? baseUrl}) async {
    return ['fake-model'];
  }

  @override
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
    String? model,
    List<String> contextBefore = const [],
    List<String> contextAfter = const [],
    Map<String, String> glossary = const {},
    void Function(int completed, int total)? onProgress,
    Future<void>? abortTrigger,
  }) async {
    translateBatchCalls.add(
      _TranslateBatchCall(
        texts: texts,
        contextBefore: contextBefore,
        contextAfter: contextAfter,
      ),
    );

    final result = queuedResults[_callIndex];
    _callIndex++;
    return result;
  }

  @override
  Future<bool> validateApiKey(
    String apiKey, {
    String? model,
    String? baseUrl,
  }) async {
    return true;
  }
}

class _TranslateBatchCall {
  final List<String> texts;
  final List<String> contextBefore;
  final List<String> contextAfter;

  const _TranslateBatchCall({
    required this.texts,
    required this.contextBefore,
    required this.contextAfter,
  });
}
