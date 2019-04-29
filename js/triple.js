/*global $, dateFns */

function auto(kind, uri) {
  "use strict";
  var $input = $("#" + kind);
  $input.on("input", function() {
    $("#" + kind + "_detach").addClass("red");
  });
  var closing = false;
  $input.autocomplete({
    minLength: 0,
    delay: 300,
    source: function(request, response) {
      $.ajax({
        url: uri,
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
        $("#" + kind + "_detach").show().removeClass("red");
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

function on_detach(button, id) {
  "use strict";
  $(button).on("click", function() {
    $(id).val("");
    $(this).hide();
    return false;
  });
}

$(function() {
  "use strict";
  auto("ctext", "/causes.json");
  auto("rtext", "/risks.json");
  auto("etext", "/effects.json");
  on_detach("#ctext_detach", "#cid");
  on_detach("#rtext_detach", "#rid");
  on_detach("#etext_detach", "#eid");
});
