## Registration Form

In this tutorial I'll be building a fully functional, however simplified, AJAX
registration form for an imaginary web site.

The registration form could look something like this:

![ui-sketch](https://raw.github.com/raimohanska/nulzzzblog/master/images/registration-form-ui.png)

### Starting with the Naive Approach

This seems ridiculously simple, right? Enter username, fullname, click and you're done. As in

```javascript
registerButton.click(function(event) {
  event.preventDefault()
  var data = { username: usernameField.val(), fullname: fullnameField.val()}
  $.ajax({
    type: "post",
    url: "/register",
    data: JSON.stringify(data)
  })
})
```

At first it might seem so, 
but if you're planning on implementing a top-notch form, you'll want 
to consider

1. Username availability checking while the user is still typing the username
2. Showing feedback on unavailable username
3. Showing an AJAX indicator while this check is being performed
4. Disabling the Register button until both username and fullname have been entered
5. Disabling the Register button in case the username is unavailable
6. Disabling the Register button while the check is being performed
7. Disabling the Register button immediately when pressed to prevent double-submit
8. Showing an AJAX indicator while registration is being processed
9. Showing feedback after registration

Some requirements, huh? Still, all of these sound quite reasonable, at least to me.
I'd even say that this is quite standard stuff nowadays. You might now model the UI like this:

![dependencies](https://raw.github.com/raimohanska/bacon-devday-slides/master/images/registration-form-thorough.png)

Now you see that, for instance, enabling/disabling the Register button depends on quite a many different things, some
of them asynchronous. 

In my original [blog posting](http://nullzzz.blogspot.fi/2012/11/baconjs-tutorial-part-i-hacking-with.html) I actually
implemented these features using jQuery, with appalling results. Believe me, or have a look...

### Back to Drawing Board

Generally, this is how you implement an app with Bacon.js.

1. Capture input into EventStreams and Properties
2. Transform and compose signals into ones that describe your domain.
3. Assign side-effects to signals

In practise, you'll probably pick a single feature and do steps 1..3 for
that. Then pick the next feature and so on until you're done. Hopefully
you'll do some refactoring on the way to keep your code clean.

Sometimes it may help to draw the thing on paper. For our case study,
I've done that for you:

![signals](https://raw.github.com/raimohanska/bacon-devday-slides/master/images/registration-form-bacon.png)

In this diagram, the greenish boxes represent EventStreams (distinct events) and the gray boxes
are Properties (values that change over time). The top three boxes represent the raw input signals:

* Key-up events on the two text fields
* Clicks on the register button

In this posting we'll capture the input signals, then define the `username` 
and `fullname` properties. In the end, we'll be able to print the values to the 
console. Not much, but you gotta start somewhere.

### Setup

You can just read the tutorial, or you can try things yourself too. In case you prefer the latter, 
here are the instructions.

First, you should get the code skeleton on your machine.

```
git clone https://github.com/raimohanska/bacon-devday-code.git
cd bacon-devday-code
git checkout -t origin/clean-slate
```

So now you've cloned the source code and switched to the [clean-slate](https://github.com/raimohanska/bacon-devday-code/tree/clean-slate) branch. 
Alternatively you may consider forking the repo first and creating a new branch
if you will.

Anyway, you can now open the `index.html` in your browser to see the registration form.
You may also open the file in your favorite editor and have a brief look. You'll find some 
helper variables and functions for easy access to the DOM elements.

### Capturing Input from DOM Events

Bacon.js is not a jQuery plugin or dependent on jQuery in any way. However, if it finds
jQuery, it adds a method to the jQuery object prototype. This method is called `asEventStream`,
and it is used to capture events into an EventStream. It's quite easy to use.

To capture the `keyup` events on the username field, you can do

```javascript
$("#username input").asEventStream("keyup")
```

And you'll get an `EventStream` of the jQuery keyup events. Try this in your browser Javascript console:

```javascript
$("#username input").asEventStream("keyup").log()
```

Now the events will be logged into the console, whenever you type something to the username field (try!).
To define the `username` property, we'll transform this stream into a stream of textfield values (strings)
and then convert it into a Property:

```javascript
$("#username input").asEventStream("keyup").map(function(event) { return $(event.target).val() }).toProperty("")
```

To see how this works in practise, just add the `.log()` call to the end and you'll see the results in your console.

What did we just do?

We used the `map` method to transform each event into the current value of the username field. The `map` method
returns another stream that contains mapped values. Actually it's just like the map function 
in [underscore.js](http://underscorejs.org/), but for EventStreams and Properties.

After mapping stream values, we converted the stream into a Property by calling `toProperty("")`. The empty string is the initial value
for the Property, that will be the current value until the first event in the stream. Again, the toProperty method returns a
new Property, and doesn't change the source stream at all. In fact, all methods in Bacon.js
return something, and most have no side-effects. That's what you'd expect from a functional programming library, wouldn't you?

The `username` property is in fact ready for use. Just name it and copy it to the source code:

```javascript
username = $("#username input").asEventStream("keyup").map(function(event) { return $(event.target).val() }).toProperty("")
```

I intentionally omitted "var" at this point to make it easier to play with the property in the browser developer console.

Next we could define `fullname` similarly just by copying and pasting. Shall we?

Nope. We'll refactor to avoid duplication:

```javascript
function textFieldValue(textField) {
    function value() { return textField.val() }
    return textField.asEventStream("keyup").map(value).toProperty(value())
}

username = textFieldValue($("#username input"))
fullname = textFieldValue($("#fullname input"))
```

Better! In fact, there's already a `textFieldValue` function available in [Bacon.UI](https://github.com/raimohanska/Bacon.UI.js/blob/master/Bacon.UI.js),
and it happens to be included in the code already so you can just go with

```javascript
username = Bacon.UI.textFieldValue($("#username input"))
fullname = Bacon.UI.textFieldValue($("#fullname input"))
```

So, there's a helper library out there where I've shoveled some of the things that seems to repeat in different projects.
Feel free to contribute!

Anyway, if you put the code above into your source code file, reload the page in the browser and type

```javascript
username.log()
```

to the developer console, you'll see username changes in the console log.

### Mapping Properties and Adding Side-Effects

To get our app to actually do something visible besides writing to the console, we'll define a couple of new
`Properties`, and assign our first side-effect. Which is enabling/disabling the Register button based on whether
the user has entered something in both the username and fullname fields.

I'll start by defining the `buttonEnabled` Property:

```javascript
function and(a,b) { return a && b }
buttonEnabled = usernameEntered.combine(fullnameEntered, and)
```

So I defined the Property by combining the two props together, with the `and` function.
The `combine` method works so that when either `usernameEntered` and `fullnameEntered`
changes, the result Property will get a new value. The new value is constructed by applying
the `and` function to the values of both props. Easy! And can be even easier:

```javascript
buttonEnabled = usernameEntered.and(fullnameEntered)
```

This does the exact same thing as the previous one, but relies on the boolean-logic methods
(`and`, `or`, `not`) included in Bacon.js.

But something's still missing. We haven't defined `usernameEntered` and `fullnameEntered`. Let's do.

```javascript
function nonEmpty(x) { return x.length > 0 }
usernameEntered = username.map(nonEmpty)
fullnameEntered = fullname.map(nonEmpty)
buttonEnabled = usernameEntered.and(fullnameEntered)
```

So, we used the `map` method again. It's good to know that it's applicable to both `EventStreams` and `Properties`.
And the `nonEmpty` function is actually already defined in the source code, so you don't actually have to redefine it.

The side-effect part is simple:

```javascript
buttonEnabled.onValue(function(enabled) {
    $("#register button").attr("disabled", !enabled)
})
```

Try it! Now the button gets immediately disabled and will be enabled once you type something in both of the text fields.
Mission accomplished!

But we can do better.

For example,

```javascript
buttonEnabled.not().onValue($("#register button"), "attr", "disabled")
```

This relies on the fact that the `onValue` method, like many other Bacon.js methods, supports different sets of
parameters. One of them is the above form, which can be translated as "call the `attr` method of the register 
button and use `disabled` as the first argument". The second argument for the `attr` method will be taken from the
current property value.

You could also do the same by

```javascript
buttonEnabled.onValue(setEnabled, registerButton)
```

Now we rely on the `setEnabled` function that's defined in our source code, as well as `registerButton`. The above
can be translated to "call the `setEnabled` function and use `registerButton` as the first argument".

So, with some Bacon magic, we eliminated the extra anonymous function and improved readability. Om nom nom.

And that's it for now. We'll do AJAX soon.
