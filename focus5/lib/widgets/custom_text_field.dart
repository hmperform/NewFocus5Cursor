import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLength;
  final int maxLines;
  final bool autofocus;
  final EdgeInsets contentPadding;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final Widget? prefix;
  final IconData? prefixIcon;
  final IconData? suffixIconData;
  final Widget? suffixIcon;
  final String? helpText;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
    this.maxLines = 1,
    this.autofocus = false,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.suffix,
    this.prefix,
    this.prefixIcon,
    this.suffixIconData,
    this.suffixIcon,
    this.helpText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: contentPadding,
            suffixIcon: suffixIcon ?? suffix ?? (suffixIconData != null ? Icon(suffixIconData) : null),
            prefixIcon: prefix ?? (prefixIcon != null ? Icon(prefixIcon) : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            helperText: helpText,
            helperStyle: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLength: maxLength,
          maxLines: maxLines,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
} 