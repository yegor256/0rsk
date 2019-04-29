/*global $, dateFns */

function on_schedule(label, f) {
  "use strict";
  $("#schedule_" + label).on("click", function() {
    $("#schedule").val(dateFns.format(f(new Date()), "DD-MM-YYYY"));
    return false;
  });
}

$(function() {
  "use strict";
  on_schedule("asap", function(today) { return dateFns.addDays(today, 3); });
  on_schedule("week", function(today) { return dateFns.addWeeks(today, 1); });
  on_schedule("month", function(today) { return dateFns.addMonths(today, 1); });
  on_schedule("later", function(today) { return dateFns.addMonths(today, 3); });
});
