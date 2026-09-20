import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class CodeViewer extends StatefulWidget {
  final String code;
  final String language; // 'smali', 'java', 'xml'
  final List<int> highlightedLines;
  final String? searchQuery;

  const CodeViewer({
    super.key,
    required this.code,
    this.language = 'smali',
    this.highlightedLines = const [],
    this.searchQuery,
  });

  @override
  State<CodeViewer> createState() => _CodeViewerState();
}

class _CodeViewerState extends State<CodeViewer> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Color _getSyntaxColor(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#') || trimmed.startsWith('//')) {
      return AppColors.comment;
    }
    if (trimmed.startsWith('.') || trimmed.startsWith('@')) {
      return AppColors.annotation;
    }
    if (trimmed.startsWith('invoke-') ||
        trimmed.startsWith('new-instance') ||
        trimmed.startsWith('const') ||
        trimmed.startsWith('return') ||
        trimmed.startsWith('iput-') ||
        trimmed.startsWith('iget-') ||
        trimmed.startsWith('sput-') ||
        trimmed.startsWith('sget-')) {
      return AppColors.keyword;
    }
    if (trimmed.startsWith('public') ||
        trimmed.startsWith('private') ||
        trimmed.startsWith('protected') ||
        trimmed.startsWith('class') ||
        trimmed.startsWith('void') ||
        trimmed.startsWith('import') ||
        trimmed.startsWith('package')) {
      return AppColors.keyword;
    }
    if (trimmed.contains('"')) {
      return AppColors.string;
    }
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.code.split('\n');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.codeBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    widget.language.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${lines.length} lines',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 15, color: AppColors.textSecondary),
                  tooltip: 'Copy Code',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Code content with line numbers
          Expanded(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: Scrollbar(
                  controller: _horizontalController,
                  notificationPredicate: (notif) => notif.depth == 1,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(lines.length, (index) {
                          final lineNum = index + 1;
                          final line = lines[index];
                          final isHighlighted = widget.highlightedLines.contains(lineNum);
                          final isMatch = widget.searchQuery != null &&
                              widget.searchQuery!.isNotEmpty &&
                              line.toLowerCase().contains(widget.searchQuery!.toLowerCase());

                          return Container(
                            color: isMatch
                                ? AppColors.warning.withValues(alpha: 0.2)
                                : (isHighlighted
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : Colors.transparent),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1.5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '$lineNum',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: AppColors.codeLineNumber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  line.isEmpty ? ' ' : line,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: _getSyntaxColor(line),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
