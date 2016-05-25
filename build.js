var Fs = require('fs-extra');
var Mincer = require('mincer');
var Package = require('./package.json');
var Path = require('path');
var Rimraf = require('rimraf');


var buildDir = Path.join(__dirname, 'build');
var env = new Mincer.Environment();

env.appendPath('assets/js');
env.appendPath('assets/css');
env.appendPath('assets/vendor');

env.cssCompressor = 'csswring';
env.jsCompressor = 'uglify';

// var manifest = new Mincer.Manifest(env, 'build');

Rimraf.sync(buildDir);


['apps/landing.coffee', 'apps/editor.coffee']
    .forEach(entry => {
        console.log('Building: %s', entry);
        
        var target = Path.join(buildDir, 'js', entry.replace('.coffee', `-${Package.version}.js`));
        var asset = env.findAsset(entry, { bundle: true });
        
        Fs.ensureDirSync(Path.dirname(target));
        Fs.writeFileSync(target, asset.buffer);
        
        console.log('Built %s with size: %d', target, asset.buffer.length);
    });

['apps/landing.less', 'apps/editor.less']
    .forEach(entry => {
        console.log('Building: %s', entry);
        
        var target = Path.join(buildDir, 'css', entry.replace('.less', `-${Package.version}.css`));
        var asset = env.findAsset(entry, { bundle: true });
        
        Fs.ensureDirSync(Path.dirname(target));
        Fs.writeFileSync(target, asset.buffer);
        
        console.log('Built %s with size: %d', target, asset.buffer.length);
    });