SHELL     := bash 
MAKEFLAGS += --warn-undefined-variables
.SILENT: 

define css
p         { text-align: right;}
xh2       { border-top: solid  1px #DDD !important;}
h3        { padding: 3px; color: #3E3B39;
						background-image: linear-gradient(to right, #DDD , white 75%); }
.docs pre {font-size: 8pt; }
endef
export css

define banner
<span id="forkongithub"><a href="https://github.com/timm/lo">Fork me on GitHub</a></span>
endef
export banner

#Lo is less. <a href="https://github.com/timm/lo/blob/main/README.md#less">Less is more</a>. So go lo. <br>
# Cluster data to lower dimensions. Just reason about those clusters.
define  header
<center>
<a href="http://github.com/timm/lo"><img align=center  height=25 src="github.png"></a>
:: <a href="https://timm.github.io/lo/index.html">home</a>
:: <a href="https://github.com/timm/lo/blob/main/CONTRIBUTE.md">doc</a>
:: <a href="https://github.com/timm/lo/issues">issues</a><hr>
<a href="https://github.com/timm/lo/blob/main/LICENSE.md">&copy; 2023</a> 
Tim Menzies, <a href="mailto:timm@ieee.org">timm@ieee.org</a>
  </center>
endef
export header

#		 !b && sub(/<div class=.section.>/,"") {b=1; print $$0 "\n" banner ;next} \

help:  ## show help
	awk 'BEGIN {FS = ":.*?## "; print "\nmake [WHAT]" } \
			/^[a-zA-Z_0-9-]+:.*?## / {printf "   \033[36m%-10s\033[0m : %s\n", $$1, $$2} \
			' $(MAKEFILE_LIST)

install: ## install lua on {debian, ubuntu, codespaces}
	sudo apt update
	sudo apt install lua5.3

saved: ## save and push  to main branch 
	read -p "commit msg> " x; git commit -am "$$x"; git push;git status

FILES=$(wildcard *.lua)
docs: $(addprefix ../docs/, $(FILES:.lua=.html))  $(addprefix ~/tmp/, $(FILES:.lua=.pdf))  ## update docs/*.html


../docs/%.html : %.lua ## make doc
	pycco -d ../docs $^ 
	gawk -v head="$$header" -v banner="$$banner" \
		'!p && sub(/<p>/,"") {p=1; print $$0 head  ; next} \
			1  ' $@ > _tmp; mv _tmp $@
	echo "$$css" >> ../docs/pycco.css
	git  add  $@

~/tmp/%.pdf: %.lua  ## make pdf
	mkdir -p ~/tmp
	echo "a2ps: $^ -> $@" 
	a2ps                          \
		-qBr                         \
		--chars-per-line 90           \
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

eggate: ## basic demo of GATE
	lua gate.lua -t gate |column -t

eggate20: ## run gate*20 (with different random seeds)
	lua gate.lua -s $$RANDOM -t gate20 | sort -n 

egs:
	make -B  ~/tmp/auto93.out   ~/tmp/coc10000.out   ~/tmp/healthCloseIsses12mths0011-easy.out  ~/tmp/pom.out \
~/tmp/china.out      ~/tmp/nasa93dem.out     \
~/tmp/coc1000.out    ~/tmp/healthCloseIsses12mths0001-hard.out  ~/tmp/nasa93demNums.out                       ../data/weather.csv

~/tmp/%.out : ../data/%.csv
	echo $@
	lua mylo.lua -s $$RANDOM -f $^  -t rules    > $@; cat $@