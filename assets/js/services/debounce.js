// Code by Peter Bacon-Darwin from: http://stackoverflow.com/questions/13320015/how-to-write-a-debounce-service-in-angularjs

module = angular.module("plunker.service.debounce", []);

// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
module.factory('debounce', ["$timeout", "$q", function($timeout, $q) {
  return function(func, wait, immediate) {
    var timeout;
    var deferred = $q.defer();
    
    function debounce() {
      var context = this, args = arguments;
      var later = function() {
        timeout = null;
        if(!immediate) {
          deferred.resolve(func.apply(context, args));
          deferred = $q.defer();
        }
      };
      var callNow = immediate && !timeout;
      if ( timeout ) {
        $timeout.cancel(timeout);
      }
      timeout = $timeout(later, wait);
      if (callNow) {
        deferred.resolve(func.apply(context,args));
        deferred = $q.defer();
      }
      return deferred.promise;
    };
    
    debounce.setWait = function(newWait) {
      wait = newWait;
    };
    
    return debounce;
  };
}]);
