module = angular.module "plunker.jobs", [
  "plunker.menu"
]

module.directive "plunkerJobs", [ ->
  restrict: "E"
  replace: true
  template: """
    <div class="plunker-jobs container">
      <div class="row">
        <div class="span12">
          <iframe class="plunker-jobs" src="http://plunker.jobthread.com/" width="100%" height="800px" frameborder="0">
          </iframe>
        </div>
      </div>
    </div>
  """
  link: ($scope, $el, attrs) ->
]

module.run ["$rootScope", "menu", ($rootScope, menu) ->
  menu.addItem "jobs",
    title: "Job directory"
    href: "/jobs"
    'class': "icon-edit"
    text: "Jobs"
]

module.config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when "/jobs",
    template: """
      <plunker-jobs></plunker-jobs>
    """
    controller: ($scope) ->
      console.log "Hello world", arguments...
]