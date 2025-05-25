import 'package:flutter/material.dart';
import '../models/loading_state.dart';

// TODO: 若未來有更複雜的載入狀態，建議將 LoadingStatus 擴充為 sealed class 或 enum，並支援多語系訊息
class LoadingIndicator extends StatelessWidget {
  final LoadingStatus status;

  const LoadingIndicator({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: status.progress > 0 ? status.progress : null,
          ),
          const SizedBox(height: 20),
          Text(
            status.message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (status.progress > 0)
            Text(
              '${(status.progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}