class WindowsRocmInstallSpec {
  static const WindowsRocmInstallSpec current = WindowsRocmInstallSpec(
    displayName: 'ROCm 7.1.1',
    dependencyProfileId: 'windows-rocm711',
    releaseTag: 'rocm-rel-7.1.1',
    sdkPackageVersion: '0.1.dev0',
    torchVersion: '2.9.0',
    torchaudioVersion: '2.9.0',
    torchBuildTag: 'rocmsdk20251116',
    managedPythonRuntimeKey: 'windows-x64-py312',
    packagesToUninstall: <String>[
      'torch',
      'torchaudio',
      'torchvision',
      'rocm_sdk_core',
      'rocm_sdk_devel',
      'rocm_sdk_libraries_custom',
    ],
  );

  final String displayName;
  final String dependencyProfileId;
  final String releaseTag;
  final String sdkPackageVersion;
  final String torchVersion;
  final String torchaudioVersion;
  final String torchBuildTag;
  final String managedPythonRuntimeKey;
  final List<String> packagesToUninstall;

  const WindowsRocmInstallSpec({
    required this.displayName,
    required this.dependencyProfileId,
    required this.releaseTag,
    required this.sdkPackageVersion,
    required this.torchVersion,
    required this.torchaudioVersion,
    required this.torchBuildTag,
    required this.managedPythonRuntimeKey,
    required this.packagesToUninstall,
  });

  String get releaseBaseUrl => 'https://repo.radeon.com/rocm/windows/$releaseTag';

  List<String> buildSdkWheelUrls() => <String>[
    '$releaseBaseUrl/rocm_sdk_core-$sdkPackageVersion-py3-none-win_amd64.whl',
    '$releaseBaseUrl/rocm_sdk_devel-$sdkPackageVersion-py3-none-win_amd64.whl',
    '$releaseBaseUrl/rocm_sdk_libraries_custom-$sdkPackageVersion-py3-none-win_amd64.whl',
  ];

  List<String> buildTorchWheelUrls() => <String>[
    _buildTorchWheelUrl('torch', torchVersion),
    _buildTorchWheelUrl('torchaudio', torchaudioVersion),
  ];

  String _buildTorchWheelUrl(String packageName, String packageVersion) {
    final String encodedVersion = Uri.encodeComponent(
      '$packageVersion+$torchBuildTag',
    );
    return '$releaseBaseUrl/$packageName-$encodedVersion-cp312-cp312-win_amd64.whl';
  }
}

bool containsWindowsAmdGpuName(String output) {
  return output
      .split(RegExp(r'[\r\n]+'))
      .map((String line) => line.trim().toLowerCase())
      .any(_looksLikeWindowsAmdGpuName);
}

bool _looksLikeWindowsAmdGpuName(String line) {
  if (line.isEmpty) {
    return false;
  }
  return line.contains('radeon') || (line.contains('amd') && line.contains('rx '));
}
