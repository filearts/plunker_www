#= require ../services/menu

module = angular.module "plunker.notfound", [
  "plunker.menu"
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.otherwise
    template: """
      <div class="plunker-notfound container">
        <div class="hero-unit">
          <h1>404 Not Found</h1>
          <p>You have reached the end of Plunker.  You are one step away from the
            end of the internet. Please proceed with caution.</p>
          <p><a href="/">I don't like it here, please take me home.</a></p>
        </div>
      </div>
    """
]

module.run ["menu", (menu) ->
  menu.deactivate()
]