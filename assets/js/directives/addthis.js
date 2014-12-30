window.angular.module("plunker.addthis", [
  
])

.directive("addthisToolbox", ["$document", "$location", "$timeout", "$window", function ($document, $location, $timeout, $window) {
  return {
    restrict: "A",
    link: function ($scope, $element, $attrs) {
      $timeout(function () {
        if (!$window.addthis_config) $window.addthis_config = {};
        if (!$window.addthis_share) $window.addthis_share = {};
        
        if ($window.addthis) {
          var config = {
            ui_click: true,
            data_track_clickback: false,
            data_ga_tracker: $window.ga,
          };
          var sharing = {
            url: ($attrs.addthisPath ? $location.protocol() + "://" + $location.host() + ($location.port() ? ":" + $location.port() : "") + $attrs.addthisPath : $attrs.addthisUrl) || $location.absUrl(),
            title: $attrs.addthisTitle || $attrs.addthisDescription || $document[0].title,
            description: $attrs.addthisDescription || $attrs.addthisTitle || "",
            templates: {
              twitter: "'{{title}}' on @plnkrco: {{url}}",
            },
          };

          $element.addClass("addthis_sharing_toolbox");

          $window.addthis.toolbox($element[0], config, sharing);
          
        }
      });
      
      angular.element($document[0].body).on("click", "#at3win a, #at3lb a, #at20mc a", function (e) {
        console.log("E", e);
        
        e.stopPropagation();
        e.preventDefault();
      });
    }
  }
}])

;