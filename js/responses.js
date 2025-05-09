// SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
// SPDX-License-Identifier: MIT

/*global $, dateFns */

function on_schedule(label, f) {
  "use strict";
  $("#schedule_" + label).on("click", function() {
    $("#schedule").val(dateFns.format(f(new Date()), "DD-MM-YYYY"));
    return false;
  });
}

function on_mnemo(id) {
  "use strict";
  var $span = $("#" + id);
  $span.on("click", function() {
    $("#schedule").val($span.text());
    return false;
  });
}

$(function() {
  "use strict";
  on_schedule("asap", function(today) { return dateFns.addDays(today, 2); });
  on_schedule("week", function(today) { return dateFns.addDays(today, 4); });
  on_schedule("month", function(today) { return dateFns.addDays(today, 20); });
  on_schedule("later", function(today) { return dateFns.addMonths(today, 3); });
  on_mnemo("daily");
  on_mnemo("weekly");
  on_mnemo("biweekly");
  on_mnemo("monthly");
  on_mnemo("quarterly");
  on_mnemo("annually");
});
