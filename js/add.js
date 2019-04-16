/*global $ */

function auto(kind, prefix, field) {
  'use strict';
  $("#" + kind).autocomplete({
    source: function(request, response) {
      $.ajax({
        url: "/" + kind + "s.json",
        method: "GET",
        dataType: "json",
        data: { query: request.term },
        success: function(data) {
          response($.map(data, function(item) {
            return {
              label: prefix + item.id + ': ' + item.text,
              value: item.text,
              id: item.id
            };
          }));
        }
      });
    },
    select: function(event, ui) {
      $(field).val(ui.item.id);
    }
  });
}

$(function() {
  'use strict';
  auto("cause", "C", "#cid");
  auto("risk", "R", "#rid");
  auto("effect", "E", "#eid");
  auto("plan", "P", "#pid");
});
