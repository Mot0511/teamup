import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ConnectStatus {connecting, connected, connectedWithoutMicro, notConnected}

class ConnectStatusWidget extends StatelessWidget {
  const ConnectStatusWidget({super.key, required this.status});
  final ConnectStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Shimmer.fromColors(
          baseColor: status == ConnectStatus.connected ? theme.primaryColor
            : status == ConnectStatus.connecting ? const Color.fromARGB(255, 133, 132, 132)
            : theme.colorScheme.secondary,
          highlightColor: status == ConnectStatus.connected ? Color.fromARGB(255, 1, 114, 61)
            : status == ConnectStatus.connecting ? const Color.fromARGB(255, 148, 148, 148)
            : Color.fromARGB(255, 0, 145, 158),
          period: Duration(milliseconds: 2000),
          child: Container(
            width: double.infinity,
            height: 25,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 1, 126, 68)
            ),
          ),
        ),
        Center(
          child: Text(
            status == ConnectStatus.connecting
              ? 'Подключение к войсу...'
              : status == ConnectStatus.connected
                ? 'Подключено'
                : 'Подключено (без микрофона)',
            style: TextStyle(
              color: const Color.fromARGB(255, 192, 192, 192),
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}