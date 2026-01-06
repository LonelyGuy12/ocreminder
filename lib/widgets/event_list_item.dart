import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lonelyreminder/models/event_model.dart';
import 'package:lonelyreminder/providers/theme_provider.dart';

class EventListItem extends StatefulWidget {
  final Event event;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final int index;

  const EventListItem({
    super.key,
    required this.event,
    required this.onDelete,
    required this.onEdit,
    this.index = 0,
  });

  @override
  State<EventListItem> createState() => _EventListItemState();
}

class _EventListItemState extends State<EventListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Pokemon type emojis for fun
  static const List<String> pokemonEmojis = ['🔥', '⚡', '💧', '🌿', '🐉', '👻', '⭐', '🌙'];

  String _getPokemonEmoji() {
    return pokemonEmojis[widget.event.title.hashCode.abs() % pokemonEmojis.length];
  }

  Duration _getTimeUntilEvent() {
    return widget.event.startTime.difference(DateTime.now());
  }

  String _formatTimeRemaining(Duration duration, bool isPokemonMode) {
    if (duration.isNegative) {
      return isPokemonMode ? 'Escaped!' : 'Passed';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final days = duration.inDays;

    if (days > 0) {
      return '${days}d ${hours % 24}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return isPokemonMode ? 'NOW!' : 'Soon!';
    }
  }

  Color _getTimeColor(Duration duration, bool isDark, bool isPokemonMode) {
    if (isPokemonMode) {
      if (duration.isNegative) return Colors.grey;
      if (duration.inMinutes < 30) return const Color(0xFFFF5722); // Fire orange
      if (duration.inHours < 2) return const Color(0xFFFFEB3B); // Electric yellow
      if (duration.inHours < 6) return const Color(0xFF4CAF50); // Grass green
      return const Color(0xFF2196F3); // Water blue
    }
    
    if (duration.isNegative) {
      return Colors.grey;
    } else if (duration.inMinutes < 30) {
      return isDark ? const Color(0xFFFF5252) : const Color(0xFFE53935);
    } else if (duration.inHours < 2) {
      return isDark ? const Color(0xFFFFAB40) : const Color(0xFFFF7043);
    } else if (duration.inHours < 6) {
      return isDark ? const Color(0xFFFFD740) : const Color(0xFFFFA726);
    } else {
      return isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateDelete() {
    _controller.reverse().then((_) => widget.onDelete());
  }

  @override
  Widget build(BuildContext context) {
    final timeRemaining = _getTimeUntilEvent();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isPokemonMode = context.watch<ThemeProvider>().isPokemonMode;
    final timeColor = _getTimeColor(timeRemaining, isDarkMode, isPokemonMode);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dismissible(
            key: Key(widget.event.id ?? widget.event.title),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => widget.onDelete(),
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isPokemonMode
                      ? [const Color(0xFFFF5722), const Color(0xFFE64A19)]
                      : [Colors.red.shade400, Colors.red.shade600],
                ),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isPokemonMode ? 'Release!' : 'Delete',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isPokemonMode ? Icons.catching_pokemon : Icons.delete_forever,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isPokemonMode
                    ? Colors.black.withOpacity(0.75)
                    : (isDarkMode ? const Color(0xFF161B22) : Colors.white),
                boxShadow: [
                  BoxShadow(
                    color: isPokemonMode
                        ? timeColor.withOpacity(0.3)
                        : (isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08)),
                    blurRadius: isPokemonMode ? 16 : 12,
                    offset: const Offset(0, 4),
                    spreadRadius: isPokemonMode ? 2 : 0,
                  ),
                ],
                border: Border.all(
                  color: isPokemonMode ? timeColor : timeColor.withOpacity(0.3),
                  width: isPokemonMode ? 2 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onEdit,
                    splashColor: timeColor.withOpacity(0.2),
                    highlightColor: timeColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pokemon emoji or animated indicator
                          if (isPokemonMode)
                            _buildPokemonIndicator(timeColor)
                          else
                            _buildTimeIndicator(timeColor),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isPokemonMode ? '${_getPokemonEmoji()} ${widget.event.title}' : widget.event.title,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: isPokemonMode
                                              ? Colors.white
                                              : (isDarkMode ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E)),
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTimeChip(timeRemaining, timeColor, isDarkMode, isPokemonMode),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      isPokemonMode ? Icons.catching_pokemon : Icons.schedule_rounded,
                                      size: 16,
                                      color: isPokemonMode
                                          ? timeColor.withOpacity(0.8)
                                          : (isDarkMode ? const Color(0xFF8B949E) : Colors.grey[500]),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('EEE, MMM d • h:mm a').format(widget.event.startTime),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isPokemonMode
                                            ? Colors.white70
                                            : (isDarkMode ? const Color(0xFF8B949E) : Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.event.description != null &&
                                    widget.event.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.event.description!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isPokemonMode
                                          ? Colors.white54
                                          : (isDarkMode ? const Color(0xFF6E7681) : Colors.grey[500]),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              _buildAlarmIcon(timeRemaining, timeColor, isDarkMode, isPokemonMode),
                              const SizedBox(height: 16),
                              _buildDeleteButton(isDarkMode, isPokemonMode),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPokemonIndicator(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.4 * value),
                color.withOpacity(0.1 * value),
              ],
            ),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4 * value),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getPokemonEmoji(),
              style: TextStyle(fontSize: 22 * value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeIndicator(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 5,
          height: 80 * value,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.3)],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeChip(Duration duration, Color color, bool isDark, bool isPokemonMode) {
    final isUrgent = duration.inMinutes < 30 && !duration.isNegative;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isPokemonMode
            ? color.withOpacity(0.3)
            : color.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(isPokemonMode ? 0.8 : 0.4),
          width: isPokemonMode ? 1.5 : 1,
        ),
        boxShadow: isUrgent || isPokemonMode
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUrgent) ...[
            Icon(
              isPokemonMode ? Icons.local_fire_department : Icons.priority_high,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formatTimeRemaining(duration, isPokemonMode),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isPokemonMode ? Colors.white : color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmIcon(Duration duration, Color color, bool isDark, bool isPokemonMode) {
    final isUrgent = duration.inMinutes < 30 && !duration.isNegative;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isUrgent ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 0.1 * (DateTime.now().millisecond % 2 == 0 ? 1 : -1),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isPokemonMode
                  ? RadialGradient(
                      colors: [
                        color.withOpacity(0.4),
                        color.withOpacity(0.1),
                      ],
                    )
                  : null,
              color: isPokemonMode ? null : color.withOpacity(isDark ? 0.15 : 0.1),
              border: isPokemonMode ? Border.all(color: color, width: 1.5) : null,
              boxShadow: isUrgent || isPokemonMode
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isPokemonMode
                  ? (isUrgent ? Icons.local_fire_department : Icons.catching_pokemon)
                  : (isUrgent ? Icons.alarm_on : Icons.notifications_active_rounded),
              size: 20,
              color: color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(bool isDark, bool isPokemonMode) {
    final deleteColor = isPokemonMode
        ? const Color(0xFFFF5722)
        : (isDark ? const Color(0xFFFF5252) : const Color(0xFFE53935));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _animateDelete,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: deleteColor.withOpacity(isPokemonMode ? 0.25 : 0.12),
            border: isPokemonMode ? Border.all(color: deleteColor.withOpacity(0.5), width: 1) : null,
          ),
          child: Icon(
            isPokemonMode ? Icons.catching_pokemon : Icons.delete_outline_rounded,
            size: 18,
            color: deleteColor,
          ),
        ),
      ),
    );
  }
}
