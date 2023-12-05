SHELL     := bash 
MAKEFLAGS += --warn-undefined-variables
.SILENT: 

define css
p,h2,h3 { text-align: right;} 
h2      { padding-top: 2px; border-top: 1px dotted #888; }
endef
export css

help:  ## show help
	awk 'BEGIN {FS = ":.*?## "; print "\nmake [WHAT]" } \
			/^[a-zA-Z_0-9-]+:.*?## / {printf "   \033[36m%-10s\033[0m : %s\n", $$1, $$2} \
			' $(MAKEFILE_LIST)

docs: ../docs/count.html ../docs/counts.html ../docs/index.html \
      ../docs/lib.html   ../docs/bayes.html

../docs/%.html : %.lua ## make doc
	echo "# making $@"
	pycco -d ../docs $^ 
	echo "$$css" >> ../docs/pycco.css
	open $@

count1: ## simple count from cli file
	lua count.lua -r mid -f data/diabetes.csv
	lua count.lua -r div -f data/diabetes.csv

count2:  ## simple count from standard input
	cat data/diabetes.csv | lua count.lua -r mid  
	cat data/diabetes.csv | lua count.lua -r div 