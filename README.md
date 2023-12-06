# AI, Refactored, Simplified

This is a semester-long experiment in 
refactoring complex  AI and SE concepts into simpler forms. I
advocate for understanding and applying _semi-supervised explainable
AI for multi-objective optimization_ in a more straightforward manner.

-  doing more with less,
- stop  assembling large libraries and complex systems.
- start focusing on  efficiency and minimalism in AI and
SE.

> Here  we say  "know the problem" before proposing solutions
We offer data-centric view here over a
code-centric or algorithm-centric approach, advocating for a exploring the _shape_ of    data and its landscape before diving into algorithmic trivia .

There's a strong focus on learning
through coding, and understanding AI and SE theories.
This subject is  targeted at individuals aiming to enhance their coding
skills and theoretical knowledge in these areas.

<img src="docs/despair.png" align=right width=400>
Students taking this course will
be able to simplify complex
problems,
becoming highly skilled (and respected) for their
 coding and
analysis skills. 
Graduates of this subject will become the CEO and CTOs of whatever follows Google and OpenAI  (\*)

(\*) That's perhaps a little overstated. 
- 1 professor + 4 Ph.D. students probably aren't going to unseat Google. 
- Maybe we need to learn when to call LLMs and when to do something else that is simpler and faster
- Anyway, at the very least, you will know so many AI buzzwords to impress people (at parties, at your next job).


This subject is offers a healthy dose of realism about   the current  mono-focus on large
language models (LLMs) like those developed by Google and OpenAI (which energy-expensive and
incomprehensible).  We  emphasizing practical learning and application of _all kinds_ of AI knowledge.



## The GREAT SECRET

<img align=right width=300 src="docs/block.jpg">

The best thing you can do with most data is throw it away.
- prune away the silly stuff
- focus on the important stuff 
- Every block of stone has a statue inside it and it is the task of the sculptor to discover it.   
  -- Michelangelo

Counter example? generative AI

- Well, yes, but so very many other counter, counter examples in classification, regression, optimization (see this subject or 
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

We offer  a practical approach
to problem-solving that involves clustering and thinking, suggesting
a method to efficiently reach solutions by minimizing assumptions
and focusing on relevant subsets of data.

Lets think about thinking:

- Rule1. Do something: $T \wedge A \vdash G$
- Rule2. Don't do something bad: $T\wedge A \not\vdash \bot$
- Rule3. Don't waste my time: minimize  $|A|$
- Rule4, Often, there areIf there are more than one solution $A'_1, A'_2, A'_3,...$
 - Pick the _best_  solution where _best_ is some domains specific predicate
    - e.g. planning / optimization: maximize goal coverage,   minimize, maximize certain numeric goal
    - e.g. monitoring: (what can go wrong), reverse of planning
    - e.g. explanation, tutoring: maximize overlap $A'$ with knowledge of the audience
    - e.g. classification / regression: report the expected values in  the $G'$ generated as above
    - e.g. testing: seek the fewest assumptions that reach the most goals

Let thing faster about thinking:

- Trick: cluster before  inference
  - First find groupings of  $A'$  into  $A'_1,A'_2...$ 
  - Then run  $T' \wedge A' \vdash G'$ inside just one or 2 of these reduced spaces (vastly faster)


## TL;DR

For efficiency, simplicity, and pragmatism
in problem-solving.

- Cluster (first), then think (less).

- Clustering should include dimensionality reduction
  - Ignore the spurious
  - Forus on what's important
