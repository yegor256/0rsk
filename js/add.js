/*global $ */

function auto(kind) {
  'use strict';
  var $input = $("#" + kind);
  var closing = false;
  $input.on('input', function() {
    $("#" + kind + '_detach').click();
  });
  $input.autocomplete({
    minLength: 0,
    delay: 300,
    source: function(request, response) {
      $.ajax({
        url: "/" + kind + "s.json",
        method: "GET",
        dataType: "json",
        data: { query: request.term },
        success: function(data) {
          response(data);
        }
      });
    },
    select: function(event, ui) {
      $.each(ui.item.fields, function(field, v) {
        $("#" + field).val(v);
        $("#" + kind + '_detach').show();
      });
    },
    close: function() {
      closing = true;
      setTimeout(function() { closing = false; }, 300);
    }
  });
  $input.focus(function() {
    if (!closing) {
      $(this).autocomplete("search");
    }
  });
}

$(function() {
  'use strict';
  auto("cause");
  auto("risk");
  auto("effect");
  auto("plan");
});
