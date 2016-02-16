"use strict";

// on page load template all the panels then load data into them
$(function() {
  if (panelParams) {
    for (var i = 0; i < panelParams.length; i++) {
      console.log(panelParams[i]);

      templatePanel(i);
      getPanelData(i);
    }
  }
});

// set up simple bind on all panels
var dataBindings = [];
function templatePanel(i) {
  var html = panelHTML.replace(/panelx/g, "panel" + i);
  $(".card-columns").append(html);
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
    title: panelParams[i].title || panelParams[i].kind,
    subtitle: panelParams[i].property || "",
  });

  if (Object.prototype.toString.call(data) == "[object Array]") {
    $(dataBindings[i]._el).find(".content")
      .html('<canvas id="chart' + i + '" width="400" height="400"></canvas>');
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
      .html('<canvas id="chart' + i + '" width="400" height="400"></canvas>');
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
  else { // Number
    dataBindings[i].outputData({
      text: data
    });
  }
}

// build URL of panels query
function appendPanelParams() {
  var serialized = $('#panelParamsForm').serializeArray();
  var query = { panels: panelParams };
  var panel = {};
  for (var i = 0; i < serialized.length; i++) {
    var name = serialized[i].name;
    panel[serialized[i].name] = serialized[i].value;
  }
  query.panels.push(panel);
  var queryString = $.param(query);

  // var queryString = "";
  // $("#panelParamsForm :input").each(function(i, input) {
    // var name = "panels[]" + input.name.replace(/\w+/, "[$&]");
    // var val = $(input).val();
    // if (!!val) queryString += "&" + name + "=" + val;
  // });
  // queryString = queryString.slice(1); // remove first &

  window.location = "?" + queryString;
  console.log(queryString);
}
