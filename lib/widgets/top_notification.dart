import 'package:flutter/material.dart';

/// A swipeable notification widget that appears at the top of the screen
/// and can be dismissed by swiping up
class TopNotification extends StatefulWidget {
  final String title;
  final String message;
  final ImageProvider? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onDismissed;
  final Duration? displayDuration;
  final Widget? trailingWidget;

  const TopNotification({
    Key? key,
    required this.title,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onDismissed,
    this.displayDuration,
    this.trailingWidget,
  }) : super(key: key);

  @override
  State<TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<TopNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Slide in from top
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    // Fade in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    // Start showing animation
    _controller.forward();
    
    // Auto-dismiss after duration if specified
    if (widget.displayDuration != null) {
      Future.delayed(widget.displayDuration!, () {
        _dismiss();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    // Slide out to top
    _controller.reverse().then((_) {
      // Call onDismissed callback if provided
      if (widget.onDismissed != null) {
        widget.onDismissed!();
      }
      // Remove from overlay
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final textColor = widget.textColor ?? theme.colorScheme.onPrimary;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            // Dismiss if swiped up with sufficient velocity
            if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
              _dismiss();
            }
          },
          child: Material(
            color: backgroundColor.withOpacity(0.95),
            elevation: 8.0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    if (widget.icon != null)
                      CircleAvatar(
                        radius: 20.0,
                        backgroundImage: widget.icon!,
                      ),
                    if (widget.icon != null)
                      const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.trailingWidget != null) ...[
                      const SizedBox(width: 8.0),
                      widget.trailingWidget!,
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.close, size: 18.0, color: Colors.white),
                        onPressed: _dismiss,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}