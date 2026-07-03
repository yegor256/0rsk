// SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
// SPDX-License-Identifier: MIT

function by_id(id) {
  "use strict";
  return document.getElementById(id);
}

function show(element) {
  "use strict";
  element.style.display = "";
}

function hide(element) {
  "use strict";
  element.style.display = "none";
}

function trigger_change(element) {
  "use strict";
  element.dispatchEvent(new Event("change", { bubbles: true }));
}

function apply_fields(fields) {
  "use strict";
  Object.keys(fields).forEach(function(field) {
    var element = by_id(field);
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

function auto(kind, uri) {
  "use strict";
  var input = by_id(kind);
  var detach = by_id(kind + "_detach");
  var timer = null;
  var list = document.createElement("ul");
  list.style.display = "none";
  list.style.position = "absolute";
  list.style.zIndex = "1000";
  list.style.margin = "0";
  list.style.padding = ".2em .4em";
  list.style.listStyle = "none";
  list.style.border = "1px solid #999";
  list.style.background = "Canvas";
  list.style.color = "CanvasText";
  input.insertAdjacentElement("afterend", list);

  function close() {
    hide(list);
    list.replaceChildren();
  }

  function select(item) {
    if (item.fields) {
      apply_fields(item.fields);
    }
    show(detach);
    detach.classList.remove("red");
    close();
  }

  function render(items) {
    close();
    items.forEach(function(item) {
      var option = document.createElement("li");
      var button = document.createElement("button");
      button.type = "button";
      button.textContent = item_text(item);
      button.style.background = "none";
      button.style.border = "0";
      button.style.color = "inherit";
      button.style.cursor = "pointer";
      button.style.display = "block";
      button.style.font = "inherit";
      button.style.padding = ".2em";
      button.style.textAlign = "left";
      button.style.width = "100%";
      button.addEventListener("click", function() {
        select(item);
      });
      option.appendChild(button);
      list.appendChild(option);
    });
    if (items.length > 0) {
      show(list);
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
  input.addEventListener("focus", search);
  input.addEventListener("keydown", function(event) {
    if (event.key === "Escape") {
      close();
    }
  });
  document.addEventListener("click", function(event) {
    if (event.target !== input && !list.contains(event.target)) {
      close();
    }
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
    hide(link);
  });
}

function on_positive() {
  "use strict";
  var positive = by_id("positive");
  var marker = by_id("marker");
  var impact = by_id("impact");
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
  var emoji = by_id("emoji");
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
  if (!form) {
    return;
  }
  form.addEventListener("submit", function(event) {
    if (
      by_id("cid").value ||
      by_id("rid").value ||
      by_id("eid").value
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
  on_detach("#ctext_detach", "#cid");
  on_detach("#rtext_detach", "#rid");
  on_detach("#etext_detach", "#eid");
  on_positive();
  on_emojis();
  on_submit();
});
