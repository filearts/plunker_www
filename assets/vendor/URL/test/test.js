var fixtures = [{
	source: 'http://usr:pwd@www.test.com:81/dir/dir.2/index.htm?q1=0&test1&test2=value#top',
    protocol: 'http',
    authority: 'usr:pwd@www.test.com:81',
    userInfo: 'usr:pwd',
    user: 'usr',
    password: 'pwd',
    host: 'www.test.com',
    port: '81',
    relative: '/dir/dir.2/index.htm?q1=0&test1&test2=value#top',
    path: '/dir/dir.2/index.htm',
    directory: '/dir/dir.2/',
    file: 'index.htm',
    query: 'q1=0&test1&test2=value',
    anchor: 'top',
    queryKey: {
		q1: '0',
		test1: '',
		test2: 'value'
    }
}];

var i, l, source, result, prop;

function ok (expr, msg) {
  if (!expr) throw new Error(msg);
}

function testProperty (prop, source, result, prefix) {
    prefix = (prefix) ? prefix + '.' : '';

    test('#' + prefix + prop, function () {
        ok(source[prop] === result[prop], source[prop] + ' !== ' + result[prop]);
    });
}

function testObject (prop, source, result) {
    var i;

    for (i in source) {
        if (source.hasOwnProperty(prop)) {
            testProperty(i, source, result, prop);
        }
    }
}

function testMake (source, result) {
    test('#make', function () {
        ok(source === result, source + ' !== ' + result);
    });
}


for (i = 0, l = fixtures.length; i < l; i++) {
    suite((i + 1) + '. parse');

    source = fixtures[i];

    result = URL.parse(source.source);

    for (prop in source) {
        if (source.hasOwnProperty(prop)) {
            if (typeof source[prop] === 'object') {
                testObject(prop, source[prop], result[prop]);
            } else {
                testProperty(prop, source, result);
            }
        }
    }

    suite((i + 1) + '. make');

    result = URL.make(source);

    testMake(source.source, result);
}