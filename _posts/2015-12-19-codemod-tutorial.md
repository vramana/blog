---
layout: post
title: How to write a codemod
published: true
---

If you don't know what codemods are, go watch [this talk][cpojer-talk]. Codemods allow you to transform your code to make breaking changes but without breaking the code. Codemods take a JS file as input and turn them into Abstract Syntax Trees (AST) and apply transformations on this AST later converting them back to JS again. I wanted to write such codemods for my own projects but there is not whole lot of documentation or tutorial on how to write them. So, I am writing some tutorials for myself and you the reader. I will try to make this as self contained as possible (even if you are lazy to watch the above video).

For these tutorials (I plan to do more than one tutorial but we will see), we will use [ASTExplorer][ast] (the same tool showed in the talk) to visualize the AST and writing the transforms as well.

### Problem:

I looked to around a bit to find to good first problem, then it struck to me, now that we have template strings in ES2015, we don't have to write to have to concatenate using `+` operator. So our aim is to convert this

{% highlight javascript %}
'Yo ' + name + '! What are you doing?'  
{% endhighlight %}

to

{% highlight javascript %}
`Yo ${name}! What are you doing?`
{% endhighlight %}

### Solution:

In this section of this tutorial, I will teach to how to use [ASTExplorer](ast) and arrive the solution to our problem incrementally.

Whenever I try to solve a problem, my first approach is to break down the problem into smaller pieces and solve them one by one. To explain this bit more,
you don't need to solve problem in its full generality in the first go, solve for a specific case it may give you insights into how to solve the original problem. I think converting  

{% highlight javascript %}
a + b
{% endhighlight %}

to

{% highlight javascript %}
`${a}${b}`
{% endhighlight %}

is a nice way to begin solving this problem.

#### Step 1:

Our entire solution revolves around transforming one AST into another. In our first step we will explore the AST Lets open  [ASTExplorer](ast). Clear everything inside the editor and enter `a + b`. On the right hand side of the editor, you will see the corresponding AST for the code you have just written. Open the tree a bit and it will look like this.

**Insert image here**

Now look at the words written in **blue**, they represent the nodes in our AST tree and things other than them represent the data about the node. We have the
following words: `File`, `Program`, `ExpressionStatement`, `BinaryExpression`,
`Identifier`. Lets try under to understand them each of them. `File`, `Program` are kind of straight forward to understand from the name. Here we don't have actual file but the ASTExplorer is simulating one to our AST parser (which is *recast* in our case).

Next let's look at `ExpressionStatement` again kind of obvious it refers to `a + b` here. Other examples of `ExpressionStatement` would be a value `4` or function call like `f(a)` (just these term in isolated line because JS automatically inserts `;` for us). `BinaryExpression` is again easy to infer from the name it refers to our expression `a + b`. The two `Identifier` node is refers to the variables `a` and `b`.     

Lets look at what the AST of `${a}${b}` (*I don't how to write \` in the markdown highlight so excuse me for that. Just treat as if they are present*).
This is what it looks like

**Insert image here**

This time it is not as straight forward to understand. We have `TemplateLiteral` which represent our template string `${a}${b}`. `a` & `b` are represent the `Identifier`'s in the *expressions* array. But what is this *quasis* which is array of `TemplateElement`? Now hover the mouse over one of the `TemplateElement` we will see the `${` is highlighted in the editor i.e, whenever you hover over a node you will see the corresponding code the node represents in the AST. This is especially helpful when you encounter new node type or there are multiple nodes of the same type and you want to see which corresponds to what etc., Now we have observe that *quasis* represent the regions of a template string between the *expressions* (or simply variables `a` & `b` in our case) including the region of template string before the first expression and region of template string after the last expression and each of these regions is represented as a `TemplateElement` in the AST.     

In the `TemplateElement` node highlighted in the above image, we have a *value* key which has *raw* & *cooked* keys to be empty strings. The following diagram
explains these things.       

**Insert Diagram here**

*raw* and *cooked* only differ when there are escape characters inside the `TemplateElement`.  







[cpojer-talk]: https://www.youtube.com/watch?v=d0pOgY8__JM
[ast]: https://astexplorer.net/
