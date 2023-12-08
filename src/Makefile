SHELL     := bash 
MAKEFLAGS += --warn-undefined-variables
.SILENT: 

define css
p,h2,h3   { text-align: right;} 
h2        { padding-top: 2px; border-top: 1px dotted #888; }
.docs pre {font-size: 8pt; }
#forkongithub a{background:#000; color:#fff; text-decoration:none;
font-family:arial,sans-serif; text-align:center; font-weight:bold;
padding:5px 40px; font-size:1rem; line-height:2rem; position:relative;
transition:0.5s; }#forkongithub a:hover{background:#c11; color:#fff;
}#forkongithub a::before,#forkongithub a::after{content:""; width:100%;
display:block; position:absolute; top:1px; left:0; height:1px;
background:#fff; }#forkongithub a::after{bottom:1px; top:auto;
}@media screen and (min-width:800px){#forkongithub{position:absolute;
display:block; top:0; right:0; width:200px; overflow:hidden;
height:200px; z-index:9999; }#forkongithub a{width:200px;
position:absolute; top:60px; right:-60px; transform:rotate(45deg);
-webkit-transform:rotate(45deg); -ms-transform:rotate(45deg);
-moz-transform:rotate(45deg); -o-transform:rotate(45deg); box-shadow:4px
4px 10px rgba(0,0,0,0.8); }}
endef
export css

define banner
<span id="forkongithub"><a href="https://github.com/timm/lo">Fork me on GitHub</a></span>
endef
export banner

define  header
&copy; 2023 Tim Menzies, <a href="mailto:timm@ieee.org">timm@ieee.org</a>, 
<a href="https://github.com/timm/lo/blob/main/LICENSE.md">BSD-2</a><br>
<a href="https://timm.github.io/lo/index.html">home</a>
:: <a href="https://github.com/timm/lo/blob/main/CONTRIBUTE.md">notes</a>
:: <a href="https://github.com/timm/lo/issues">issues</a> 
:: <a href="lib.html">lib</a>
<center><img src="refactor.png" width=500></center>
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
		'!p && sub(/<p>/,"") {p=1; print head  $$0; next} \
	  	/^<body>/ { print $$0 " " banner; next } \
			1  ' $@ > _tmp; mv _tmp $@
	echo "$$css" >> ../docs/pycco.css
	git  add  $@

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
