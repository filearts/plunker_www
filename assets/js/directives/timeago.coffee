#= require ./../../vendor/jquery-timeago/jquery.timeago


module = angular.module "plunker.timeago", []

module.directive "timeago", [ "$timeout", "$filter", ($timeout, $filter) ->
  restrict: "A"
  scope:
    timeago: "="
  replace: true
  link: ($scope, $el, attrs) ->
    $scope.$watch "timeago", (date) ->
      if date
        date = if angular.isDate(date) then date else new Date(date)
        
        $el.text $filter("date")(date, "medium")
        attrs.$set "title", date.toISOString()
        
        $timeout -> $el.timeago()
]