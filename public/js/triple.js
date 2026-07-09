// SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
// SPDX-License-Identifier: MIT

/*global dom_by_id, dom_hide, dom_show */

var autocomplete_widgets = [];

function trigger_change(element) {
  "use strict";
  element.dispatchEvent(new Event("change", { bubbles: true }));
}

function apply_fields(fields) {
  "use strict";
  Object.keys(fields).forEach(function(field) {
    var element = dom_by_id(field);
    if (!element) {
      return;
    }
    if (typeof fields[field] === "boolean") {
      element.checked = fields[field];
    } else {
      element.value = fields[field];
    }
    trigger_change(element);
  });
}

function item_text(item) {
  "use strict";
  return item.label || item.value || item.text || "";
}

function close_autocomplete_widgets(event) {
  "use strict";
  autocomplete_widgets.forEach(function(widget) {
    if (
      event &&
      (event.target === widget.input || widget.list.contains(event.target))
    ) {
      return;
    }
    widget.close();
  });
}

function auto(kind, uri) {
  "use strict";
  var input = dom_by_id(kind);
  var detach = dom_by_id(kind + "_detach");
  var timer = null;
  var closing = false;
  var items = [];
  var active = -1;
  var list = document.createElement("ul");
  if (!input || !detach) {
    return;
  }
  list.className = "autocomplete";
  list.id = kind + "_autocomplete";
  list.setAttribute("role", "listbox");
  input.setAttribute("aria-autocomplete", "list");
  input.setAttribute("aria-controls", list.id);
  input.insertAdjacentElement("afterend", list);

  function close() {
    list.classList.remove("open");
    list.replaceChildren();
    items = [];
    active = -1;
    input.removeAttribute("aria-activedescendant");
    closing = true;
    setTimeout(function() { closing = false; }, 300);
  }

  function activate(index) {
    active = index;
    list.querySelectorAll("button").forEach(function(button, pos) {
      var selected = pos === active;
      button.classList.toggle("active", selected);
      button.setAttribute("aria-selected", selected ? "true" : "false");
      if (selected) {
        input.setAttribute("aria-activedescendant", button.id);
      }
    });
  }

  function select(item) {
    if (item.fields) {
      apply_fields(item.fields);
    }
    dom_show(detach);
    detach.classList.remove("red");
    close();
  }

  function render(found) {
    close();
    items = found.filter(function(item) {
      return item_text(item);
    });
    items.forEach(function(item, index) {
      var option = document.createElement("li");
      var button = document.createElement("button");
      button.type = "button";
      button.id = kind + "_autocomplete_" + index;
      button.textContent = item_text(item);
      button.setAttribute("role", "option");
      button.setAttribute("aria-selected", "false");
      button.addEventListener("click", function() {
        select(item);
      });
      option.appendChild(button);
      list.appendChild(option);
    });
    if (items.length > 0) {
      list.classList.add("open");
    }
  }

  function search() {
    fetch(uri + "?query=" + encodeURIComponent(input.value), {
      headers: { Accept: "application/json" }
    }).then(function(response) {
      if (!response.ok) {
        return [];
      }
      return response.json();
    }).then(render).catch(close);
  }

  input.addEventListener("input", function() {
    detach.classList.add("red");
    clearTimeout(timer);
    timer = setTimeout(search, 300);
  });
  input.addEventListener("focus", function() {
    if (!closing) {
      search();
    }
  });
  input.addEventListener("keydown", function(event) {
    if (event.key === "ArrowDown" && items.length > 0) {
      event.preventDefault();
      activate((active + 1) % items.length);
    } else if (event.key === "ArrowUp" && items.length > 0) {
      event.preventDefault();
      activate((active + items.length - 1) % items.length);
    } else if (event.key === "Enter" && active >= 0) {
      event.preventDefault();
      select(items[active]);
    } else if (event.key === "Escape") {
      close();
    }
  });

  autocomplete_widgets.push({
    input: input,
    list: list,
    close: close
  });
}

function on_detach(button, id) {
  "use strict";
  var link = document.querySelector(button);
  var input = document.querySelector(id);
  if (!link || !input) {
    return;
  }
  link.addEventListener("click", function(event) {
    event.preventDefault();
    input.value = "";
    dom_hide(link);
  });
}

function on_positive() {
  "use strict";
  var positive = dom_by_id("positive");
  var marker = dom_by_id("marker");
  var impact = dom_by_id("impact");
  if (!positive || !marker || !impact) {
    return;
  }
  positive.addEventListener("change", function() {
    var yes = positive.checked;
    marker.classList.toggle("up", yes);
    marker.classList.toggle("down", !yes);
    impact.querySelectorAll('option[type="negative"]').forEach(function(option) {
      option.hidden = yes;
    });
    impact.querySelectorAll('option[type="positive"]').forEach(function(option) {
      option.hidden = !yes;
    });
    impact.value = 5;
  });
}

function on_emojis() {
  "use strict";
  var emoji = dom_by_id("emoji");
  if (!emoji) {
    return;
  }
  document.querySelectorAll("a.emoji").forEach(function(link) {
    link.addEventListener("click", function(event) {
      event.preventDefault();
      emoji.value = link.textContent;
    });
  });
}

function on_submit() {
  "use strict";
  var form = document.querySelector('form[action$="/triple/save"]');
  var cid = dom_by_id("cid");
  var rid = dom_by_id("rid");
  var eid = dom_by_id("eid");
  if (!form) {
    return;
  }
  form.addEventListener("submit", function(event) {
    if (
      (cid && cid.value) ||
      (rid && rid.value) ||
      (eid && eid.value)
    ) {
      if (!confirm("You are going to MODIFY existing data, are you sure?")) {
        event.preventDefault();
      }
    }
  });
}

document.addEventListener("DOMContentLoaded", function() {
  "use strict";
  auto("ctext", "/causes.json");
  auto("rtext", "/risks.json");
  auto("etext", "/effects.json");
  document.addEventListener("click", close_autocomplete_widgets);
  on_detach("#ctext_detach", "#cid");
  on_detach("#rtext_detach", "#rid");
  on_detach("#etext_detach", "#eid");
  on_positive();
  on_emojis();
  on_submit();
});
