## Bus of Doom

In a previous [Bacon blog post](http://baconjs.blogspot.fi/2014/12/structuring-real-life-applications.html) a way to structure Bacon application was outlined. It introduces Buses as a central way to glue components with each other. I'm in a very strong disagreement with the proposed style. Why?

[Quoting Erik Meijer](https://social.msdn.microsoft.com/Forums/en-US/bbf87eea-6a17-4920-96d7-2131e397a234/why-does-emeijer-not-like-subjects)

> Subjects are the "mutable variables" of the Rx world and in most cases you do not need them.

In Bacon parlance that would be

> Buses are the "mutable variables" of the Bacon world and in most cases you do not need them.

Now, that needs an explanation. We can split the statement to two parts and treat each individually. "Why Buses (and mutable variables) are bad", then "why you don't usually need them".


### Problems with Bus

There was a time when data structures in our programs were built by mutating those data structures. In case you have entered this field only recently you may be a lucky one and haven't seen that madness in full glory (== spaghetti).

```javascript
var cart = ShoppingCart()
var view = ShoppingCartView()
view.cart = cart
```

This was a bad idea as it creates temporal dependencies all over the program, making it difficult to locally understand how a piece of code works. Instead, a global view on a program is required. Who mutates what and when. It also created many bugs as components of a system are from time to time in an invalid state. Most common invalid state being at a construction phase where fields are initialized to nulls. A whole slew of bugs were eliminated and sanity regained by moving to immutable data.

```javascript
var cart = ShoppingCart()
var view = ShoppingCartView(cart)
```

Ok, what does all that have to do with Buses? Well, Buses introduce similar temporal dependencies to your program. Is that component ready to be used? I don't know, did you plug its Buses already with this and that? 

```javascript
var shoppingCartBus = new Bacon.Bus()
$.ajax('/api/cart').done(cart => shoppingCartBus.push(cart))
...
shoppingCartBus.onValue(cart => renderCart(cart))
```

Here's a recent bug (simplified from a real world app) found in our company's internal chat. Can you spot it? 

There's a chance that the ajax call on line 2 returns before line 4 is executed, thus the event is completely missed. It is temporal dependencies like that which are nearly impossible to understand in a bigger context. And what's worse, these bugs are difficult to reproduce as we are programming in a setting where stuff is nondeterministic (timers, delays, network calls etc.). I'm sure that many Bus fetished programs contain subtle bugs like above.


### How to avoid Buses

I'll give examples of techniques avoiding Buses by refactoring the example in the previous blog post.

The first one is simple and obvious. Turn inputs of a component to be input arguments of the component.

Before:

```javascript
function ShoppingCart(initialContents) {
  var addBus = new Bacon.Bus()
  var removeBus = new Bacon.Bus()
  var contentsProperty = Bacon.update(initialContents,
    addBus, function(contents, newItem) { return contents.concat(newItem) },
    removeBus, function(contents, removedItem) { return _.remove(contents, removedItem) }
  )
  return {
    addBus: addBus,
    removeBus: removeBus,
    contentsProperty: contentsProperty
  }
}
```

After:

```javascript
function ShoppingCart(initialContents, addItem, removeItem) {
  return Bacon.update(initialContents,
    addItem, function(contents, newItem) { return contents.concat(newItem) },
    removeItem, function(contents, removedItem) { return _.remove(contents, removedItem) }
  )
}
```

I'm pretty sure everyone agrees that the refactored version is simpler. 

The next refactoring has to do with remove links. Each shopping cart item will have a link and clicking a link will remove the item from a cart. The refactored version of the ShoppingCart needs `removeItem` click stream as a function argument, but the individual items are created dynamically as the user selects items. This can be solved by event delegation.

```javascript
$('#shopping-cart').asEventStream('click', '.remove-item')
```

You can state just once and for all: here's a stream of `clicks` of every `.remove-item` link in the shopping cart, and **of all the future** `.remove-item` links that will appear in the shopping cart. That is fantastic. It's like, you put it there and there it is. Event delegation is such a god sent tool and my heart fills with joy every time I have a chance to use it. After that the click events must be associated with items. A canonical way to do it is with data attributes.

Now the sample program is Bus-free.

```javascript
function ShoppingCart(initialContents, addItem, removeItem) {
  return Bacon.update(initialContents,
    addItem, function(contents, newItem) { return contents.concat(newItem) },
    removeItem, function(contents, removedItem) { return _.remove(contents, removedItem) }
  )
}

var removeItemStream = $('#shopping-cart').asEventStream('click', '.remove-item')
  .map(function(e) { return $(e.currentTarget).data('id') })
var newItemView = NewItemView()
var cart = ShoppingCart([], newItemView.newItemStream, removeItemStream)
var cartView = ShoppingCartView(cart)
```

All done? Not yet. `removeItemStream` is hanging there while it probably should be part of `ShoppingCartView`. 

```javascript
function ShoppingCartView(cart) {
  return {
    cartView: ...
    removeItemStream: $('#shopping-cart').asEventStream('click', '.remove-item')
      .map(function(e) { return $(e.currentTarget).data('id') })
}
```

Whoops, now we introduced a cyclic dependency between `ShoppingCart` and `ShoppingCartView`.

```javascript
var cart = ShoppingCart(initialContents, addItem, removeItemStream)
var {removeItemStream} = ShoppingCartView(cart)
```

Cyclic dependency is often given as an example where Buses are needed. After all the hard work should we now reintroduce Buses?

Here a Bus can be used to break the cyclic dependency, just as a mutable variable would do if you will. But we have other options too. Why don't we factor the components so that the cyclic dependency completely disappears.

```javascript
function RemoveItems(container) {
  return {
    view: ...
    removeItemStream: container.asEventStream('click', '.remove-item')
      .map(function(e) { return $(e.currentTarget).data('id') })
}

var viewContainer = $('#shopping-cart')
var removeItems = RemoveItems(viewContainer)
var cart = ShoppingCart(initialContents, addItem, removeItems.removeItemStream)
ShoppingCartView(viewContainer, cart, removeItems)
```

Similar factorings can be almost always used to break cyclic dependencies.

### Conclusion

Avoid Buses. View those as mutable variables and you will understand the kinds of problems they create. By relating Buses to mutable variables gives you an intuition on how to avoid those in a first place.

