import os
import glob
import io
import argparse
from pypdf import PdfReader, PdfWriter

parser = argparse.ArgumentParser(
    description="Prepare documents by splitting PDFs into new files per page.",
    epilog="Example: parsepdfbypage.py '..\data\*' -v"
    )
parser.add_argument("file_path", help="Folder of files to be processed")
parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
args = parser.parse_args()

print("Processing files...")
for file in os.listdir(args.file_path):
    if args.verbose: print(f"Processing '{file}'")
    reader = PdfReader(os.path.join(args.file_path, file))
    pages = reader.pages
    for i in range(len(pages)):
        output_filename = os.path.splitext(os.path.basename(file))[0] + f"-{i}" + ".pdf"
        if args.verbose: print(f"\tCreating new file for page {i} -> {output_filename}")
        f = io.BytesIO()
        writer = PdfWriter()
        writer.add_page(pages[i])
        with open(os.path.join(args.file_path, output_filename), "wb") as out:
                    writer.write(out)