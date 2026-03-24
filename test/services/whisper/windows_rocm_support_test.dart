import 'package:caption_trans/services/whisper/windows_rocm_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowsRocmInstallSpec.current', () {
    test('pins the supported ROCm 7.1.1 release metadata', () {
      const WindowsRocmInstallSpec spec = WindowsRocmInstallSpec.current;

      expect(spec.displayName, 'ROCm 7.1.1');
      expect(spec.dependencyProfileId, 'windows-rocm711');
      expect(spec.releaseBaseUrl, 'https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1');
      expect(spec.managedPythonRuntimeKey, 'windows-x64-py312');
    });

    test('builds the expected ROCm SDK wheel URLs', () {
      const WindowsRocmInstallSpec spec = WindowsRocmInstallSpec.current;

      expect(spec.buildSdkWheelUrls(), <String>[
        'https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/rocm_sdk_core-0.1.dev0-py3-none-win_amd64.whl',
        'https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/rocm_sdk_devel-0.1.dev0-py3-none-win_amd64.whl',
        'https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/rocm_sdk_libraries_custom-0.1.dev0-py3-none-win_amd64.whl',
      ]);
    });

    test('builds the expected ROCm PyTorch wheel URLs', () {
      const WindowsRocmInstallSpec spec = WindowsRocmInstallSpec.current;

      expect(spec.buildTorchWheelUrls(), <String>[
        'https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/torch-2.9.0%2Brocmsdk20251116-cp312-cp312-win_amd64.whl',
        'https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/torchaudio-2.9.0%2Brocmsdk20251116-cp312-cp312-win_amd64.whl',
      ]);
    });

    test('removes both PyTorch and ROCm SDK packages before reinstalling', () {
      const WindowsRocmInstallSpec spec = WindowsRocmInstallSpec.current;

      expect(spec.packagesToUninstall, const <String>[
        'torch',
        'torchaudio',
        'torchvision',
        'rocm_sdk_core',
        'rocm_sdk_devel',
        'rocm_sdk_libraries_custom',
      ]);
    });
  });

  group('containsWindowsAmdGpuName', () {
    test('detects Radeon cards in WMIC output', () {
      expect(
        containsWindowsAmdGpuName(
          'Name=AMD Radeon RX 7800 XT\nName=Microsoft Basic Display Adapter',
        ),
        isTrue,
      );
    });

    test('detects Radeon cards in PowerShell output', () {
      expect(
        containsWindowsAmdGpuName('AMD Radeon RX 7800 XT\n'),
        isTrue,
      );
    });

    test('ignores non-AMD adapters', () {
      expect(
        containsWindowsAmdGpuName('Name=NVIDIA GeForce RTX 4080'),
        isFalse,
      );
    });
  });
}
