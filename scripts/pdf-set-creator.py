#!/usr/bin/python
# coding: utf-8

# pdf_creator.py - change PDF creator string
# VikingOSX, 2017-06-30, Apple Support Communities

from Foundation import NSURL, NSMutableDictionary
from Quartz import PDFDocument, PDFDocumentCreatorAttribute
import os
import sys


def main():

    if len(sys.argv) != 4:
        print("Usage: {} in.pdf out.pdf \"creator string\"".format(__file__))
        sys.exit(1)

    in_PDF = os.path.expanduser(sys.argv[1])
    out_PDF = os.path.expanduser(sys.argv[2])
    creator_str = sys.argv[3]

    fn = os.path.expanduser(in_PDF)
    url = NSURL.fileURLWithPath_(fn)
    pdfdoc = PDFDocument.alloc().initWithURL_(url)

    attrs = (NSMutableDictionary.alloc()
             .initWithDictionary_(pdfdoc.documentAttributes()))
    attrs[PDFDocumentCreatorAttribute] = creator_str

    pdfdoc.setDocumentAttributes_(attrs)
    pdfdoc.writeToFile_(out_PDF)


if __name__ == "__main__":
    sys.exit(main())
