import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class RichEmailEditor extends StatefulWidget {
  const RichEmailEditor({
    super.key,
    required this.onHtmlChanged,
    this.initialHtml,
    this.minLines = 8,
  });

  final String? initialHtml;
  final int minLines;
  final ValueChanged<String> onHtmlChanged;

  @override
  State<RichEmailEditor> createState() => _RichEmailEditorState();
}

class _RichEmailEditorState extends State<RichEmailEditor> {
  late final TextEditingController _controller;
  bool _htmlMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialHtml ?? '');
    _controller.addListener(_emitHtml);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_emitHtml)
      ..dispose();
    super.dispose();
  }

  void _emitHtml() {
    widget.onHtmlChanged(_controller.text.trim());
  }

  void _wrapSelection(String openTag, String closeTag) {
    final selection = _controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      final insertAt = selection.isValid ? selection.baseOffset : 0;
      final updated = _controller.text.replaceRange(
        insertAt,
        insertAt,
        '$openTag$closeTag',
      );
      _controller.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: insertAt + openTag.length),
      );
      return;
    }

    final selected = selection.textInside(_controller.text);
    final updated = _controller.text.replaceRange(
      selection.start,
      selection.end,
      '$openTag$selected$closeTag',
    );
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection(
        baseOffset: selection.start + openTag.length,
        extentOffset: selection.end + openTag.length,
      ),
    );
  }

  void _insertBlock(String html) {
    final selection = _controller.selection;
    final insertAt = selection.isValid
        ? selection.baseOffset
        : _controller.text.length;
    final prefix =
        insertAt > 0 && !_controller.text.substring(0, insertAt).endsWith('\n')
        ? '\n'
        : '';
    final updated = _controller.text.replaceRange(
      insertAt,
      insertAt,
      '$prefix$html\n',
    );
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: insertAt + prefix.length + html.length + 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        children: [
          _EditorToolbar(
            htmlMode: _htmlMode,
            onToggleMode: () => setState(() => _htmlMode = !_htmlMode),
            onBold: () => _wrapSelection('<strong>', '</strong>'),
            onItalic: () => _wrapSelection('<em>', '</em>'),
            onUnderline: () => _wrapSelection('<u>', '</u>'),
            onParagraph: () => _insertBlock('<p></p>'),
            onList: () => _insertBlock('<ul><li></li></ul>'),
            onLink: () => _wrapSelection('<a href="">', '</a>'),
          ),
          Divider(height: 1, color: context.modeBorder),
          TextField(
            controller: _controller,
            minLines: widget.minLines,
            maxLines: 12,
            cursorColor: context.modePrimary,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              height: 1.4,
              color: context.modeTextPrimary,
              fontFamily: _htmlMode ? 'monospace' : null,
            ),
            decoration: InputDecoration(
              hintText: _htmlMode
                  ? '<p>Write or paste your HTML email here...</p>'
                  : 'Write the email body. Use the toolbar to add HTML formatting.',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.htmlMode,
    required this.onToggleMode,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onParagraph,
    required this.onList,
    required this.onLink,
  });

  final bool htmlMode;
  final VoidCallback onToggleMode;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onParagraph;
  final VoidCallback onList;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: onBold,
          ),
          _ToolButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: onItalic,
          ),
          _ToolButton(
            icon: Icons.format_underlined,
            tooltip: 'Underline',
            onPressed: onUnderline,
          ),
          _ToolButton(
            icon: Icons.format_align_left,
            tooltip: 'Paragraph',
            onPressed: onParagraph,
          ),
          _ToolButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'List',
            onPressed: onList,
          ),
          _ToolButton(icon: Icons.link, tooltip: 'Link', onPressed: onLink),
          const Spacer(),
          Tooltip(
            message: htmlMode ? 'HTML mode' : 'Rich editor mode',
            child: TextButton.icon(
              onPressed: onToggleMode,
              icon: AppIcon(
                htmlMode ? Icons.code_off : Icons.code,
                size: 18,
                color: context.modePrimary,
              ),
              label: Text(
                htmlMode ? 'HTML' : 'Rich',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.modePrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: AppIcon(icon, size: 19, color: context.modeTextPrimary),
      onPressed: onPressed,
    );
  }
}
