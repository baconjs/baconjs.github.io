## Tutorial Part I - Hacking With jQuery

This is the first part of a hopefully upcoming series of postings
intended as a [Bacon.js](https://github.com/raimohanska/bacon.js)
tutorial. I'll be building a fully functional, however simplified, AJAX
registration form for an imaginary web site. 

This material is based on my presentation/hands-on session at [Reaktor Dev Day 2012](http://reaktordevday.fi/2012/)
where I had to squeeze a Bacon.js intro and a coding session into less than an hour. I didn't have much time
to discuss the problem and jumped into the solution a bit too fast. This time I'll first try to explain the problem
I'm trying to solve with Bacon. So bear with me. Or have a look at the [Full Solution](https://github.com/raimohanska/bacon-devday-code/blob/full-solution/index.html)
first if you like.

Anyway, the registration form could look something like this:

![ui-sketch](https://raw.github.com/raimohanska/nulzzzblog/master/images/registration-form-ui.png)

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
to consider including

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
of them asynchronous. But hey, fuck the shit. Let's just hack it together now, right? Some jQuery and we're done in a while.

[hack hack hack] ... k, done. 

```javascript
var usernameAvailable, checkingAvailability, clicked

usernameField.keyup(function(event) {
  showUsernameAjaxIndicator(true)
  updateButtonState()
  $.ajax({ url : "/usernameavailable/" + usernameField.val()}).done(function(available) {
    usernameAvailable = available
    setVisibility(unavailabilityLabel, !available)
    showUsernameAjaxIndicator(false)
    updateButtonState()
  })
})

fullnameField.keyup(updateButtonState)

registerButton.click(function(event) {
  event.preventDefault()
  clicked = true
  setVisibility(registerAjaxIndicator, true)
  updateButtonState()
  var data = { username: usernameField.val(), fullname: fullnameField.val()}
  $.ajax({
    type: "post",
    url: "/register",
    data: JSON.stringify(data)
  }).done(function() {
    setVisibility(registerAjaxIndicator, false)
    resultSpan.text("Thanks!")
  })
})

updateButtonState()

function showUsernameAjaxIndicator(show) {
  checkingAvailability = show
  setVisibility(usernameAjaxIndicator, show)
}

function updateButtonState() {
  setEnabled(registerButton, usernameAvailable 
                              && nonEmpty(usernameField.val()) 
                              && nonEmpty(fullnameField.val())
                              && !checkingAvailability
                              && !clicked)
}
```

Beautiful? Nope, could be even uglier though. Works? Seems to. Number of variables? 3.

Unfortunately, there's still a major bug in the code: the username availability responses may return in a different order than they were requested,
in which case the code may end up showing an incorrect result. Easy to fix? Well, kinda.. Just add a counter and .. Oh, it's sending 
tons of requests even if you just move the cursor with the arrow keys in the username field. Hmm.. One more variable and.. Still too
many requests... Throttling needed... It's starting to get a bit complicated now... Oh, setTimeout, clearTimeout... DONE.

Here's the code now:

```javascript
var usernameAvailable, checkingAvailability, clicked, previousUsername, timeout
var counter = 0

usernameField.keyup(function(event) {
  var username = usernameField.val()
  if (username != previousUsername) {
    if (timeout) {
      clearTimeout(timeout)
    }
    previousUsername = username
    timeout = setTimeout(function() {
      showUsernameAjaxIndicator(true)
      updateButtonState()
      var id = ++counter
      $.ajax({ url : "/usernameavailable/" + username}).done(function(available) {
        if (id == counter) {
          usernameAvailable = available
          setVisibility(unavailabilityLabel, !available)
          showUsernameAjaxIndicator(false)
          updateButtonState()
        }
      })
    }, 300)
  }
})

fullnameField.keyup(updateButtonState)

registerButton.click(function(event) {
  event.preventDefault()
  clicked = true
  setVisibility(registerAjaxIndicator, true)
  updateButtonState()
  var data = { username: usernameField.val(), fullname: fullnameField.val()}
  $.ajax({
    type: "post",
    url: "/register",
    data: JSON.stringify(data)
  }).done(function() {
    setVisibility(registerAjaxIndicator, false)
    resultSpan.text("Thanks!")
  })
})

updateButtonState()

function showUsernameAjaxIndicator(show) {
  checkingAvailability = show
  setVisibility(usernameAjaxIndicator, show)
}

function updateButtonState() {
  setEnabled(registerButton, usernameAvailable 
                              && nonEmpty(usernameField.val()) 
                              && nonEmpty(fullnameField.val())
                              && !checkingAvailability
                              && !clicked)
}
```

Number of variables: 6
Max. level of nesting: 5

Are your eyes burning already?

Writing this kind of code is like changing diapers. Except kids grow up and change your diapers in the end.
This kind of code just grows uglier and more disgusting and harder to maintain. It's like if your kids gradually started to...
Well, let's not go there.

How to improve this code? With MVC frameworks. Nope. Object-oriented design? Maybe. You'll end up with more code
and better structure, but iIt will still be hard to separate concerns cleanly...

No matter what, you'll need to store the UI state, like whether or not an AJAX request is pending, somewhere. 
And you need to trigger things like enabling/disabling the button somewhere, and usually in many places, as in the code
above. This introduces dependencies in all the wrong places. Now many different parts of code need to know about updating
the status of the button, while it should be the other way around.

With the well-known Observer pattern (say, jQuery custom events) you can do some decoupling, so that you'll have an Observer
that observes many events and then updates the button state. But, this does not solve the problem of providing the 
updateButtonState function with all the relevant data. So you'll end up using one mechanism for triggering state update and
another one for maintaining required mutable state. No good.

Wouldn't it be great if you had some abstraction for a signal that you can observe and compose, so that
the "button enabled" state would be a composite signal constructed from all the required input signals?

Say yes.

Good. The Property class in Bacon.js is just that: a composable signal representing the state of something. The EventStream 
class is a composable signal representing distinct events. Define the following signals:

    var username = ..
    var fullname = ..
    var buttonClick = ..

The rest is just composition.

But hey, I'll get to that in the next posting.
