import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../theme/brand_colors.dart';

/// Boc quanh mot widget (vd. thanh vi) — khi gameState.balance TANG, ban 4
/// dong xu bay len 28px + mo dan tu vi tri so du, roi tu dong don dep.
/// Khong dung timer lap: 1 AnimationController one-shot moi lan kich hoat.
class CoinBurst extends StatefulWidget {
  final Widget child;
  const CoinBurst({super.key, required this.child});

  @override
  State<CoinBurst> createState() => _CoinBurstState();
}

const _kCoinOffsets = [-12.0, -4.0, 4.0, 12.0];
const _kCoinCount = 4;
const _kStaggerMs = 60;
const _kRiseMs = 500;
const _kTotalMs = _kRiseMs + _kStaggerMs * (_kCoinCount - 1);

class _CoinBurstState extends State<CoinBurst>
    with SingleTickerProviderStateMixin {
  double? _lastBalance;
  AnimationController? _burstCtrl;

  void _trigger() {
    if (!mounted || _burstCtrl != null) return;
    if (MediaQuery.of(context).disableAnimations) return;
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _kTotalMs));
    setState(() => _burstCtrl = ctrl);
    ctrl.forward().whenComplete(() {
      if (mounted) setState(() => _burstCtrl = null);
      ctrl.dispose();
    });
  }

  @override
  void dispose() {
    _burstCtrl?.dispose();
    super.dispose();
  }

  Widget _coin(int i) {
    final startMs = i * _kStaggerMs;
    final anim = CurvedAnimation(
      parent: _burstCtrl!,
      curve: Interval(startMs / _kTotalMs, (startMs + _kRiseMs) / _kTotalMs,
          curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) => Transform.translate(
        offset: Offset(_kCoinOffsets[i], -28 * anim.value),
        child: Opacity(
          opacity: 1 - anim.value,
          child: const Icon(Icons.monetization_on, size: 14, color: kGold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final balance = gameState.balance;
        if (_lastBalance != null && balance > _lastBalance!) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _trigger());
        }
        _lastBalance = balance;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_burstCtrl != null)
              Positioned(
                left: 26,
                top: 2,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < _kCoinCount; i++) _coin(i),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
