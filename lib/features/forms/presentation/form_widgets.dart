import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/basya_components.dart';
import '../domain/form_preview.dart';

class FormNotice extends StatelessWidget {
  const FormNotice(this.message, {super.key, this.title, this.warning = false});
  final String message;
  final String? title;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF8EB) : AppTheme.neutralSurface,
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.info_outline : Icons.info_outline_rounded,
          size: 22,
          color: warning ? AppTheme.warning : AppTheme.teal,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class FormSection extends StatelessWidget {
  const FormSection(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.muted,
            ),
          ),
        ],
      ],
    ),
  );
}

class FormValue extends StatelessWidget {
  const FormValue(this.label, this.value, {super.key, this.prominent = false});
  final String label;
  final String value;
  final bool prominent;
  @override
  Widget build(BuildContext context) => prominent
      ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutralSurface,
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppTheme.muted),
              ),
              const SizedBox(height: 6),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.readOnlySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        );
}

InputDecoration formDecoration(
  String label, {
  String? hint,
  String? helper,
  Widget? suffix,
  String? prefix,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  helperText: helper,
  helperMaxLines: 4,
  errorMaxLines: 4,
  floatingLabelBehavior: FloatingLabelBehavior.always,
  labelStyle: const TextStyle(fontSize: 16, color: AppTheme.ink),
  floatingLabelStyle: const TextStyle(fontSize: 16, color: AppTheme.ink),
  hintStyle: const TextStyle(fontSize: 15, color: AppTheme.muted),
  filled: true,
  fillColor: Colors.white,
  suffixIcon: suffix,
  prefixText: prefix,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
);

class BasyaChoiceField extends StatelessWidget {
  const BasyaChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.helper,
  });
  final String label;
  final List<String> options;
  final String? value;
  final String? helper;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: value,
    validator: (_) => value == null ? 'Pilih ${label.toLowerCase()}.' : null,
    builder: (field) => Semantics(
      button: true,
      label: label,
      value: value ?? 'Belum dipilih',
      child: _FormControlFocus(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            final selected = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              useSafeArea: true,
              builder: (sheetContext) => SafeArea(
                top: false,
                child: SizedBox(
                  height: MediaQuery.sizeOf(sheetContext).height * .65,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Tutup pilihan',
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: options.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            title: Text(options[index]),
                            selected: options[index] == value,
                            trailing: options[index] == value
                                ? const Icon(Icons.check, color: AppTheme.teal)
                                : null,
                            onTap: () =>
                                Navigator.pop(sheetContext, options[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            if (selected != null && context.mounted) {
              field.didChange(selected);
              onChanged(selected);
            }
          },
          child: InputDecorator(
            decoration: formDecoration(
              label,
              helper: helper,
              suffix: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.teal,
              ),
            ).copyWith(errorText: field.errorText),
            child: Text(
              value ?? 'Pilih ${label.toLowerCase()}',
              style: TextStyle(
                fontSize: 16,
                color: value == null ? AppTheme.muted : AppTheme.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class BasyaDateField extends StatelessWidget {
  const BasyaDateField({
    super.key,
    required this.label,
    required this.onChanged,
    this.value,
    this.pastOnly = false,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool pastOnly;
  String get display => value == null
      ? 'Pilih tanggal'
      : '${value!.day} ${FormPreview.months[value!.month - 1]} ${value!.year}';

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    initialValue: value,
    validator: (_) => value == null ? 'Pilih ${label.toLowerCase()}.' : null,
    builder: (field) => _FormControlFocus(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          final now = DateTime.now();
          final chosen = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: pastOnly ? now : DateTime(now.year + 50),
            helpText: label,
            cancelText: 'Batal',
            confirmText: 'Pilih',
          );
          if (chosen != null && context.mounted) {
            field.didChange(chosen);
            onChanged(chosen);
          }
        },
        child: Semantics(
          button: true,
          label: label,
          value: display,
          child: InputDecorator(
            decoration: formDecoration(
              label,
              suffix: const Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.teal,
                size: 21,
              ),
            ).copyWith(errorText: field.errorText),
            child: Text(
              display,
              style: TextStyle(
                fontSize: 16,
                color: value == null ? AppTheme.muted : AppTheme.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FormControlFocus extends StatefulWidget {
  const _FormControlFocus({required this.child});
  final Widget child;
  @override
  State<_FormControlFocus> createState() => _FormControlFocusState();
}

class _FormControlFocusState extends State<_FormControlFocus> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (value) => setState(() => _focused = value),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _focused
            ? const [BoxShadow(color: AppTheme.ink, spreadRadius: 3)]
            : null,
      ),
      child: Material(color: Colors.transparent, child: widget.child),
    ),
  );
}

class LocalAttachment {
  const LocalAttachment({
    required this.name,
    required this.bytes,
    required this.isImage,
  });
  final String name;
  final Uint8List bytes;
  final bool isImage;
}

typedef AttachmentPicker = Future<XFile?> Function(List<XTypeGroup> types);

class BasyaAttachmentField extends StatefulWidget {
  const BasyaAttachmentField({
    super.key,
    required this.label,
    required this.onChanged,
    this.pdfOnly = false,
    this.imageOnly = false,
    this.required = true,
    this.picker,
  });
  final String label;
  final ValueChanged<LocalAttachment?> onChanged;
  final bool pdfOnly;
  final bool imageOnly;
  final bool required;
  final AttachmentPicker? picker;

  @override
  State<BasyaAttachmentField> createState() => _BasyaAttachmentFieldState();
}

class _BasyaAttachmentFieldState extends State<BasyaAttachmentField> {
  final _field = GlobalKey<FormFieldState<LocalAttachment>>();
  LocalAttachment? _attachment;
  String? _pickError;
  bool _picking = false;
  int get _maxMb => widget.pdfOnly ? 10 : 5;
  List<String> get _extensions => widget.pdfOnly
      ? ['pdf']
      : ['jpg', 'jpeg', 'png', if (!widget.imageOnly) 'pdf'];

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _pickError = null;
    });
    try {
      final types = [
        XTypeGroup(
          label: widget.label,
          extensions: _extensions,
          mimeTypes: [
            if (!widget.pdfOnly) ...['image/jpeg', 'image/png'],
            if (!widget.imageOnly) 'application/pdf',
          ],
          uniformTypeIdentifiers: [
            if (!widget.pdfOnly) ...['public.jpeg', 'public.png'],
            if (!widget.imageOnly) 'com.adobe.pdf',
          ],
        ),
      ];
      final file =
          await (widget.picker?.call(types) ??
              openFile(acceptedTypeGroups: types));
      if (file == null || !mounted) return;
      final extension = file.name.split('.').last.toLowerCase();
      final length = await file.length();
      if (!_extensions.contains(extension)) {
        throw FormatException(
          'Pilih berkas ${_extensions.join(', ').toUpperCase()}.',
        );
      }
      if (length == 0 || length > _maxMb * 1024 * 1024) {
        throw FormatException(
          'Pilih berkas yang tidak kosong dan maksimal $_maxMb MB.',
        );
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final attachment = LocalAttachment(
        name: file.name,
        bytes: bytes,
        isImage: extension != 'pdf',
      );
      setState(() => _attachment = attachment);
      _field.currentState?.didChange(attachment);
      widget.onChanged(attachment);
    } on FormatException catch (error) {
      if (mounted) setState(() => _pickError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _pickError = 'Berkas tidak dapat dibuka. Coba pilih berkas lain.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => FormField<LocalAttachment>(
    key: _field,
    validator: (value) => widget.required && value == null
        ? 'Pilih ${widget.label.toLowerCase()}.'
        : null,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label}${widget.required ? '' : ' (opsional)'}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutralSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_attachment?.isImage == true) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _attachment!.bytes,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    semanticLabel: 'Pratinjau ${widget.label.toLowerCase()}',
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Pratinjau tidak tersedia. Pilih gambar lain jika berkas rusak.',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _attachment == null
                        ? Icons.upload_file_outlined
                        : Icons.description_outlined,
                    color: AppTheme.teal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachment?.name ?? 'Pilih berkas dari perangkat',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _attachment == null
                    ? '${_extensions.join(', ').toUpperCase()} · Maks. $_maxMb MB'
                    : '${(_attachment!.bytes.length / 1024).ceil()} KB · Hanya tersimpan selama form terbuka',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _picking ? null : _pick,
                    icon: const Icon(Icons.attach_file, size: 19),
                    label: Text(
                      _picking
                          ? 'Membuka berkas…'
                          : _attachment == null
                          ? 'Pilih berkas'
                          : 'Ganti berkas',
                    ),
                  ),
                  if (_attachment != null)
                    TextButton(
                      onPressed: _picking
                          ? null
                          : () {
                              setState(() {
                                _attachment = null;
                                _pickError = null;
                              });
                              field.didChange(null);
                              widget.onChanged(null);
                            },
                      child: const Text('Hapus'),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_pickError != null || field.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _pickError ?? field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class FormReviewSheet extends StatelessWidget {
  const FormReviewSheet({super.key, required this.title, required this.values});
  final String title;
  final Map<String, String> values;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tinjau $title',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Kembali ke form',
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in values.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const FormNotice(
              'Ini pratinjau frontend. Konfirmasi tidak mengirim transaksi atau mengubah data akun.',
              title: 'Mode demo',
            ),
            const SizedBox(height: 20),
            BasyaActionButton(
              label: 'Konfirmasi demo',
              expand: true,
              labelSize: 16,
              style: BasyaActionStyle.emphasis,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali dan ubah'),
            ),
          ],
        ),
      ),
    ),
  );
}
