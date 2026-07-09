// SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
// SPDX-License-Identifier: MIT

function dom_by_id(id) {
  "use strict";
  return document.getElementById(id);
}

function dom_show(element) {
  "use strict";
  element.style.display = "";
}

function dom_hide(element) {
  "use strict";
  element.style.display = "none";
}
