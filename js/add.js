/*global $ */

function auto(kind) {
  'use strict';
  $("#" + kind).autocomplete({
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
      });
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
