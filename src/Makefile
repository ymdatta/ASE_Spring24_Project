SHELL     := bash 
MAKEFLAGS += --warn-undefined-variables
.SILENT: 

define css
p,h2,h3   { text-align: right;}
hr        { background-color: #EEE !important;
    color: #EEE !important
    border: solid 1px #EEE !important;
    height: 1px !important; }
.docs pre {font-size: 8pt; }
endef
export css

define banner
<span id="forkongithub"><a href="https://github.com/timm/lo">Fork me on GitHub</a></span>
endef
export banner

define  header
Lo is less. <a href="https://github.com/timm/lo/blob/main/README.md#less">Less is more.</a> <br>
&copy; 2023 Tim Menzies, <a href="mailto:timm@ieee.org">timm@ieee.org</a>, 
<a href="https://github.com/timm/lo/blob/main/LICENSE.md">BSD-2</a><br>
Cluster data to lower dimensions. Just reason about those clusters.<hr>
<center><a href="http://github.com/timm/lo"><img align=center  height=25 src="github.png"></a>
:: <a href="https://timm.github.io/lo/index.html">home</a>
:: <a href="https://github.com/timm/lo/blob/main/CONTRIBUTE.md">notes</a>
:: <a href="https://github.com/timm/lo/issues">issues</a> 
:: <a href="lib.html">lib</a>  </center><hr>
endef
export header

#		 !b && sub(/<div class=.section.>/,"") {b=1; print $$0 "\n" banner ;next} \

help:  ## show help
	awk 'BEGIN {FS = ":.*?## "; print "\nmake [WHAT]" } \
			/^[a-zA-Z_0-9-]+:.*?## / {printf "   \033[36m%-10s\033[0m : %s\n", $$1, $$2} \
			' $(MAKEFILE_LIST)

saved: ## save and push  to main brach 
	git add *;git commit -am save;git push;git status

FILES=$(wildcard *.lua)
docs: $(addprefix ../docs/, $(FILES:.lua=.html))  ## update docs/*.html

../docs/%.html : %.lua ## make doc
	pycco -d ../docs $^ 
	gawk -v head="$$header" -v banner="$$banner" \
		'!p && sub(/<p>/,"") {p=1; print $$0 head  ; next} \
			1  ' $@ > _tmp; mv _tmp $@
	echo "$$css" >> ../docs/pycco.css
	git  add  $@

~/tmp/%.pdf: %.lua 
	mkdir -p ~/tmp
	echo "pdf-ing $^ ... "
	a2ps                          \
		-Br                          \
		--chars-per-line 90          \
		--file-align=fill              \
		--line-numbers=1                \
		--borders=no                     \
		--pro=color                       \
		--columns  3                       \
		-M letter                           \
		--pretty-print="../etc/lua.ssh"   \
		-o ~/tmp/$^.ps $^ ;               \
	ps2pdf ~/tmp/$^.ps $@ ;  rm ~/tmp/$^.ps; \
  open $@

zero:
	lua zero.lua  -f ../data/zero.csv
	cat ../data/zero.csv | lua zero.lua

count1: ## simple count from cli file
	lua count.lua -r mid -f ../data/diabetes.csv
	lua count.lua -r div -f ../data/diabetes.csv

count2:  ## simple count from standard input
	cat ../data/diabetes.csv | lua count.lua -r mid  
	cat ../data/diabetes.csv | lua count.lua -r div 

counts: ## simple count from cli file
	cat ../data/diabetes.csv | lua counts.lua 
