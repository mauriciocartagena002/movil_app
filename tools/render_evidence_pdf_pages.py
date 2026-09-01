from pathlib import Path

import fitz
from PIL import Image, ImageDraw, ImageOps


PDF = Path("docs/Informe_GymPro_Flutter_con_Evidencias.pdf")
OUT = Path("docs/rendered_gympro_evidencias")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(PDF)
    page_paths = []
    for index, page in enumerate(doc, start=1):
        pix = page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5), alpha=False)
        path = OUT / f"page-{index}.png"
        pix.save(path)
        page_paths.append(path)

    thumbs = []
    for index, path in enumerate(page_paths, start=1):
        img = Image.open(path).convert("RGB")
        img.thumbnail((260, 340))
        canvas = Image.new("RGB", (280, 380), "white")
        x = (280 - img.width) // 2
        canvas.paste(img, (x, 20))
        draw = ImageDraw.Draw(canvas)
        draw.text((16, 352), f"Pagina {index}", fill=(30, 30, 30))
        thumbs.append(ImageOps.expand(canvas, border=1, fill=(190, 190, 190)))

    cols = 3
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * 282, rows * 382), "white")
    for index, img in enumerate(thumbs):
        x = (index % cols) * 282
        y = (index // cols) * 382
        sheet.paste(img, (x, y))
    sheet.save(OUT / "contact-sheet.png")
    print(len(page_paths))
    print(OUT / "contact-sheet.png")


if __name__ == "__main__":
    main()
