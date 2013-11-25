#= require ./../../vendor/marked.js


module = angular.module "plunker.markdown", []

module.directive "markdown", [ ->
  restrict: "A"
  link: ($scope, $element, $attrs) ->
    marked.setOptions
      gfm: true
      #highlight: (code, lang, callback) -> callback(null, code)
      tables: false
      breaks: false
      pedantic: false
      sanitize: true
      smartLists: true
      smartypants: false
      langPrefix: 'lang-'
      
    $scope.$watch  $attrs.markdown, (markdown) ->
      if markdown then $element.html marked(markdown or "")
      else $element.html("")
]