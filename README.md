# AI, Refactored

There is a disase, which we might call "library-itis" infecting
my studnets. Instead of understanding their systems, the instead
just wire together increasingly complex ensembles of libraries.

My students keep making connections between different parts
pf AI

## What is new here?

- A data  centric view
  - _Data_ as the ultimate API
    - algorithms do this and that, but they all do it to data
    - so study the landscape of the data BEFORE anything
- Not a _code_ centric view
- Not respectful to  _algorithms_  (our goal: refactor  many algorithms  into a much smaller number reusable parts )


## A little theory

- Rule1. Do something: $T \wedge A \vdash G$
- Rule2. Don't do something bad: $T\wedge A \not\vdash \bot$
- Rule3. Don't waste my time: minimize  $|A|$
- Pragmatics: 
  - You;ll be able to reach some of the goals using some of the theory, so you will only need a few assumptions
    - So, one more time:
      - $T' \subseteq T$
      - $A' \subseteq A$
      - $G' \subseteq G$
      - $T' \wedge A' \vdash G'$
      - $T' \wedge A' \not\vdash \bot$
      - If there are more than one solution $A'_1, A'_2, A'_3,...$
        - Pick the _best_ where _best_ is some domains specific predicate
          - e.g. planning / optimization: maximize goal coverage,   minimize, maximize certain numeric goal
          - e.g. monitoring: (what can go wrong), reverse of planning
          - e.g. explanation, tutoring: maximize overlap $A'$ with knowledge of the audience
          - e.g. classification / regression: report the expeted values in  the $G'$ generated as above
  - If you give this to a naive theorem prover, exponential   runtimes (so many subsets)
    - Trick: cluster the space, before inference
      - So first cluster $A'$ into  $A'_1,A'_2...$ 
      - Before running  $T' \wedge A' \vdash G'$ (so this runs is a much smaller space)
