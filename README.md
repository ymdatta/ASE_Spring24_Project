# SE for  Simpler AI: A Minimalist Approach

**CHALLENGE**: AI software is still software. Hence, if we understand it, it can be refactored
and simplified.  Do you understand the software basis for AI?

<img align=right width=300 src="docs/revolution.png">

This is a semester-long experiment in  refactoring complex  AI and SE concepts into simpler forms. Here, we 
advocate   understanding and applying _semi-supervised explainable
AI for multi-objective optimization_ in a more straightforward manner.

>  Graduates of this class will become software revolutionaries,
the  CEO and CTOs of whatever follows Google or OpenAI.

Here are our themes;

- **Simplification of AI and SE:** Emphasizing the transformation of complex AI concepts into simpler, more understandable forms.
- **Learning and Skill Development:** Focus on enhancing coding skills and theoretical knowledge in AI and software engineering through practical examples.
- **Empowerment through Knowledge:**  
- Motivating readers to become proficient in enhanced coding and analysis, enabling them to tackle complex problems with simplified solutions.
  - Yes, you can understand it.
- Enabling people, who are not the developers, to understand and critique
  a system and (in an effective manner) demand changes to that system.
  - Yes, you can critique it and propose improvements to  it.
- **Critical View of Current AI Systems:** Analyzing the limitations of current large language models, such as their inefficiency and lack of transparency or validation [^wechat23]
- **Data-Centric Approach:** Prioritizing a focus on data analysis over algorithmic or code-centric methods.
  - Data is the ultimate API
- **Efficiency and Minimalism:** Advocating for more efficient solutions using fewer resources and simpler methods.
  <img align=right width=300 src="docs/block.jpg">
- **Importance of 'Pruning' Data:** Highlighting the need to focus on important data and discard the irrelevant, drawing inspiration from Michelangelo’s sculpting philosophy.
  - "Every block of stone has a statue inside it and it is the task of the sculptor to discover it." -- Michelangelo
  - The best thing to do with most data is throw it away 
    (and there are many examples of this [^btw] [^stealth] [^early]).
- **Dimensionality Reduction:** Discussing how high-dimensional data can be simplified and understood in lower dimensions.
  - See case study, below
- **Practical Problem-Solving Strategy:** Presenting a methodical approach to problem-solving by prioritizing clustering and minimizing assumptions

[^wechat23]: For more on this, see T. Menzies. keynote ASE'23, 
 [Beware, some of the rhetoric on LLMs is misleading](tiny.cc/wechat23).

[^btw]: I definitely believe this for classification, regression,
and optimization. Generation, on the other hand, is another matter.

[^stealth]: L. Alvarez and T. Menzies,
["Don’t Lie to Me: Avoiding Malicious Explanations With STEALTH,"](https://arxiv.org/pdf/2301.10407.pdf) in IEEE Software, 
vol. 40, no. 3, pp. 43-53, May-June 2023, doi: 10.1109/MS.2023.3244713.

[^early]: N.C. Shrikanth, Suvodeep Majumder, Tim Menzies  
[Early Life Cycle Software Defect Prediction. Why? How?](https://arxiv.org/pdf/2011.13071.pdf), ICSE'21.


TL;DR: 
- "Cluster (first), then think (less)" to promote efficient and effective problem-solving.
- Clustering should include dimensionality reduction
  - Ignore the spurious
  - Focus on what's important

## Case Study: Privacy


> [Peters, Fayola, Tim Menzies, and Lucas Layman.](https://www.ezzoterik.com/papers/15lace2.pdf)
    2015 IEEE/ACM 37th IEEE International Conference on Software Engineering. Vol. 1. IEEE, 2015.

Why share all the data? why not just cluster and just share a few cluster centroids?[^peters]
  - [Fayola Peters](https://www.ezzoterik.com/papers/15lace2.pdf) used cluster + contrast to prune data, as she passed data around a community. 
   - For example, in the following, green rows are those nearest the cluster centroids and blue rows are the ones most associated with the last column (bugs/10Kloc).
   - Discard things are aren't blue of green. 
   - She ended up sharing 20% of the rows and around a third of the columns. 1 - 1/5\*1/3 thus offered 93%   privacy
   - As for the remaining 7% of the data, we ran a mutator that pushed up items up the boundary point between classes (and no further). Bu certain common measures of privacy, that made the 7% space 80% private. 
   - Net effect 93% + .8*7 = 98.4% private,
   - And, FYI, inference on the tiny green+blue region was as effective as inference over all

<img width=700 src="https://github.com/timm/tested/blob/main//etc/img/peters1.png">

<img width=700 src="https://github.com/timm/tested/blob/main//etc/img/peters2.png">






## Some Theory

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


