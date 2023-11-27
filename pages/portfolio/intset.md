---
title: IntSet
title-suffix: Portfolio
date: 2023-11-21
keywords: [JavaScript, Set Theory, Bit Masking, Container, BigInt]
website: https://www.npmjs.com/package/intset
abstract:
  "`IntSet` is a container for storing `bigint`s in a relatively efficient manner.
  It uses bit masking to store numbers more efficiently."
---

# Functionality

You can view the code at the [GitHub repository](https://github.com/athanclark/intset.js),
but I'll describe the functionality here.

## As a Container

You can treat an `IntSet` as a general purpose container for `bigint`s pretty intuitively,
designed after the built-in
[`Set`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set):

```js
const IntSet = require('intset');

let set = new IntSet();

// add a value
set.add(1n);

// remove a value
set.remove(1n);

// check if the set contains a value
set.contains(1n);

// see if the set is empty
set.isEmpty();
```

## As a Set

The whole purpose behind this data structure is to allow for "efficient" unions, intersections,
symmetric difference, and difference operations with the sets. Imagine you have two sets,
`set1` and `set2`. These operations can be done like so:

```js
// returns a union of the two sets
const unionOfSet1And2 = set1.union(set2);

// returns an intersection
const unionOfSet1And2 = set1.intersection(set2);

// returns a symmetric difference
const symDiffOfSet1And2 = set1.symmetricDifference(set2);

// returns set1 without elements of set2
const set1Diff2 = set1.difference(set2);
```

## Implementation

This datastructure is implemented in a very simple way -- through bit masking. For a thorough
explanation of bit masking, please see this project's [blog post](/blog/intset.html#bit-masking).
