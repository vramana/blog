---
layout: post
title: Codemod Tutorial
published: false
---

If you don't know what codemods are, go watch [this talk][cpojer-talk].
Codemods allow you to transform your code to make breaking changes but without
breaking the code. Codemods take a JS file as input and turn them into
Abstract Syntax Trees (AST) and apply transformations on this AST later converting
them back to JS again. I wanted to write such codemods for my own projects but
there is not whole lot of documentation or tutorial on how to write them.
So, I am writing some tutorials for myself and you the reader. I will try to
make this as self contained as possible (even if you are lazy to watch the above
video).

For these tutorials (I plan to do more than one tutorial but we will see), we will
use [ASTExplorer][ast] (the same tool showed in the talk) to visualize the AST
and writing the transforms as well.

### Problem:

I looked to around a bit to find to good first problem, then it struck to me, now that we
have template strings in ES2015, we don't have to write to have to concatenate using `+` operator. So our aim is to convert this

```javascript
'Yo ' + name + '! What are you doing?'  
```

to

```javascript
`Yo ${name}! What are you doing?`
```

### Solution:

In this section of this tutorial, I will teach to how to use [ASTExplorer](ast) and arrive the solution to our problem incrementally.

#### Step 1:

Whenever I try to solve a problem, my first approach is to break down the problem into smaller pieces and solve them one by one. To explain this bit more,
you don't need to solve problem in its full generality in the first go, solve for a specific case it may give you insights into how to solve the original problem. I think converting  

```javascript
(a + b)
```

to

```javascript
`${a}${b}`
```

is a nice way to begin solving this problem. Open up [ASTExplorer](ast). Clear everything inside the editor and enter `(a + b)`. On the right hand side of the
editor, you will see the corresponding AST for the code you have just written. Open the tree a bit and it will look like this.

**Insert image here**

Now look at the words written in **blue**, they represent the nodes in our AST tree and things other than them represent the data about the node. We have the
following words: `File`, `Program`, `ExpressionStatement`, `BinaryExpression`,
`Identifier`. Lets try under to understand them each of them. `File`, `Program` are kind of straight forward to understand from the name. Here we don't have actual file but the ASTExplorer is simulating one to our AST parser (which is *recast* in our case).   









[cpojer-talk]: https://www.youtube.com/watch?v=d0pOgY8__JM
[ast]: https://astexplorer.net/
