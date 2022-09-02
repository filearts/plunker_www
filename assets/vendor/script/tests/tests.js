script('../node_modules/domready/ready.js', function () {

  domready(function() {

    sink('Basic', function(test, ok, before, after) {

      test('should call from chained ready calls', 4, function() {

        script.ready('jquery', function() {
          ok(true, 'loaded from ready callback')
        })

        script.ready('jquery', function() {
          ok(true, 'called jquery callback again')
        })
          .ready('jquery', function() {
            ok(true, 'called ready on a chain')
          })

        script('jquery.js', 'jquery', function() {
          ok(true, 'loaded from base callback')
        })

      })

      test('multiple files can be loaded at once', 1, function() {
        script(['../demos/js/foo.js', '../demos/js/bar.js'], function() {
          ok(true, 'foo and bar have been loaded')
        })
      })

      test('ready should wait for multiple files by name', 1, function() {
        script(['../demos/js/baz.js', '../demos/js/thunk.js'], 'bundle').ready('bundle', function() {
          ok(true, 'batch has been loaded')
        })
      })

      test('ready should wait for several batches by name', 1, function() {
        script('yui-utilities.js', 'yui')
        script('mootools.js', 'moomoo')
        script.ready(['yui', 'moomoo'], function() {
          console.log('ONCE')
          ok(true, 'multiple batch has been loaded')
        })
      })

      test('ready should not call a duplicate callback', 1, function() {
        script.ready(['yui', 'moomoo'], function() {
          console.log('TWICE')
          ok(true, 'found yui and moomoo again')
        })
      })

      test('ready should not call a callback a third time', 1, function() {
        script.ready(['yui', 'moomoo'], function() {
          console.log('THREE')
          ok(true, 'found yui and moomoo again')
        })
      })

      test('should load a single file without extra arguments', 1, function () {
        var err = false
        try {
          script('yui-utilities.js')
        } catch (ex) {
          err = true
          console.log('wtf ex', ex)
        } finally {
          ok(!err, 'no error')
        }
      })

      test('should callback a duplicate file without loading the file', 1, function () {
        script('yui-utilities.js', function () {
          ok(true, 'loaded yui twice. nice')
        })
      })

      test('onerror', 1, function () {
        script('waaaaaaaaaaaa', function () {
          ok(true, 'no waaaa')
        })
      })

      test('setting script path', 3, function () {
        script.path('')
        script(['patha', 'pathb', 'http://ded.github.com/morpheus/morpheus.js'], function () {
          ok(patha == true, 'loaded patha.js')
          ok(pathb == true, 'loaded pathb.js')
          ok(typeof morpheus !== 'undefined', 'loaded morpheus.js from http')
        })
      })

      test('syncronous ordered loading', 2, function () {
        script.order(['order-a', 'order-b', 'order-c'], 'ordered-id', function () {
          ok(true, 'loaded each file in order')
          console.log('loaded each file in order')
        })
        script.ready('ordered-id', function () {
          console.log('readiness by id')
          ok(ordera && orderb && orderc, 'done listen for readiness by id')
        })
      })

    })
    start()
  })
})