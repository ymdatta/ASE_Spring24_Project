main: book.pdf clean

book.pdf: book.tex 
	- pdflatex -shell-escape  -halt-on-error $^ | grep '^!.*' -A200 --color=always 
	- bibtex book
	- pdflatex -shell-escape  -halt-on-error $^ | grep '^!.*' -A200 --color=always 
	- pdflatex -shell-escape  -halt-on-error $^ | grep '^!.*' -A200 --color=always 

clean:
	@rm -f *.aux  *.bbl *.blg *.nav   *.fdb_latexmk *.out  *.toc *.fls    *.vrb *.log  *.snm
