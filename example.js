$(function () {
  "use strict";

  $(".example").each(function (idx, el) {
    var textarea = $("textarea", el)[0];
    var htmlElement = $($(".example-html", el).get(0));
    var runButton = $($("button.run", el).get(-1));
    var htmlContent = htmlElement.html();

    if (!textarea || !htmlElement) {
      return;
    }

    var cm = CodeMirror.fromTextArea(textarea, {
      mode: "javascript",
      styleSelectedText: true,
      // lineNumbers: true,
    });

    function run() {
      var content = cm.getValue();
      try {
        // reload content of html-element
        htmlElement.html(htmlContent);

        // eval script
        eval(content);
        runButton.removeClass("error");
      } catch (e) {
        console.error(e);
        runButton.addClass("error");
      }
    }

    run();
    runButton.click(run);
  });

  $("textarea.code").each(function (idx, el) {
    console.log(el);
    var cm = CodeMirror.fromTextArea(el, {
      mode: "javascript",
      styleSelectedText: true,
      // lineNumbers: true,
    });
  });
});
