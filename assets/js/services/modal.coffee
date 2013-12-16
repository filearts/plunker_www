module = angular.module "plunker.modal", []

module.factory "modal", ["$rootScope", "$document", "$compile", "$templateCache", "$injector", ($rootScope, $document, $compile, $templateCache, $injector) ->
  (templateUrl, controller) ->
    $body = $document.find("body")
    $scope = $rootScope.$new()
    originalOverflow = $body.css("overflow")
    markupLinker = $compile """
      <div class="plunker-modal-overlay">
        <div class="plunker-modal-container">
          <a class="close" ng-click="$modal.close()">&times;</a>
          #{$templateCache.get(templateUrl)}
        </div>
      </div>
    """
    
    $modal =
      close: ->
        stopListening()
        $scope.$destroy()
        $el.remove()
        $body.css overflow: originalOverflow
    
    $scope.$modal = $modal  
    $el = markupLinker($scope)
    $body.prepend($el).css("overflow", "hidden")
                         
    $injector.invoke(controller, controller, $scope: $scope) if controller
  
    stopListening = $rootScope.$on "$routeChangeStart", -> $modal.close()
]
