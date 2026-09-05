class JoinScanResult {
  const JoinScanResult.scanned(String this.code);
  const JoinScanResult.manualEntry() : code = null;

  final String? code;
}
