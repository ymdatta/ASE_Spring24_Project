main: slides.pdf clean

slides.pdf: slides.tex 
	- pdflatex -shell-escape  -halt-on-error $^ | grep '^!.*' -A200 --color=always 
	- bibtex slides
	- pdflatex -shell-escape  -halt-on-error $^ | grep '^!.*' -A200 --color=always 
	- pdflatex -shell-escape  -halt-on-error $^ | grep '^!.*' -A200 --color=always 

clean:
	@rm -f *.aux  *.bbl *.bib *.blg *.nav   *.fdb_latexmk *.out  *.toc *.fls    *.vrb *.log  *.snm
