import 'package:flutter/material.dart';

import 'card_deck.dart';
import 'card_style.dart';
import 'theme.dart';

/// Name, colour and icon for one card.
///
/// The colour is the card's whole identity in the stack, so the sheet previews
/// the real thing at the top and updates it live as you pick — choosing from
/// swatches alone means guessing how a colour reads behind black text.
Future<DeckCard?> showCardEditor(BuildContext context, DeckCard card) {
  return showModalBottomSheet<DeckCard>(
    context: context,
    backgroundColor: DeckColors.strip,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _CardEditorSheet(card: card),
  );
}

class _CardEditorSheet extends StatefulWidget {
  const _CardEditorSheet({required this.card});

  final DeckCard card;

  @override
  State<_CardEditorSheet> createState() => _CardEditorSheetState();
}

class _CardEditorSheetState extends State<_CardEditorSheet> {
  late DeckCard _draft = widget.card;
  late final TextEditingController _name =
      TextEditingController(text: widget.card.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _preview(),
            const SizedBox(height: 18),
            _label('Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              style: const TextStyle(color: DeckColors.text, fontSize: 15),
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: DeckColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(name: value)),
            ),
            const SizedBox(height: 18),
            _label('Colour'),
            const SizedBox(height: 8),
            _swatches(),
            const SizedBox(height: 18),
            _label('Icon'),
            const SizedBox(height: 8),
            _icons(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colorOf(_draft.colorKey),
                  foregroundColor: DeckColors.onCard,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final trimmed = _name.text.trim();
    // An unnamed card is an unreadable sliver, so fall back rather than
    // letting the stack fill with blanks.
    Navigator.pop(
      context,
      _draft.copyWith(name: trimmed.isEmpty ? widget.card.name : trimmed),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: DeckColors.textDim,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

  /// The card as it will actually look in the stack.
  Widget _preview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 84,
      decoration: BoxDecoration(
        color: colorOf(_draft.colorKey),
        borderRadius: BorderRadius.circular(DeckMetrics.cardRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(iconOf(_draft.iconKey), size: 19, color: DeckColors.onCard),
          const Spacer(),
          Flexible(
            child: Text(
              _draft.name.trim().isEmpty ? widget.card.name : _draft.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: DeckColors.onCard,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatches() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in cardPalette)
          GestureDetector(
            onTap: () =>
                setState(() => _draft = _draft.copyWith(colorKey: color.key)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Color(color.value),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: _draft.colorKey == color.key
                      ? DeckColors.text
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: _draft.colorKey == color.key
                  ? const Icon(Icons.check_rounded,
                      size: 20, color: DeckColors.onCard)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _icons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final key in cardIconKeys)
          GestureDetector(
            onTap: () => setState(() => _draft = _draft.copyWith(iconKey: key)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _draft.iconKey == key
                    ? colorOf(_draft.colorKey)
                    : DeckColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: _draft.iconKey == key
                      ? Colors.transparent
                      : DeckColors.surfaceEdge,
                ),
              ),
              child: Icon(
                iconOf(key),
                size: 20,
                color: _draft.iconKey == key
                    ? DeckColors.onCard
                    : DeckColors.textDim,
              ),
            ),
          ),
      ],
    );
  }
}
