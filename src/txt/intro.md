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
    \usepackage{listings}
    \lstset{basicstyle=\tiny} 
---

# AI is EZ?

This book offers a tiny piece of code  (about 500 lines)
which implements (what I
think) are some of most important ideas  in AI and SE.  This code
is a demonstrator that good AI (i.e. that is fast and understandable)
is easy and simple to build-- assuming that the software engineering
is done right.

Why does better SE mean better AI?  Well, anyone who has done this
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

For example, the `DATA` class defined in this document summarizes
`ROW`s into its various `NUM`eric or `SYM`bolic columns.  `DATA` turns out
to be extraordinarily reusable for many things. E.g. if clustering,
we an give each cluster its own `DATA``.  If we want separate stats
on each cluster, then we call the `DATA:stats()` method (shown
below).  For classification, we  store information about different
classes in its own separate data. Once that is done, then
implementing a Naive Bayes Classifier takes just  eight lines of
code.

```lua 
local function learn(data,row,  my,kl) --> nil, side-effect: update "my"
  my.n = my.n + 1 
  kl   = row.cells[data.cols.klass.at] 
  if my.n > then -- wait at least 10 items before testing
    my.tries = my.tries + 1 
    my.acc   = my.acc + (kl == row:likes(my.datas) and 1 or 0) end
  my.datas[kl] = my.datas[kl] or DATA.new{data.cols.names} -- klass 'l' exists
  my.datas[kl]:add(row)  -- update klass 'k'
end
```

In the above, `ROW`s from different classes are store in their own
DATA` instance. Also note that we test the classifier before updating
the columns (so we are always testing on previously unseen examples).
For full details on the above, see the rest of this paper.

Implementing Naive Bayes in eight lines is not so impressive (since
the underlying algorithm is so simple).  What is  more interesting
is how my code  needs just 30 lines to code up and incremental
 semi-supervised learning for multi-objective sequential model optimization. 
That's a lot of buzz words (and we will learn what they mean, soon)
but the main point here is that seemingly
complex AI is not really complex, if you get the SE right.  The
methods of this document have also been applied to clustering, data
synthesis, anomaly detection, privacy, multi-objective optimization,
streaming, and many other applications besides.

And all that was pretty simple.

Let me show you how.


# Less is More

Good programming does not mean lots of programming. In fact,
smarter programmers, code less.  The longer your code, the more placed for bugs
to collect. The shorter your code, the less you need to debug and maintain, explain to other
other people,   port to other platforms (or languages), etc.

Near misses

Two   powerful methods for making code shorter are experience and abstraction.
_Experience_ is that thing that lets you recognize that _this_ is kind of like _that_.
And abstraction is the practice where we code up the common bits, then write the tiny
bits of code that customize the tiny bit for the particular thing you want to do. 

## My Experience 
Decades  of AI and SE kept showing me that  simple models can perform exceptionally well: 

- Defect prediction datasets [^me06] where two to three attributes
were enough to predict for defects
- Effort estimation models [^chen05] where four to eight attributes
where enough to predict for defects;
- Requirements models for NASA deep space missions [^jalali08]
where two-thirds of the decision attributes could be ignored
while still finding effective optimizations;
- Numerous Github issue close time data sets [^rees17] where only 3 attributes (on average) were needed for effective prediction
- Learning a security model fro 28,750 Mozilla functions meant  learning just 300  support vectors [^zhe19].
- And many other examples besides.


[^me06]: Tim Menzies, Jeremy Greenwald, and Art Frank. 2006. Data mining static code
attributes to learn defect predictors. IEEE transactions on software engineering 33,
1 (2006), 2–13.
[^chen05]: Zhihao Chen, Tim Menzies, Daniel Port, and D Boehm. 2005. Finding the right
data for software cost modeling. IEEE software 22, 6 (2005), 38–46.
[^jalali08]: Omid Jalali, Tim Menzies, and Martin Feather. 2008. Optimizing requirements
decisions with keys. Predictor
models in software engineering. 79–86.
[^rees17]: Mitch Rees-Jones, Matthew Martin, and Tim Menzies. 2017. Better predictors for
issue lifetime. arXiv preprint arXiv:1702.07735 (2017).
[^zhe19]: Zhe Yu, Christopher Theisen, Laurie Williams, and Tim Menzies. 2019. Improving
vulnerability inspection efficiency using active learning. IEEE Transactions on
Software Engineering 47, 11 (2019), 2401–2420

Turns out, all the above are examples of the _low-dimensional embeddings_ assumption_; i.e.
a set of points in a high-dimensional space can be embedded into a space of much lower dimension in such a way that distances between the points are nearly preserved  [^joh84]. Which is to
say that if you are presented with very complex descriptions 
of something (that use many attributes)
Strange to say,   very few people are  
asking "say, does that mean that we could make   AI
simpler and more comprehensible?" This is  an important question,
since humans often have difficulty accurately assessing complex
models (leading to unreliable and sometimes dangerous results).  

[^joh84]: Johnson, William B.; Lindenstrauss, Joram (1984), "Extensions of Lipschitz mappings into a Hilbert space", in Conference in modern analysis and probability (New Haven, Conn., 1982), Contemporary Mathematics, vol. 26,  pp. 189–206, doi:10.1090/conm/026/737400 

## My Favorite Abstraction
 Based on the above experience, we know that
most things are controlled by a small number of things.
This means, in turn, that if we clustered the data
then  there are very few  difference between those controlling sets in 
nearby clusters.

  So   my favorite
 abstraction is  
  _cluster and contrast_. That is,
 when   reasoning,  do not look at everything.
 Rather,  look for the _minimal difference_ between _things_.
So when speeding towards a cliff, I will not waste
 your time with measurements of the temperature and humidity.
 Rather, I will shout in your ear "turn left, NOW!". Which is to say:
 
 -  I cluster the future scenarios (crash and burn, live another day);
 -  I report   the smallest difference  between them (turn left, NOW!)

As we shall see, this approach leads to very simple code.

# More than Just Coding
# DRY (Don't Repeat Yourself) 

A lot of code is WET Write Every Time(WET) is a cheeky abbreviation to mean the opposite i.e. code that doesn't adhere to DRY principle

# You Will Test (a Lot)


# Patterns
