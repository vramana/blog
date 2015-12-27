---
layout: post
title: Path to painless upgrades in Ember
published: false
---

*Note: This post assumes some knowledge of JS features from ES2015*

*This is blog post is continuation to the my other blog post on [How to write a codemod][tutorial]*

### Introduction

After I wrote my last blog post on **How to write a codemod**, I was searching for problems that I can use for this blog post and I remembered about a blog post complaining the Ember 2.0 churn. I felt that codemods would have prevented some of the pain in the upgrading process. So, I wanted to write codemods for ember to show the community that, they can really benefit from codemods. But, the problem, I have absolutely zero knowledge of ember. But somehow, I landed on this [ember deprecations][ember-depr] page and I was immediately excited. It's because they gave the code before deprecation and after deprecation i.e, all we need to do is to write a codemod. I also felt a huge sigh of relief because I don't have to learn a new framework just to write a few codemods.    

In this blog post, we will codemods for two of such deprecations. The first one is extremely simple and second one is slightly more complex and tricky. Let's start!

### A little recap

In my previous blog post, I haven't summarized what we have learned about codemods. Let's quickly go over things we have learned so far.

Codemod is essentially a function which takes `file` and `api` (jscodeshift API) as arguments and returns the transformed JavaScript code as the output. Inside our codemod function, first we convert our given JavaScript code into AST. We now, find all the node we wants to modify and apply the corresponding modifications on them. Once we are done, we convert the modified AST back into JavaScript code.

#### API summary

Note: `j` simply refers to `api.jscodeshift` if you have forgot.

These are [jscodeshift][jscodeshift] API that we have learnt so far.  

- Pascal case version of node type (for exmple `j.Identifier`) is used to check the type of node

- Camel case version of node type (for example `j.identifier`) is used to construct new nodes.    

- `j(...)` takes the source of file and converts it into an AST

- `.find(...)` finds particular nodes in the AST and returns a list of paths. jscodeshift doesn't use an array to represent these paths. Instead it uses custom `Collection` class to represents these paths and provides its own custom methods such as `map`, `filter`, `replaceWith` etc.,

  These are not documented anywhere so for now you have to read the jscodeshift's source to find all such methods. We will use a couple in this blogpost and they should be sufficient. 

- `.replaceWith(...)` replace the node at a each path inside the Collection.

- `.toSource()` converts the transformed AST into JavaScript code.


### Problem 1

Let's look at the first deprecation code that we are going to transform.

```js
// Ember < 2.1

import layout from '../templates/some-thing-lol';

export default Ember.Component.extend({
  defaultLayout: layout
});

// Ember 2.1 and later

import layout from '../templates/some-thing-lol';

export default Ember.Component.extend({
  layout: layout
});

```

### Solution

The simplest solution is to replace `defaultLayout` identifier by `layout` identifier. But it may do false positives transformations. We avoid this problem by looking for some more context i.e, `defaultLayout` is key of an object literal and the object itself is an argument to `Ember.Component.extend` function call.

So, the algorithm will be as follows:

- Find all instances of `Identifier`'s whose name is `defaultLayout` and this will give us paths to all such nodes.

- Go to the path of parent node (`p.parent`) and check if it's a `Property` node and the `defaultLayout` is the key of this property. This also confirms `Property` node parent is an `ObjectExpression` node.

- Check if the parent of `ObjectExpression` node is `CallExpression` and the `CallExpression`'s callee is `Ember.Component.extend`.

- If path a satisfies these properties, then replace the `defaultLayout` identifier with `layout` identifier.

```js
export default function (file, api) {
  const j = api.jscodeshift

  const isProperty = p => {
    return (
      p.parent.node.type === 'Property' &&
      p.parent.node.key.type === 'Identifier' &&
      p.parent.node.key.name === 'defaultLayout'
    )
  }

  const checkCallee = node => {
    const types = (
      node.type === 'MemberExpression' &&
      node.object.type === 'MemberExpression' &&
      node.object.object.type === 'Identifier' &&
      node.object.property.type === 'Identifier' &&
      node.property.type === 'Identifier'
    )

    const identifiers = (
      node.object.object.name === 'Ember' &&
      node.object.property.name === 'Component' &&
      node.property.name === 'extend'
    )

    return types && identifiers
  }

  const isArgument = p => {
    if (p.parent.parent.parent.node.type === 'CallExpression') {
      const call = p.parent.parent.parent.node
      return checkCallee(call.callee)
    }
  }

  const replaceDefaultLayout = p => {
    p.node.name = 'layout'
    return p.node
  }

  return j(file.source)
    .find(j.Identifier, { name: 'defaultLayout' })
    .filter(isProperty)
    .filter(isArgument)
    .replaceWith(replaceDefaultLayout)
    .toSource();
}
```

The code here feels bit long but most of it is checking types of nodes and `Identifier`'s name. Just look at return value of our transform, each line follows the steps we have described above with the exception of first and last line. `filter` method here behaves exactly similar to `Array.filter`.  



### Problem 2

### Solution (Approach 1)


### Solution (Approach 2)



[tutorial]: https://vramana.github.io/blog/2015/12/21/codemod-tutorial/
[ember-depr]: http://emberjs.com/deprecations/v2.x/
[jscodeshift]: https://github.com/facebook/jscodeshift
