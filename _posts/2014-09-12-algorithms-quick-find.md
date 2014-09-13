---
layout: post
title: Algorithms & Data Structures - Union Find
tags: math, haskell, programming, cs
date: 2014-09-13
---

Currently, there is a ongoing [Algorithms Part I](https://www.coursera.org/course/algs4partI) course on coursera. Along with studying the course, in a series of blog posts, I will try to explain various data structures and algorithms and implement them in Haskell and if time permits in JavaScript as well. I started learning Haskell recently, so implementation of algorithms here will very naive and may not of same efficiency. But I will try my best to write as nice solution within my knowledge. As learn more Haskell along the way, I plan to revisit old algorithms and rewrite them. In case you are wondering why I mentioned JavaScript beside Haskell, I really really like it as language(because of the way Douglas Crockford puts it) and I want to explore its potential to do functional style programs.

Once the course ends, and if I am still writing, I will definitely pick up Purely Functional Data Structures book by C. Osaki and rewrite everything. You may ask, what's the point of rewriting this many times? I just view as a good learning exercise. Alright, let's get started!


## Union-Find

**Problem** Given $$N$$ objects and two functions on those objects `find` and `union` which are defined as follows. If $$a$$ and $$B$$ are two objects

- `union(a, b)` - connects $$a$$ and $$b$$ by a path
- `find(a, b)` - returns if there is a path connecting $$a$$ and $$b$$

Determine a data structure to store the $$N$$ objects such that the algorithms for both `union` and `find` are efficient

Observe that a path between two points $$a$$ and $$b$$ is an equivalence relation, so you can partition the set of $$N$$   objects into components/subsets such that any two members of component are connected. So we can restate the definitions of `union` and `find` as follows. If $$a$$ and $$b$$ are two objects

- `union(a, b)` - connect component of $$a$$ with $$b$$ (i.e, take the union of two subsets)
- `find(a, b)` - returns if $$a$$ and $$b$$ belong to the same component

(_Note_: This particular problem depends mutable arrays to solve the problem efficiently. After reading up a bit, I felt Haskell Arrays are not suitable. So I don't know, whether there is equivalent implementation that has the same efficiency. So, this time for the sake of completeness I am solving them using lists. If I find a solution, I will update this post. This might work using MutableArrays, I don't want to write any code with mutable data structures, so I leave it for later because the implementation won't change much.)

**Solution 1**  Represent the $$N$$ objects by $$0, 1 \dots N- 1$$. Initialize an array of N-dimension with indices representing out objects. Suppose we know the initial state of objects, set same value at each index in the array that belongs to a component.

{% gist bfca9253cbd95950d56b union1.hs %}

**Solution 2** If know what are the connected components then we can represent each component as tree like structure (for sake of simplicity we will just refer it as a tree) with a root and nodes. We may have node of node connected to the root or exceptions to a definition of tree structure but it doesn't get in the way of our algorithm. We just require that root of the tree is unique.

Initialize an array of dimension $$N$$ such that `tree[i] = i`. Here index $$i$$ corresponds to our objects and value `tree[i]` corresponds to root of the node it is connected (if it has multiple roots choose any one). We are setting the initial state of all objects to be disconnected. Our functions definitions are slighted modified to match our representation of objects. So the new definitions are

- `union(a, b)` - connect root of the tree containing $$a$$ with the root of tree containing $$b$$ (i.e, take the union of two subsets)
- `find(a, b)` - returns if $$a$$ and $$b$$ have same root of the tree they belong to.

We also here need a auxiliary function to determine root of the tree containing the given node. Lets call it `root`.

{% gist bfca9253cbd95950d56b union2.hs %}

**Solution 2.1** `root` is crucial function in both union and find so we would like it to be as fast as possible. After several unions, the tree might look unbalanced, one sided may contains way too many nodes which in turn decreases the speed of `root`. So, we would like to have a balanced tree. One way to do it is avoid creating a unbalanced tree in the first place. To do this we create another array which stores the weight of node. When we call the union function, we see which tree has greater weight and connect the root of small tree to the big tree.

{% gist bfca9253cbd95950d56b union3.hs %}

Here `step2` and `wStep2` illustrates how the `union` and `weightUnion` work.

We can do one more little improvisation on our tree that is Path Compression. Instead of having tall balanced trees, we make the tree wide and balanced, so that we can get to root of tree really quickly (access in constant time). We achieve this by setting `tree[i] = tree[tree[i]]`.

{% gist bfca9253cbd95950d56b union4.hs %}

That wraps up the first week's content.
