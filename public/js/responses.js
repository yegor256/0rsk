// SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
// SPDX-License-Identifier: MIT

/*global dateFns */

function by_id(id) {
  "use strict";
  return document.getElementById(id);
}

function on_schedule(label, f) {
  "use strict";
  var link = by_id("schedule_" + label);
  var schedule = by_id("schedule");
  if (!link || !schedule) {
    return;
  }
  link.addEventListener("click", function(event) {
    event.preventDefault();
    schedule.value = dateFns.format(f(new Date()), "DD-MM-YYYY");
  });
}

function on_mnemo(id) {
  "use strict";
  var link = by_id(id);
  var schedule = by_id("schedule");
  if (!link || !schedule) {
    return;
  }
  link.addEventListener("click", function(event) {
    event.preventDefault();
    schedule.value = link.textContent;
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
