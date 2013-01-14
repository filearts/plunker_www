module = angular.module "plunker.guard", []

module.factory "guard", [ "$parse", ($parse) ->
  class Guard
    constructor: (@scope, @expression, options = {}) ->
      @viewValue = Number.NaN
      @modelValue = Number.NaN
      
      @getter = $parse(@expression)
      @setter = @getter.assign
      
      throw new Error("Guarded expressions must be writable") unless @setter
      
      @render = angular.noop
      
      @scope.$watch =>
        value = angular.copy(@getter(@scope))
        
        unless angular.equals(@modelValue, value)
          @modelValue = angular.copy(value)
          
          unless angular.equals(@modelValue, @viewValue)
            @viewValue = angular.copy(value)
            
            @render()
    
    setViewValue: (value) =>
      @viewValue = angular.copy(value)
      
      unless angular.equals(@modelValue, @viewValue)
        @modelValue = angular.copy(value)
        @setter(@scope, angular.copy(value))
        
  create = ($scope, expression, options) -> new Guard($scope, expression, options)
  
  
  
  create
    
]