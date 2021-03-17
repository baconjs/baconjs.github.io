## Wrapping Things in Bacon

I've got a lot of questions along the lines of "can I integrate Bacon with X". And the answer is, of course, Yes You Can. Assuming X is something with a Javascript API that is. In fact, for many values of X, there are ready-made solutions.

- JQuery events is supported out-of-the box 
- With [Bacon.JQuery](https://github.com/baconjs/bacon.jquery), you get more, including AJAX, two-way bindings
- Node.js style callbacks, with (err, result) parameters, are supported with Bacon.fromNodeCallback
- General unary callbacks are supported with Bacon.fromCallback
- There's probably a plenty of wrappers I haven't listed here. Let's put them on the [Wiki](https://github.com/baconjs/bacon.js/wiki/Related-projects), shall we?

In case X doesn't fall into any of these categories, you may have to roll your own. And that's not hard either. Using `Bacon.fromBinder`, you should be able to plug into any data source quite easily. In this blog posting, I'll show some examples of just that.

You might want to take a look at Bacon.js [readme](https://github.com/baconjs/bacon.js?utm_source=javascriptweekly&utm_medium=email) for documentation and reference.

### Example 1: Timer

Let's start with a simple example. Suppose you want to create a stream that produces timestamp events each second. Easy!

Using `Bacon.interval`, you'll get a stream that constantly produces a value. Then you can use `map` to convert the values into timestamps.

```javascript
Bacon.interval(1000).map(function() { return new Date().getTime() })
```

Using `Bacon.fromPoll`, you can have Bacon call your function each 1000 milliseconds, and produce the current timestamp on each call.

```javascript
Bacon.fromPoll(1000, function() { return new Date().getTime() })
```

So, clearly Using `Bacon.fromBinder` is an overkill here, but if you want to learn to roll your own streams, this might be a nice example:

```javascript
var timer = Bacon.fromBinder(function(sink) {
    var id = setInterval(function() {
        sink(new Date().getTime())
    }, 1000)
    return function() {
        clearInterval(id)
    }
})
timer.take(5).onValue(function(value) {
    $("#events").append($("<li>").text(value))
})
```

Try it out: http://jsfiddle.net/PG4c4/

So,

- you call `Bacon.fromBinder` and you provide your own "subscribe" function
- there you register to your underlying data source. In the example, `setInterval`.
- when you get data from your data source, you push it to the provided "sink" function. In the example, you push the current timestamp
- from your "subscribe" function you return another function that cleans up. In this example, you'll call `clearInterval`

### Example 2: Hammer.js

[Hammer.js](http://eightmedia.github.io/hammer.js/) is a library for handling multi-touch gesture events. Just to prove my point, I created a fiddle where I introduce a "hammerStream" function that wraps any Hammer.js event into an EventStream:

```javascript
function hammerStream(element, event) {
    return Bacon.fromBinder(function(sink) {
        function push() {
            sink("hammer time!")
        }
        Hammer(element).on(event, push)
        return function() {
            Hammer(element).off(event, push)
        }
    })
}
```

Try it out: http://jsfiddle.net/axDJy/3/

It's exactly the same thing as with the above example. In my "subscribe" function, I register an event handler to Hammer.js. In this event handler I push a value "hammer time!" to the stream. I return a function that will de-register the hammer event handler.

### More examples

You're not probably surprised at the fact that all the included wrappers and generators (including `$.asEventStream`, `Bacon.fromNodeCallback`, `Bacon.interval`, `Bacon.fromPoll` etc) are implemented on top of Bacon.fromBinder. So, for more examples, just dive into the Bacon.js codebase itself.
