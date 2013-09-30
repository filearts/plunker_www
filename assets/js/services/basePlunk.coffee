module = angular.module "plunker.service.basePlunk", []

module.value "basePlunk",
  files: [
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