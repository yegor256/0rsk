/*global $, dateFns */

function auto(kind) {
  "use strict";
  var $input = $("#" + kind);
  var closing = false;
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
        $("#" + kind + "_detach").show();
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

function on_schedule(label, f) {
  "use strict";
  $("#schedule_" + label).on("click", function() {
    $("#schedule").val(dateFns.format(f(new Date()), 'DD-MM-YYYY'));
    return false;
  });
}

$(function() {
  "use strict";
  auto("cause");
  auto("risk");
  auto("effect");
  auto("plan");
  on_detach("#cause_detach", "#cid");
  on_detach("#risk_detach", "#rid");
  on_detach("#effect_detach", "#eid");
  on_detach("#plan_detach", "#pid");
  on_schedule("asap", function(today) { return dateFns.addDays(today, 3); });
  on_schedule("week", function(today) { return dateFns.addWeeks(today, 1); });
  on_schedule("month", function(today) { return dateFns.addMonths(today, 1); });
  on_schedule("later", function(today) { return dateFns.addMonths(today, 3); });
});
