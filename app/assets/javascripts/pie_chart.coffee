window.pieChart = (selector, data)->
  pie = new d3pie(selector, _.extend({
#      "header": {
#        "title": {
#          "text": "Contributions",
#          "fontSize": 22,
#          "font": "verdana"
#        },
#        "subtitle": {
#          "color": "#999999",
#          "fontSize": 10,
#          "font": "verdana"
#        },
#        "location": "top-left",
#        "titleSubtitlePadding": 12
#      },
#      "footer": {
#        "color": "#999999",
#        "fontSize": 11,
#        "font": "open sans",
#        "location": "bottom-center"
#      },
    "misc": {
      "colors": {
        "background": null,
        "segments": window.chartColors,
        "segmentStroke": "#ffffff"
      }
    },
    "size": {
      "canvasHeight": 250,
      "canvasWidth": 380,
      "pieOuterRadius": "80%"
    },
    "labels": {
      "outer": {
        "pieDistance": 14
      },
      "inner": {
        "format": "value"
      },
      "mainLabel": {
        "fontSize": 10,
      },
      "percentage": {
        "color": "#e1e1e1",
        "decimalPlaces": 0
      },
      "value": {
        "color": "#e1e1e1",
      },
      "lines": {
        "enabled": true,
        "color": "#cccccc"
      },
      "truncation": {
        "enabled": true
      }
    },
    "tooltips": {
      "enabled": true,
      "type": "placeholder",
      "string": "{label}: {value}, {percentage}%"
    },
    "effects": {
      "pullOutSegmentOnClick": {
        "effect": "linear",
        "speed": 400,
        "size": 10
      }
    }
  }, {"data": data}))
