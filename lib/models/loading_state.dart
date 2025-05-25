class LoadingStatus {
  final double progress;
  final String message;

  LoadingStatus({
    required this.progress,
    required this.message,
  });

  factory LoadingStatus.initial() {
    return LoadingStatus(
      progress: 0.0,
      message: '初始化...',
    );
  }
}