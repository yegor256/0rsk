// SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
// SPDX-License-Identifier: MIT

/*global $, dateFns */

function on_schedule(label, f) {
  "use strict";
  document.getElementById("schedule_" + label).addEventListener("click", function() {
    document.getElementById("schedule").value = dateFns.format(f(new Date()), "DD-MM-YYYY");
    return false;
  });
}

function on_mnemo(id) {
  "use strict";
  var span = document.getElementById(id);
  span.addEventListener("click", function() {
    document.getElementById("schedule").value = span.textContent;
    return false;
  });
}

document.addEventListener("DOMContentLoaded", function() {
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