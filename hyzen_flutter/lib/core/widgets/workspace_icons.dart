import 'package:flutter/material.dart';

/// Equal-cell generated artwork; one cached sheet, no per-icon file decoding.
enum WorkspaceGlyph {
  notes,
  papers,
  books,
  mcqs,
  scan,
  gallery,
  pdf,
  word,
  slides,
  edit,
  crop,
  signature,
  settings,
  back,
  share,
  panda,
}

class WorkspaceIcon extends StatelessWidget {
  const WorkspaceIcon(this.glyph, {super.key, this.size = 28});
  final WorkspaceGlyph glyph;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -(glyph.index % 4) * size,
            top: -(glyph.index ~/ 4) * size,
            width: size * 4,
            height: size * 4,
            child: Image.asset(
              'assets/reference/workspace-icons.png',
              fit: BoxFit.fill,
              cacheWidth: 1024,
            ),
          ),
        ],
      ),
    ),
  );
}

WorkspaceGlyph? glyphForIcon(IconData icon) {
  if ([
    Icons.picture_as_pdf_rounded,
    Icons.picture_as_pdf_outlined,
    Icons.picture_as_pdf,
  ].contains(icon)) {
    return WorkspaceGlyph.pdf;
  }
  if ([Icons.article_rounded, Icons.description_outlined].contains(icon)) {
    return WorkspaceGlyph.word;
  }
  if (icon == Icons.slideshow_rounded) {
    return WorkspaceGlyph.slides;
  }
  if ([Icons.menu_book_rounded, Icons.auto_stories_rounded].contains(icon)) {
    return WorkspaceGlyph.books;
  }
  if (icon == Icons.quiz_rounded) {
    return WorkspaceGlyph.mcqs;
  }
  if (icon == Icons.history_edu_rounded) {
    return WorkspaceGlyph.papers;
  }
  return null;
}
