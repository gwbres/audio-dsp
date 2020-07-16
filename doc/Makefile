PDFLATEX = /usr/bin/pdflatex

RM = rm -rf

all: documentation.pdf

documentation.pdf: documentation.tex
	$(PDFLATEX) $<
	$(PDFLATEX) $<

.PHONY: clean
clean:
	$(RM) *.out *.aux *.toc *.log *.pdf
