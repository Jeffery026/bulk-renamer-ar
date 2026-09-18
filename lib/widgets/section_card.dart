import 'package:flutter/material.dart';

class OpSection extends StatelessWidget {
  final String title;
  final Color labelColor;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const OpSection({
    super.key,
    required this.title,
    required this.labelColor,
    required this.enabled,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(title, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const Spacer(),
          Switch(value: enabled, onChanged: onToggle),
        ]),
        AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !enabled,
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.all(12), child: child),
            ),
          ),
        ),
      ]),
    );
  }
}

class TxtField extends StatefulWidget {
  final String initial;
  final String label;
  final String hint;
  final void Function(String) onChanged;
  final TextInputType keyboardType;

  const TxtField({
    super.key,
    required this.initial,
    required this.label,
    this.hint = '',
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<TxtField> createState() => _TxtFieldState();
}

class _TxtFieldState extends State<TxtField> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
      onChanged: widget.onChanged,
    );
  }
}
