---
title: IntSet Development
title-suffix: Blog
author: Athan Clark
keywords: [IntSet, JavaScript, Bit Masking]
abstract:
  "On 2023-11-21, I developed a set container for JavaScript `bigint`s. This allows for
  unions, intersections, and other set operations, but in a relatively fast manner.
  This blog post describes my development methodology, the issues I faced, and how I
  overcame them."
date: 2023-11-23
scripts:
  - ./intset/plot_bench.js
---

[tl;dr](#conclusion), Don't use more than 16k values, and don't have a variance greater than 65k
between the minimum and maximum values.

# Preamble

The purpose of IntSet is to act as a container for `bigint`s by utilizing bit masks and bitwise
operators. This would improve the runtime performance and reduce memory use compared to
traditional methods, assuming the contents of the sets are "relatively close" to one another.

> "Relatively close", meaning the spread of integers within the set, or the range of values
> (the difference between the minimum value and maximum value) is lower than 65k. The reason
> why is discussed in the [benchmarks](#benchmarks).

Traditionally, if you have a group of values you need to retain, the everyday programmer would
choose something simple like an array and manually check for uniqueness, while others would
look to a tree-like structure like a
[binary tree](https://en.wikipedia.org/wiki/Binary_tree), or better, a
[red-black tree](https://en.wikipedia.org/wiki/Red%E2%80%93black_tree), to contain the data.
These are easy solutions, and doesn't require much thought, but the performance of these structures
matters when dealing with high throughput (either data or operations). Arrays grant $O(1)$
insertion, but harbor $O(n)$ for search and deletion. A red-black tree will grant
$O(log n)$ for all three operations in the worst case, but we can do better.

This blog post is an account of my development experience for this library, and a slight technical
interlude on how it works. The audiance reading this should be familiar with basic
[set theory](https://en.wikipedia.org/wiki/Set_theory), JavaScript, and
[bits](https://en.wikipedia.org/wiki/Bit).

Before I go any further into the implementation, I'd like to describe the bit masking and
how it works.

# Bit Masking

Assume you have some non-negative real integer
([natural number](https://en.wikipedia.org/wiki/Natural_number)) $x \in \mathbb{N}$. Also,
assume you have a bit space (where you can freely write and read bits at certain indicies),
represented as array of bits with length $n \in \mathbb{N}$.
For instance, a 32-bit integer consumes 32 bits of space, and
in that circumstance, $n = 32$.

If $x < n$, then $x$ can be represented as a single bit flipped in the space provided by $n$;
$x = 0$ is the first bit, $x = 1$ is the second bit, $x = 2$ is the third bit, and so on.
If you were to turn the bit space into a (little-endian / right-to-left) integer
$m \in \mathbb{N}$, and if $x$'s bit
were the only bit flipped in the bit space, then $m = 2^x$.

As an example, let's say $x = 0$, and $n = 8$. In this case, the value of the first bit
is $1$, and the value of the of the rest of the bits would be $0$.
If we turn this bit space into a integer $m$, it would equal $1$ --
in other words, $2^0 = 1$. You can try this in JavaScript -- the bit space would be written
(using binary notation) as `0b00000001`, and JavaScript will tell us this value is actually
just `1` (our $m$).

```js
const m = 0b00000001;
console.log(m);
// → 1
```

Or, let's say that $x = 7$, and $n = 8$ again. In that instance, $n$'s 8th bit is $1$,
and the rest are $0$'s - it would look like `0b10000000` in JavaScript. Again, if we were to
evaluate this, it would return `128`, which is the same as $2^7 = 128$.

```js
const m = 0b10000000;
console.log(m);
// → 128
```

## Bitwise Or and Union

Now lets imagine the union of these two examples -- we'll "zip" the bit spaces together, and
if either of each compared bit has a value of $1$, we'll retain it. Doing this with
our previous examples of `0b00000001` and `0b10000000` would return
`0b10000001`, which when evaluated in JavaScript would reveal `129`:

```js
const m = 0b10000001;
console.log(m);
// → 129
```

What we _mean_ by this bit space is "both the values
of $x = 0$ and $x = 7$ are present in the bitspace $n = 8$".

Fortunately, JavaScript (and in fact, most CPU architectures)
implement this bitwise union through the bitwise "OR" operator `|`. We can try
running `128 | 1` and `0b10000000 | 0b00000001` in JavaScript, and we'll receive the result `129`:

```js
console.log(128 | 1);
// → 129
console.log(0b10000000 | 0b00000001);
// → 129
```

## What does this imply?

Given a contiguous bitspace with a size $n \in \mathbb{N}$, all natural numbers less than the
bitspace size ($\forall x \in \mathbb{N}$ such that $x < n$) can be represented in the bitspace
via the presence of its $x$th bit.

Furthermore, given a set $A$ of natural numbers less than the bitspace size
($A = \{ x | x < n \}$), where each member
of the set is referred to as $x_1 \ldots x_q$ (i.e., there are $q$ elements in $A$), the bitspace
can be represented as:

$$
m_A = 2^{x_1} \cup 2^{x_2} \cup \ldots \cup 2^{x_q}
$$

Where $m_A$ is the whole integer that represents the set $A$, and $\cup$ is the bitwise or operator `|`.
These implications are expanded on the other operators as well:

| Bitwise Operator | Set Operator |
| :--------------: | :----------: |
| `|` / OR         | $\cup$ / Union |
| `&` / AND        | $\cap$ / Intersection |
| `^` / XOR        | $\oplus$ / Symmetric Difference |

With these primitive operations, the difference operation can be defined as follows:

$$
X \backslash Y = X \cup (X \oplus Y)
$$

# Unbounded Data

Now that we have a mechanism to create sets of natural numbers up to size $n \in \mathbb{N}$, we
need one that could be (mostly) unbounded.

## A first stab -- Arrays

Initially, I imagined am array of $m$'s to be the most intuitive solution -- the bit space
representation of a set $A$ of _any_ value $x \in \mathbb{N}$ is an array $\psi$ of length
$p_\psi = \lceil y / n \rceil$ elements, each of which holds an $m$, with bit
size of $n$. The value of an $i$th bit in a $j$th bitspace $m_j$ is calculated as follows:

> Note, $\lceil ... \rceil$ is the
> [ceiling operation](https://en.wikipedia.org/wiki/Floor_and_ceiling_functions).

$$
i + (j \times n)
$$

Where $j$ is the (zero-based) index in the array that contains $m_j$.

Implementations of setwise union, intersection, and the like would be performed through
[zip-with](https://hackage.haskell.org/package/base-4.19.0.0/docs/Prelude.html#v:zipWith)
-- where in the case of union and symmetric difference, the elements not present in the
other are simply retained as-is -- the resulting array between sets with arrays $\psi$
and $\phi$ would be the maximum of $p_\psi$ and $p_\phi$.

### Issues with Arrays

The critical issue with this solution is the case where the set only holds large values.
In that circumstance, there will be wasted $0$-valued $m$ elements denoting orders of magnitude, up
until the relevant $i_p$ value -- essentially, this makes the size of the set linear with respect
to the maximum value of $y / n$ regardless of the count of elements contained within the set,
and likewise the setwise uperations would be $O(p)$.

This is unacceptable, and a better solution exists.

## A better stab -- Maps

Rather than store empty $m$ values, we can sparsely store $m$ values if they are greater than 0 by
utilizing the built-in `Map` object in ECMAScript 6 -- Now, we can store the $m$
values with the $i_p$ index as its key:

$$
i_p \mapsto m
$$

This causes for a great deal of efficiency where $x$ values are relatively near to
each other. Particularly, if the average difference between $x$ values are
below $n$, then they'll (likely) be stored in the same $m$ value, regardless of how large the
$x$ values are.

# Implementation

The code lives [in my personal GitHub](https://github.com/athanclark/intset.js), and
can be inspected very easily - it's only a few hundred lines.

I tried to be thorough with the tests and benchmarks, however the latter are a bit
difficult to parse, but they did help me choose a good default $n$ value.
I am confident with the default settings of `IntSet`,
but if you'd like to customize $n$, it can be supplied as an argument to `new IntSet(n)`.

## Tests

The tests are built using
[property-based testing](https://medium.com/criteo-engineering/introduction-to-property-based-testing-f5236229d237)
techniques, namely via a [fuzz tester](https://en.wikipedia.org/wiki/Fuzzing) library
for JavaScript called [fast-check](https://fast-check.dev/). The following
[invariants](https://en.wikipedia.org/wiki/Invariant_(mathematics)) are tested:


+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Name                        | Expression                                                                                          |
+:===========================:+:===================================================================================================:+
| Existence                   | $\forall \enspace X \in IntSet, \enspace x \in \mathbb{N}. \enspace X \cup \{x\} \ni x$             |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Non-Existence               | $\forall \enspace X \in IntSet, \enspace x \in \mathbb{N}. \enspace X \backslash \{x\} \not\ni x$   |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Union Commutativivty        | $\forall \enspace X \in IntSet, \enspace Y \in IntSet. \enspace X \cup Y = Y \cup X$                |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Union Identity              | $\forall \enspace X \in IntSet. \enspace \emptyset \cup X = X$                                      |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Union Associativity         | $$                                                                                                  |
|                             | \forall \enspace X \in IntSet, \enspace Y \in IntSet, \enspace Z \in IntSet.                        |
|                             | $$                                                                                                  |
|                             | $$                                                                                                  |
|                             | (X \cup Y) \cup Z = X \cup (Y \cup Z)                                                               |
|                             | $$                                                                                                  |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Intersection Commutativivty | $\forall \enspace X \in IntSet, \enspace Y \in IntSet. \enspace X \cap Y = Y \cap X$                |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Intersection Absorption     | $\forall \enspace X \in IntSet. \enspace X \cap X = \emptyset$                                      |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Intersection Associativity  | $$                                                                                                  |
|                             | \forall \enspace X \in IntSet, \enspace Y \in IntSet, \enspace Z \in IntSet.                        |
|                             | $$                                                                                                  |
|                             | $$                                                                                                  |
|                             | (X \cap Y) \cap Z = X \cap (Y \cap Z)                                                               |
|                             | $$                                                                                                  |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Symmetric Difference        | $\forall \enspace X \in IntSet, \enspace Y \in IntSet. \enspace X \oplus Y = Y \oplus X$            |
| Commutativivty              |                                                                                                     |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Symmetric Difference        | $\forall \enspace X \in IntSet. \enspace \emptyset \oplus X = X$                                    |
| Identity                    |                                                                                                     |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Symmetric Difference        | $\forall \enspace X \in IntSet. \enspace X \oplus X = \emptyset$                                    |
| Absorption                  |                                                                                                     |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Symmetric Difference        | $$                                                                                                  |
| Associativity               | \forall \enspace X \in IntSet, \enspace Y \in IntSet, \enspace Z \in IntSet.                        |
|                             | $$                                                                                                  |
|                             | $$                                                                                                  |
|                             | (X \oplus Y) \oplus Z = X \oplus (Y \oplus Z)                                                       |
|                             | $$                                                                                                  |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Difference                  | $\forall \enspace X \in IntSet. \enspace X \backslash \emptyset = X$                                |
| Identity                    |                                                                                                     |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Difference                  | $\forall \enspace X \in IntSet. \enspace X \backslash X = \emptyset$                                |
| Absorption                  |                                                                                                     |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Difference / Union          | $\forall \enspace X \in IntSet, \enspace Y \in IntSet. \enspace X \backslash Y = Y \oplus X$        |
| Intersection Equivalence    |                                                                                                     |
+-----------------------------+-----------------------------------------------------------------------------------------------------+
| Difference / Union          | $$                                                                                                  |
| Symmetric Difference        | \forall \enspace X \in IntSet, \enspace Y \in IntSet.                                               |
| Equivalence                 | $$                                                                                                  |
|                             | $$                                                                                                  |
|                             | X \cup (X \oplus Y) = X \backslash Y                                                                |
|                             | $$                                                                                                  |
+-----------------------------+-----------------------------------------------------------------------------------------------------+

I've deemed this to be a pretty thorough test suite. If you feel like more properties
should be represented in the test suite, please feel free to
[file a bug report](https://github.com/athanclark/intset.js/issues).

> **Note**: $IntSet$ in the above contexts is defined as the set of all `IntSet`s.
>
> The empty set is defined as
>
> $$
> \emptyset \in IntSet
> $$
> Such that
> $$
> \forall x \in \mathbb{N}. \enspace x \not\in \emptyset
> $$

## Benchmarks

The benchmark suite is, in my opinion, sub-standard. I originally built it to try and find
a good default value for $n$; my assumption was that $64$ would be a good value, but I wanted
to verify.

I have two forms of benchmarking suites - the first uses [Benchmark.js](https://benchmarkjs.com/)
to find a "fastest" version of the `union` function, and the second takes a heap snapshot
of the `union` function of the same two sets, and also measures the approximate total amount of
data stored in that resulting set. The data being generated are two sets, each of which are
filled with $2^16$ random `bigint`s, with maximum value $y$ of $2^8 \leq y \leq 2^32$, and
implementations of $n$ varying between $2^5 \leq n \leq 2^15$. The following figures show
the results:

<div class="figure" id="ops-per-sec"></div>
<div class="figure" id="heap-used"></div>
<div class="figure" id="total-size"></div>

### Interpretations

A few observations can be made by these figures. First, let's start with
[Operations Per Second](#ops-per-sec):

- Sets maximize speed for random numbers generated up to $2^8$ when $n \geq 2^8$.
- Sets maximize speed for random numbers generated up to $2^12$ when $n \geq 2^12$.
- Before the speed is maximized, the approach to obtaining higher speed at a particular
  max random
  value comes at a curve.
- The entire space past $2^20$ for maximum size is pretty flat - no drastic speed increases.

Secondly, [Heap Used](#heap-used):

- The dominating factor is the maximum value of the generated numbers, not $n$.
- $n$'s increase does have a minor factor past $n \geq 2^12$, especially in the extreme
  cases of $y = 32$.

Lastly, [Total Size](#total-size):

- Total size appears to gain exponential growth past $y \geq 24$, and can be directly observed
  with an increase in $n$.

Unfortunately, the last figure doesn't give us a great deal of insight to the (potential) total
amount of memory used, but rather a philosophical perspective, which is why I included the
"Heap Used" figure as well.

Given that concern, I've opted to reduce the chart's ranges a bit for these next figures -
$n$ will not exceed $2^12$, and the max number generated will not exceed $2^24$.

<div class="figure" id="reduced-ops-per-sec"></div>
<div class="figure" id="reduced-heap-used"></div>
<div class="figure" id="reduced-total-size"></div>

### Further Interpretations

From the latter two figures, a reasonable conclusion can be observed -- space consumed by sets
are relatively constant up until the maximum number generated becomes greater than $2^16$.
This, however, may be indirectly related to the fact that there are only $2^16$ numbers in
each set; smaller generated values would likely exhaust the sample space.

Additionally, although the assumed spatial consumtion of the sets (last figure) is assumed to
increase as $n$ increases, we can see that for cases where the maximum generated number is
greater than $2^16$, the heap is actually larger for smaller values of $n$. I assume this to
be due to the operational overhead, i.e. callbacks and the like, because of the need to "mesh"
more values together.

# Conclusion

There are a few key points to receive from this investigation:

1. Potential gains from this library are drastically diminished when the set contents can be
   larger than $2^16$, both in terms of speed and space.
2. For values generated up to $2^12$, I recommend a default $n$ value of $2^8$, due to the
   clef in the [Reduced Operations Per Second](#reduced-ops-per-sec) at $x = 8, y = 12$.
3. For values generated up to $2^16$, I recommend an $n$ value of $2^12$.
4. For larger values, maybe consider a different library.

## Considerations

A few potential deficiencies should also be identified:

- I only benchmarked `union`, not the other set-wise operations.
- I only benchmarked sets that have $2^16$ elements, not fewer ones.
- I used `Math.random()` to generate the random numbers -- there may be a lack of uniformity in
  the random numbers being generated.

However, I don't want to address those at this time. I hope you enjoyed this exploration! It was
very insightful for me.
