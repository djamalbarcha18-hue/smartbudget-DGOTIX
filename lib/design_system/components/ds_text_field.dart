import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smartbudget/design_system/components/latin_digits_formatter.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';

/// Standardized text input for the DGOTIX design system.
class DsTextField extends StatefulWidget {
  const DsTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<DsTextField> createState() => _DsTextFieldState();
}

class _DsTextFieldState extends State<DsTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: DsRadius.brMd,
          borderSide: BorderSide(color: color),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: t.labelMedium?.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          autofillHints: widget.autofillHints,
          inputFormatters: <TextInputFormatter>[
            const LatinDigitsFormatter(),
            ...?widget.inputFormatters,
          ],
          onFieldSubmitted: widget.onSubmitted,
          style: t.bodyMedium?.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: t.bodyMedium?.copyWith(color: c.textFaint),
            filled: true,
            fillColor: c.surfaceMuted,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 18, color: c.textMuted),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: c.textMuted,
                    ),
                  )
                : null,
            enabledBorder: border(c.border),
            focusedBorder: border(c.brand),
            errorBorder: border(c.expense),
            focusedErrorBorder: border(c.expense),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
