---
title:  |
  ![](txt/cover.png){width=6.5in}\vspace{1cm}    
  **AI and SE: just the important bits**
author: Tim Menzies
date: \today
geometry: margin=1in
documentclass: article
fontsize: 8pt
header-includes: |
    \usepackage{graphicx}
    \usepackage{titlesec}\newcommand{\sectionbreak}{\clearpage}
    \usepackage{inconsolata}
    \usepackage{amssymb}
    \usepackage{pifont}
    \usepackage{array}
    \usepackage[T1]{fontenc}
    \usepackage{textcomp}
    \usepackage{mathpazo}
    \usepackage{fancyhdr}\pagestyle{fancy}
    \fancyhead[CO,CE]{}\fancyfoot[CO,CE]{}\fancyfoot[LE,RO]{\thepage}
    \BeforeBeginEnvironment{listings}{\par\noindent\begin{minipage}{\linewidth}}
    \AfterEndEnvironment{listings}{\end{minipage}\par\addvspace{\topskip}}
    \AddToHook{env/quote/before}{\small}
---

# AI is EZ

This book offers a tiny piece of code  (about 500 lines)
which implements (what I
thinks) are some of most important ideas  in AI and SE.  This code
is a demonstrator that good AI (i.e. that is fast and understandable)
is easy and simple to build-- assuming that the software engineering
is done right.

Why does better SE mean better AI?  Well, anyone who has dpme this
stuff knows that AI software is still software.  Measured in terms
of lines of code, any AI brain is very small compared to all the
software that it needs to make it go [^sculley] [^mesoft]. So rather
than start with the inference procedure, we start here with the
data structures (the classes) that implement the under-the-hood
tedium (e.g reading rows into a table of data, summarizing the rows
into columns).

[^sculley]: D. Sculley, Gary Holt, Daniel Golovin, Eugene Davydov,
Todd Phillips, Dietmar Ebner, Vinay Chaudhary, Michael Young,
Jean-Francois Crespo, Dan Dennison Hidden Technical Debt in Machine
Learning Systems Advances in Neural Information Processing Systems
28 (NIPS 2015)

[^mesoft]: T. Menzies, "The Five Laws of SE for AI," in IEEE Software,
vol. 37, no. 1, pp. 81-85, Jan.-Feb. 2020, doi: 10.1109/MS.2019.2954841.

This approach generates two things:

- Some reusable  classes to handle the under-the-hood stuff;
- And some very tiny functions implementing the actual AI.

For example, the DATA class defined in this document summarizes
ROWs into its various NUMeric or SYMbolic columns.  DATA turns out
to be extraordinarily reusable for many things. E.g. if clustering,
we an give each cluster its own DATA.  If we want separate stats
on each cluster, then we call the `DATA:stats()` method (shown
below).  For classification, we  store information about different
classes in its own separate data. Once that is done, then
implementing a Naive Bayes Classifier takes just  eight lines of
code.
```lua 
local function learn(data,row,  my,kl) --> nil, but updates
the working memory "my"
  my.n = my.n + 1 kl   = row.cells[data.cols.klass.at] if my.n >
  10 then -- train on at least 10 items before testing
    my.tries = my.tries + 1 my.acc   = my.acc + (kl == row:likes(my.datas)
    and 1 or 0) end
  my.datas[kl] = my.datas[kl] or DATA.new{data.cols.names}
  my.datas[kl]:add(row) end
```
In the above, ROWs from different classes are store in their own
DATA instance. Also note that we test the classifier before updating
the columns (so we are always testing on previously unseen examples).
For full details on the above, see the rest of this paper.

Implementing Naive Bayes in eight lines is not so impressive (since
the underlying algorithm is so simple).  What is  more interesting
is how my code  needs just 30 lines to code up:

- incremental
- semi-supervised learning
- for multi-objective sequential model optimization. 

That's a lot of buzz words but the main point here is that seemingly
complex AI is not really complex, if you get the SE right.  The
methods of this document have also been applied to clustering, data
synthesis, anomaly detection, privacy, multi-objective optimization,
streaming, and many other applications besides.

And all that was pretty simple.

Let me show you how.

\newline


asaas

