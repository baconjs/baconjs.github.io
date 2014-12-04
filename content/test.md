The Internet is full of smart peanut-size examples of how to solve X with "FRP" and Bacon.js. But how to organize a real-world size application? That's been [asked](https://github.com/baconjs/bacon.js/issues/478) once in a while and indeed I have an answer up in my sleeve. Don't take though that I'm saying this is the The Definitive Answer. I'm sure your own way is as good or better. Tell me about it!

I think there are some principles that you should apply to the design of any application though, like [Single Reponsibility Principle](http://en.wikipedia.org/wiki/Single_responsibility_principle) and [Separation of Concerns](http://en.wikipedia.org/wiki/Separation_of_concerns). Given that, your application should consist of components that are fairly independent of each others implementation details. I'd also like the components to communicate using some explicit signals instead of shared mutable state (nudge nudge Angular). For this purpose, I find the Bacon.js `EventStreams` and `Properties` quite handy. 

So if a component needs to act when a triggering event occurs, why not give it an `EventStream` representing that event in its constructor.  The `EventStream` is an abstraction for the event source, so the implementation of your component is does not depend on where the event originates from, meaning you can use a WebSocket message as well as a mouse click as the actual event source. Similarly, if you component needs to display or act on the *state* of something, why not give it a `Property` in its constructor.

When it comes to the outputs of a component, those can exposed as `EventStreams` and `Properties` in the component's public interface. In some cases it also makes sense to publish a `Bus` to allow plugging in event sources after component creation.

For example, a ShoppingCart model component might look like this.

```javascript
function ShoppingCart(initialContents) {
  var addBus = new Bacon.Bus()
  var removeBus = new Bacon.Bus()
  var contentsProperty = Bacon.update(initialContents,
    addBus, function(contents, newItem) { return contents.concat(newItem) },
    removeBus, function(contents, removedItem) { return _.remove(contents, removedItem) }
  )
  return {
    addBus: addBus,
    removeBus: removeBus,
    contentsProperty: contentsProperty
  }    
}
```

Internally, the ShoppingCart contents are composed from an initial status and `addBus` and `removeBus` streams using `Bacon.update`.

The external interface of this component exposes the `addBus` and `removeBus` buses where you can plug external streams for adding and removing items. It also exposes the current contents of the cart as a `Property`.

Now you may define a view component that shows cart contents, using your favorite DOM manipulation technology, like [virtual-dom](https://github.com/Matt-Esch/virtual-dom):

```javascript
function ShoppingCartView(contentsProperty) {
  function updateContentView(newContents) { /* omitted */ }
  contentsProperty.onValue(updateContentView)
}
```

And a component that can be used for adding stuff to your cart:

```javascript
function NewItemView() {
  var $button, $nameField // JQuery objects
  var newItemProperty = Bacon.$.textFieldValue($nameField) // property containing the item being added
  var newItemClick = $button.asEventStream("click") // clicks on the "add to cart" button
  var newItemStream = newItemProperty.sampledBy(newItemClick)
  return {
    newItemStream: newItemStream
  }
}
```

And you can plug these guys together as follows.

```javascript
var cart = ShoppingCart([])
var cartView = ShoppingCartView(cart.contentsProperty)
var newItemView = NewItemView()
cart.addBus.plug(newItemView.newItemStream)
```

So there you go!
