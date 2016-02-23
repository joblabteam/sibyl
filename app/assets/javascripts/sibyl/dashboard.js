"use strict";

// on page load template all the panels then load data into them
$(function() {
  Chart.defaults.global.responsive = true;
  Chart.defaults.global.maintainAspectRatio = false;

  console.log(panelParams);
  if (panelParams) {
    for (var i = 0; i < panelParams.length; i++) {
      console.log(panelParams[i]);
      templatePanel(i);
      getPanelData(i);
    }
  }

  $('.dropdown').on('show.bs.dropdown', function () {
    $("#editPanelButton").hide();
    $("#funnelForms").html(funnelForm);
  });

  $(document).on("click", ".card-title", function() {
    var id = $(this).closest(".panel").attr("id").slice(5) * 1;
    var funnel = panelParams[id].funnel;

    $(".dropdown-toggle").dropdown('toggle');
    $("#editPanelButton").show().attr("onclick", "editPanelParams(" + id + "); return false;");
    Object.keys(funnel).forEach(function(panelKey, i) {
      var panel = funnel[panelKey];

      if (i !== 0) addFunnelForm();

      Object.keys(panel).forEach(function(param) {
        if (param == "filters") {
          panel[param].forEach(function(filters, j) {
            $("#funnelForms").find(".add-filter").eq(i).trigger("click");
            Object.keys(filters).forEach(function(filter) {
              $("#funnelForms").find(".filters-container").eq(i).find('[name="funnel[][filters][][' + filter + ']"]').eq(j).val(filters[filter]);
            });
          });
        }
        else {
          $("#funnelForms").find('[name="funnel[][' + param + ']"]').eq(i).val(panel[param]);
        }
      });
    });
    return false;
  });

  $(document).on("click", ".close-panel", function() {
    var id = $(this).closest(".panel").attr("id").slice(5) * 1;
    panelParams.splice(id, 1);
    setLocationParams();
  });

  $(document).on("click", ".export-panel", function() {
    var id = $(this).closest(".panel").attr("id").slice(5) * 1;
    setExportParams(id);
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

  var chartData;
  if (Object.prototype.toString.call(data) == "[object Array]" && Object.keys(data[0]).includes("interval")) {
    $(dataBindings[i]._el).find(".content")
      .html('<canvas id="chart' + i + '" width="" height="300"></canvas>');
    // we know the "interval" key, find the other one
    var keys = Object.keys(data[0]).slice(); // copy don't mutate
    keys.splice(keys.indexOf("interval"), 1);
    var key = keys[0];
    new Chart(document.getElementById("chart" + i).getContext("2d")).Line({
      labels: data.map(function(v) { return v.interval; }),
      datasets: [{
        label: key,
        fillColor: "#FE9B08",
        data: data.map(function(v) { return v[key]; })
      }]
    });
  }
  else if (Object.prototype.toString.call(data) == "[object Object]") {
    if (data.funnel) {
      if (data.funnel.length == 2) {
        dataBindings[i].outputData({ text: Math.round(data.funnel[1].percent) + "%" });
      }
      else {
        $(dataBindings[i]._el).find(".content")
          .html('<canvas id="chart' + i + '" height="300"></canvas>');
        new Chart(document.getElementById("chart" + i).getContext("2d")).Bar({
          labels: data.funnel.map(function(v) { return v.label + " (" + v.value + ")"; }),
          datasets: [{
            label: "Funnel",
            fillColor: "#14A2FF",
            data: data.funnel.map(function(v) { return v.percent; })
          }]
        });
        dataBindings[i].outputData({
          title: (data.funnel[0].label || "All") + " - " + (data.funnel[data.funnel.length - 1].label || "All"),
          subtitle: ""
        });
      }
    }
    else {
      // new Chart(document.getElementById("chart" + i).getContext("2d")).Bar({
        // labels: Object.keys(data),
        // datasets: [{
          // label: "",
          // fillColor: "rgba(50, 100, 200, 0.6)",
          // data: Object.keys(data).map(function (k) { return data[k]; })
        // }]
      // });
      $(dataBindings[i]._el).find(".content")
        .html('<canvas id="chart' + i + '" height="300"></canvas>');
      new Chart(document.getElementById("chart" + i).getContext("2d")).Doughnut(
        Object.keys(data).map(function (k) {
          return {
            label: k,
            value: data[k]
          };
        })
      );
    }
  }
  else { // Number
    dataBindings[i].outputData({ text: data });
  }
}

// add panel to end of params and visit
function editPanelParams(id) {
  var serialized = $('#panelParamsForm').serializeJSON();
  panelParams[id] = serialized;
  setLocationParams();
}

// add panel to end of params and visit
function appendPanelParams() {
  var serialized = $('#panelParamsForm').serializeJSON();
  panelParams.push(serialized);
  setLocationParams();
}

// go to URL of panels query
function setExportParams(id) {
  // var query = { panels: , title: $('[name="title"]').val() };
  // var zlib = btoa(pako.deflate(JSON.stringify(query), { to: 'string' }));
  // var encode = encodeURIComponent(zlib);
  // window.location = "?zlib=" + encode;

  var queryString = $.param(panelParams[id]);
  window.location = eventsPath + ".csv?" + queryString;
}

function setLocationParams() {
  var query = { panels: panelParams, title: $('[name="title"]').val() };
  var zlib = btoa(pako.deflate(JSON.stringify(query), { to: 'string' }));
  var encode = encodeURIComponent(zlib);
  window.location = "?zlib=" + encode;
  // var queryString = $.param(query);
  // window.location = "?" + queryString;
}

function addFunnelForm() {
  $("#funnelForms").append("<hr>");
  $("#funnelForms").append("<hr>");
  $("#funnelForms").append(funnelForm);
}

function removeFilter(e, el) {
  e.preventDefault();
  e.stopPropagation();
  el.closest(".filter-wrapper").remove();

  return false;
}
