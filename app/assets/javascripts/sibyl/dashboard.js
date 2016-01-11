$(function() {
  if (panelParams) {
    for (var i = 0; i < panelParams.length; i++) {
      console.log(panelParams[i]);

      templatePanel(i);

      getPanelData(i);
    }
  }
});

var dataBindings = [];
function templatePanel(i) {
  dataBindings.push(new SimpleBind("panel" + i));
  html = panelHTML.replace(/panel-/g, "panel" + i + "-");
  $(".card-columns").append(html);
}

function getPanelData(i) {
  $.getJSON(eventsPath, panelParams[i], function(data) {
    outputPanelData(i, data);
  });
}

function outputPanelData(i, data) {
  console.log(data);
  dataBindings[i].outputData({
    title: panelParams[i].kind,
    subtitle: "Subtitle",
    text: data
  });
}

function appendPanelParams() {
  serialized = $('#panelParamsForm').serializeArray();
  query = { panels: panelParams };
  panel = {};
  for (var i = 0; i < serialized.length; i++) {
    panel[serialized[i].name] = serialized[i].value;
  }
  query.panels.push(panel);
  queryString = $.param(query);
  window.location = "?" + queryString;
  console.log(queryString);
}
