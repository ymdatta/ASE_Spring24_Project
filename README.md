# AI, Refactored

Here, we explore a large case study in refactoring seemingly complex code into something very, very simple indeed
- semi-supervised explainable AI for  multi-objective optimization
- a.k.a. "peek at a few  things (or less) to learn rules that tame many things".

Along the way, we'll do lots of coding in Python and learn lots of SE and AI theory.

## Why do this subject?

<img src="docs/despair.png" align=right width=400>

- you will learn the **GREAT SECRET** (see below)
  - you will code in a team to solve fun (and complex problems)
- this  will become a coding and analysis GOD
  - mere mortals will with respect you and fear your wrath
  - for any new problem, 
    - you will gave at it a while 
    - then say "here's  20 lines of code where you test if something else is better, simpler, faster"
  - for any new plan that explores many options
    - you will  boil that plan down into the minimum number of steps to succeed
- you will become a revolutionary 
  - taking down the system from within
  - the CEO and CTOs of whatever follows Google and OpenAI
  - you will unseat  LLMs  (which energy-expensive, incomprehensible, untestable, unreproducible...)
    -  and you will offer something... better (\*)

(\*) that's perhaps a little overstated. 
- 1 professor + 4 Ph.D. students probably aren't going to unseat Google. 
- Maybe we learn when to call LLMs and when to do something else that is simpler and faster
- Anyway, at the very least, you will know so many AI buzzwords to impress people (at parties, at your next job).


## What is new here?

- A data  centric view
  - _Data_ as the ultimate API
    - algorithms do this and that, but they all do it to data
    - so study the landscape of the data BEFORE anything
- Not a _code_ centric view
- Not respectful to  _algorithms_  (our goal: refactor  many algorithms  into a much smaller number reusable parts )
- Not library-itis
  - We don't deliver large ensembles that bolt together large libraries
  - We try to do _more_ with _less_


## The GREAT SECRET

<img align=right width=300 src="docs/block.jpg">

The best thing you can do with most data is throw it away.
- prune away the silly stuff
- focus on the important stuff 
- Every block of stone has a statue inside it and it is the task of the sculptor to discover it.   
  -- Michelangelo

Counter example? generative AI

- Well, yes, but so very many other counter, counter examples (see this subject or 
  [1](https://arxiv.org/pdf/2011.13071.pdf),
  [2](https://arxiv.org/abs/2108.09847) 
  [3](https://www.researchgate.net/publication/3248296_Finding_the_Right_Data_for_Software_Cost_Modeling))
- Challenge: how to combine the benefits of LLMs with this "pruning approach"

### Manifolds

High-dimensional data can be approximated in lower dimension
- **Continuity Assumption:**  Points which are closer to each other are more likely to have the same output label.
- **Cluster Assumption:**    Data can be divided into discrete clusters and points in the same cluster are more likely to share an output label.
- **Manifold Assumption:**    high dimensional data can be randomly projected into a lower dimensional  space while controlling the distortion in the pairwise distances. 
  - <a href="https://scikit-learn.org/stable/auto_examples/miscellaneous/plot_johnson_lindenstrauss_bound.html">Examples</a>.
- So we only have to   fit relatively simple, low-dimensional, highly structured subspaces.
- Within a manifolds,  we can  interpolate between two inputs, that is to say, morph one into another via a continuous path along which all points fall on the manifold. 

Why reduce dimensions?

- lower dimensions = less search = easier explanation
- higher dimensionality = more complexity = harder to find releveant examples = less reproduability = less validation = less trust
-  To see this, consider the volume of an $n$-dimensional sphere.
   -  $V_2( r )={\pi}r^2$ 
   -  $V_3( r )=\frac{4}{3}{\pi}r^3$ 
   - $V_{n>3}( r )= \frac{{2\pi}r^2}{n} V_{n-2}( r )$. 
   -  Now consider the unit sphere i.e. $r=1$   for $n>2\pi$. 
       - Observe how after $n=6$, the volume starts shrinking. 
<a href="https://ontopo.files.wordpress.com/2009/03/unit-hypersphere.png">(and hits zero at $n=20$)</a>. 
- So hard to find nearby (relevant) examples
  - Trick: find a transform to map higher to lower.


### Before Thinking, CLuster

Thinking:

- Rule1. Do something: $T \wedge A \vdash G$
- Rule2. Don't do something bad: $T\wedge A \not\vdash \bot$
- Rule3. Don't waste my time: minimize  $|A|$

- Pragmatics: you;ll be able to reach some of the goals using some of the theory, so you will only need a few assumptions
  - So, one more time:
    - $T' \subseteq T$
    - $A' \subseteq A$
    - $G' \subseteq G$
    - $T' \wedge A' \vdash G'$
    - $T' \wedge A' \not\vdash \bot$
    
If there are more than one solution $A'_1, A'_2, A'_3,...$
  - Pick the _best_ where _best_ is some domains specific predicate
    - e.g. planning / optimization: maximize goal coverage,   minimize, maximize certain numeric goal
    - e.g. monitoring: (what can go wrong), reverse of planning
    - e.g. explanation, tutoring: maximize overlap $A'$ with knowledge of the audience
    - e.g. classification / regression: report the expected values in  the $G'$ generated as above
    - e.g. testing: seek the fewest assumptions that reach the most goals

If you give this to a naive theorem prover, exponential   runtimes (so many subsets)
- Trick: cluster before  inference
  - First find groupings of  $A'$  into  $A'_1,A'_2...$ 
  - Then run  $T' \wedge A' \vdash G'$ inside just one or 2 of these reduced spaces (vastly faster)

## TL;DR

Cluster (first), then think (less).
