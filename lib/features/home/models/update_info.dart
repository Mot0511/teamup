class UpdateInfo {
  final String currentVersion;
  final List newFeatures;

  UpdateInfo({required this.currentVersion, required this.newFeatures});

  factory UpdateInfo.fromJSON(Map data) {
    return UpdateInfo(currentVersion: data['currentVersion'], newFeatures: data['newFeatures']);
  }
}