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
        var $field = $("#" + field);
        if (typeof v === "boolean") {
          $field.prop("checked", v);
        } else {
          $field.val(v);
        }
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
  $('#positive').change(function() {
    if ($(this).is(':checked')) {
      $('#marker').addClass('up').removeClass('down');
      $('#impact option[type="negative"]').attr('hidden', true);
      $('#impact option[type="positive"]').attr('hidden', false);
      $('#impact').val(5);
    } else {
      $('#marker').addClass('down').removeClass('up');
      $('#impact option[type="negative"]').attr('hidden', false);
      $('#impact option[type="positive"]').attr('hidden', true);
      $('#impact').val(5);
    }
  });
});
