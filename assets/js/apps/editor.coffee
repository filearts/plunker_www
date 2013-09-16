require "../services/session.coffee"


require "../directives/borderLayout.coffee"
require "../directives/codeEditor.coffee"
require "../directives/previewer.coffee"


module = angular.module "plunker.app.editor", [
  "fa.borderLayout"
  
  "plunker.service.session"
  
  "plunker.directive.codeEditor"
  "plunker.directive.previewer"
]

module.controller "Editor", ["$scope", "session", ($scope, session) ->
  client = session.createClient("MainCtrl")
  
  $scope.session = client
  
  client.reset files: [
    filename: "index.html"
    content: """
      <!doctype html>
      <html ng-app="plunker" >
      <head>
        <meta charset="utf-8">
        <title>AngularJS Plunker</title>
        <script>document.write('<base href="' + document.location + '" />');</script>
        <link rel="stylesheet" href="style.css">
        <script data-require="angular.js@1.1.x" src="http://code.angularjs.org/1.1.4/angular.js"></script>
        <script src="app.js"></script>
      </head>
      <body ng-controller="MainCtrl">
        <p>Hello {{name}}!</p>
      </body>
      </html> 
    """
  ,
    filename: "app.js"
    content: """
      var app = angular.module('plunker', []);
       
      app.controller('MainCtrl', function($scope) {
        $scope.name = 'World';
      });
    """
  ,
    filename: "style.css"
    content: """
      p {
        color: red;
      }
    """
  ]
  
  $scope.addFile = ->
    if filename = prompt("Filename?")
      client.fileCreate(filename)
      client.cursorSetFile(filename)
  
  $scope.renameFile = (old_filename) ->
    if client.hasFile(old_filename) and filename = prompt("Filename?", old_filename)
      client.fileRename(old_filename, filename)    
  
  $scope.removeFile = (filename) ->
    if client.hasFile(filename) and confirm("Are you sure you would like to delete #{filename}?")
      client.fileRemove(filename)
  
  $scope.moveTo = (filename) ->
    client.cursorSetFile(filename)
]