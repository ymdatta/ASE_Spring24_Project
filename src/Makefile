SHELL     := bash 
MAKEFLAGS += --warn-undefined-variables
.SILENT: 

define css
p,h2,h3   { text-align: right;} 
h2        { padding-top: 2px; border-top: 1px dotted #888; }
.docs pre {font-size: 8pt; }
endef
export css

define header
</h1>
<p>
<a href="https://timm.github.io/min/index.html">home</a>
:: <a href="https://github.com/timm/min/blob/main/CONTRIBUTE.md">notes</a>
:: <a href="https://github.com/timm/min">github</a> 
:: <a href="https://github.com/timm/min/issues">issues</a> 
:: <a href="lib.html">lib</a>
<br><img src="refactor.png" width=400>
</div>
endef
export header
	 
help:  ## show help
	awk 'BEGIN {FS = ":.*?## "; print "\nmake [WHAT]" } \
			/^[a-zA-Z_0-9-]+:.*?## / {printf "   \033[36m%-10s\033[0m : %s\n", $$1, $$2} \
			' $(MAKEFILE_LIST)


FILES=$(wildcard *.lua)
docs: $(addprefix ../docs/, $(FILES:.lua=.html))  ## update docs/*.html

../docs/%.html : %.lua ## make doc
	pycco -d ../docs $^ 
	gawk -v head="$$header" \
		'sub(/<\/h1><\/div>/,"") {print $$0 head;next} 1 \
		' $@ > _tmp; mv _tmp $@
	echo "$$css" >> ../docs/pycco.css
	git  add  $@

count1: ## simple count from cli file
	lua count.lua -r mid -f data/diabetes.csv
	lua count.lua -r div -f data/diabetes.csv

count2:  ## simple count from standard input
	cat data/diabetes.csv | lua count.lua -r mid  
	cat data/diabetes.csv | lua count.lua -r div 