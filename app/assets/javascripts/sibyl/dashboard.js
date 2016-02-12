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
  dataBindings.push(new SimpleBind("panel" + i));
  var html = panelHTML.replace(/panel-/g, "panel" + i + "-");
  $(".card-columns").append(html);
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
    text: data
  });
}

// build URL of panels query
function appendPanelParams() {
  var serialized = $('#panelParamsForm').serializeArray();
  var query = { panels: panelParams };
  var panel = {};
  for (var i = 0; i < serialized.length; i++) {
    panel[serialized[i].name] = serialized[i].value;
  }
  query.panels.push(panel);
  var queryString = $.param(query);
  window.location = "?" + queryString;
  console.log(queryString);
}
