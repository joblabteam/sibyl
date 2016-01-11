SimpleBind = function(model) {
  this._model = model;
  this._el = document.querySelector('[data-sb-' + model + ']');
  if (!this._el) this._el = document;
};

SimpleBind.prototype.outputData = function(data) {
  if (data) {
    for (var attr in data) {
      if (Object.prototype.hasOwnProperty.call(data, attr)) {
        var nodes = this.outputNodes(attr);
        for (var i = 0; i < nodes.length; i++) {
          var node = nodes[i];
          var format = node.attributes['data-sb-format'];
          if (format) {
            if (format.value)
              node.innerHTML = SimpleBind._interpolate(format.value, data[attr]);
          }
          else {
            node.innerHTML = data[attr];
          }

          var attrs = node.attributes['data-sb-attributes'];
          if (attrs && attrs.value) {
            attrs = attrs.value.split(' ');
            for (var j = 0; j < attrs.length; j++) {
              var format = node.attributes['data-sb-' + attrs[j] + '-format'];
              if (format) {
                if (format.value)
                  node.setAttribute(attrs[j], SimpleBind._interpolate(format.value, data[attr]));
              }
              else {
                node.setAttribute(attrs[j], data[attr]);
              }
            }
          }
        }
      }
    }
  }
  else {
    var attribute = 'data-sb-' + this._model + '-output';
    var nodes = this.outputNodes('', true);
    var output = {};
    for (var k = 0; k < nodes.length; k++)
      output[ nodes[k].attributes[attribute].value ] = nodes[k].innerHTML;
    return output;
  }
};

SimpleBind.prototype.outputNodes = function(name, single) {
  return this.nodes('output', name, single);
};

SimpleBind.prototype.inputData = function(data) {
  if (data) {
    for (var attr in data)
      if (Object.prototype.hasOwnProperty.call(data, attr))
        this.inputNodes(attr).value = data[attr];
  }
  else {
    var attribute = 'data-sb-' + this._model + '-input';
    var nodes = this.inputNodes();
    var output = {};
    for (var i = 0; i < nodes.length; i++)
      output[ nodes[i].attributes[attribute].value ] = nodes[i].value;
    return output;
  }
};

SimpleBind.prototype.inputNodes = function(name) {
  return this.nodes('input', name, true);
};

SimpleBind.prototype.nodes = function(type, name, single) {
  var attribute = 'data-sb-' + this._model + '-' + type;
  if (name)
    return single ?
      this._el.querySelector('[' + attribute + '="' + name + '"]') :
      this._el.querySelectorAll('[' + attribute + '="' + name + '"]');
  else
    return this._el.querySelectorAll('[' + attribute + ']');
};

SimpleBind.prototype.update = function() {
  this.outputData(this.inputData());
};

SimpleBind._interpolate = function(attr, str) {
  str = '' + str;
  return attr.replace(/%(s|S|L|R|t\{[^}]+}|f\{[^}]+})/g,
    function(match) {
      if (match.match(/^%s$/))
        return str;
      if (match.match(/^%S$/))
        return str !== '' ? ' ' + str + ' ' : '';
      if (match.match(/^%L$/))
        return str !== '' ? str + ' ' : '';
      if (match.match(/^%R$/))
        return str !== '' ? ' ' + str : '';
      var matches;
      if (matches = /^%t\{([^}]+)}$/.exec(match))
        return str !== '' ? matches[1] : '';
      if (matches = /^%f\{([^}]+)}$/.exec(match))
        return str !== '' ? '' : matches[1];
    }
  );
};
