"use strict";

// on page load template all the panels then load data into them
$(function() {
  Chart.defaults.global.responsive = true;
  Chart.defaults.global.maintainAspectRatio = false;

  if (panelParams) {
    for (var i = 0; i < panelParams.length; i++) {
      console.log(panelParams[i]);

      templatePanel(i);
      getPanelData(i);
    }
  }

  $(document).on("click", ".card-title", function() {
    var id = $(this).closest(".panel").attr("id");
    var i = id.slice(5) * 1; // cut off "panel" and leave the number
    $(".dropdown-toggle").dropdown('toggle');
    var params = panelParams[i];
    Object.keys(params).forEach(function(param) {
      $("#panelParamsForm").find('[name="' + param + '"]').val(params[param]);
    });
    return false;
  });

  $(document).on("click", ".close-panel", function() {
    var id = $(this).closest(".panel").attr("id");
    var i = id.slice(5) * 1; // cut off "panel" and leave the number

    window.location.search = encodeURI(decodeURIComponent(window.location.search.slice(1)).split("&").filter(function(el) {
      return !el.match('panels\\[' + i + '\\]');
    }).map(function(el) {
      var num = el.match('panels\\[([0-9]+)\\]')[1] * 1;
      if (num > i)
        el = el.replace(new RegExp("panels\\[" + num + "\\]"), "panels[" + (num - 1) + "]");
      return el;
    }).join("&"));
  });
});

// set up simple bind on all panels
var dataBindings = [];
function templatePanel(i) {
  var html = panelHTML.replace(/panelx/g, "panel" + i);
  $("#panels").append(html);
  dataBindings.push(new SimpleBind("panel" + i));
}

// request all the panel data
function getPanelData(i) {
  $.getJSON(eventsPath, panelParams[i], function(data) {
    outputPanelData(i, data);
  });
}

// output all data into the panels
function outputPanelData(i, data) {
  console.log(data);

  dataBindings[i].outputData({
    title: panelParams[i].funnel[0].title || panelParams[i].funnel[0].kind || "All",
    subtitle: panelParams[i].funnel[0].property || "",
    text: ""
  });

  if (Object.prototype.toString.call(data) == "[object Array]") {
    $(dataBindings[i]._el).find(".content")
      .html('<canvas id="chart' + i + '" width="" height="300"></canvas>');
    var chartData;
    if (Object.keys(data[0]).includes("interval")) {
      // we know the "interval" key, find the other one
      var keys = Object.keys(data[0]).slice(); // copy don't mutate
      keys.splice(keys.indexOf("id"), 1); // "id" is always nil, remove it
      keys.splice(keys.indexOf("interval"), 1);
      var key = keys[0];
      chartData = {
        labels: data.map(function(v) { return v.interval; }),
        datasets: [
          {
            label: key,
            data: data.map(function(v) { return v[key]; })
          },
        ]
      };
    }
    new Chart(document.getElementById("chart" + i).getContext("2d")).Line(chartData);
  }
  else if (Object.prototype.toString.call(data) == "[object Object]") {
    $(dataBindings[i]._el).find(".content")
      .html('<canvas id="chart' + i + '" height="300"></canvas>');
    if (data.funnel) {
      var chartData = {
        labels: data.funnel.map(function(v) { return v.label + ": " + v.value; }),
        datasets: [{
          label: "Funnel",
          data: data.funnel.map(function(v) { return v.percent; }),
        }],
      };
      new Chart(document.getElementById("chart" + i).getContext("2d")).Bar(chartData);
    }
    else {
      var chartData = {
        labels: Object.keys(data),
        datasets: [
          {
            label: "",
            data: Object.keys(data).map(function (k) { return data[k]; })
          },
        ]
      };
      new Chart(document.getElementById("chart" + i).getContext("2d")).Bar(chartData);
    }
  }
  else { // Number
    dataBindings[i].outputData({
      text: data
    });
  }
}

// build URL of panels query
function appendPanelParams() {
  var serialized = $('#panelParamsForm').serializeJSON();

  var query = { panels: panelParams };
  query.panels.push(serialized);
  var queryString = $.param(query);

  window.location = "?" + queryString;
}

function addFunnelForm() {
  $("#funnelForms").append("<hr>");
  $("#funnelForms").append(funnelForm);
}
