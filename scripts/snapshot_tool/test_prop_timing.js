const { JSDOM } = require('jsdom');
const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>', { pretendToBeVisual: true });
global.window = dom.window;
global.document = dom.window.document;
global.navigator = dom.window.navigator;
global.Node = dom.window.Node;
global.Element = dom.window.Element;
global.HTMLDivElement = dom.window.HTMLDivElement;
dom.window.HTMLCanvasElement.prototype.getContext = function() { return { fillRect: function(){}, clearRect: function(){}, getImageData: function(){return {data: new Uint8ClampedArray(0)};}, putImageData: function(){}, createImageData: function(){return [];}, setTransform: function(){}, drawImage: function(){}, save: function(){}, restore: function(){}, beginPath: function(){}, moveTo: function(){}, lineTo: function(){}, closePath: function(){}, stroke: function(){}, translate: function(){}, scale: function(){}, rotate: function(){}, arc: function(){}, fill: function(){}, measureText: function(){return {width: 0};}, transform: function(){}, rect: function(){}, clip: function(){} }; };
const lottie = require('./node_modules/lottie-web');

// Direct test: Layer st=10, shape p keyframe at t=10→[0,0], t=30→[100,0]
// We'll set currentFrame to 20 and check what value the property gives
var animData = {
  "v":"5.5.0","fr":30,"ip":0,"op":50,"w":200,"h":200,
  "layers":[{
    "ty":4,"ind":1,"nm":"test-layer","ip":10,"op":30,"st":10,
    "ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"k":[0,0]}},
    "shapes":[
      {"ty":"sh","ks":{"a":1,"k":[{"t":10,"s":[{"c":false,"v":[[0,0],[100,0]],"i":[[0,0],[0,0]],"o":[[0,0],[0,0]]}]},{"t":30,"s":[{"c":false,"v":[[10,0],[110,0]],"i":[[0,0],[0,0]],"o":[[0,0],[0,0]]}]}]}},
      {"ty":"st","c":{"k":[1,0,0]},"o":{"k":100},"w":{"k":2},"lc":2,"lj":1,"ml":4}
    ]
  }]
};

var container = document.createElement('div');
document.body.appendChild(container);
var anim = lottie.loadAnimation({ container: container, renderer: 'svg', loop: false, autoplay: false, animationData: animData });
anim.addEventListener('DOMLoaded', function() {
  // Test at different frames
  var frames = [10, 15, 20, 25, 30];
  frames.forEach(function(frame) {
    anim.goToAndStop(frame, true);
    var svg = container.querySelector('svg');
    var paths = svg ? svg.querySelectorAll('path[d]') : [];
    var pathData = [];
    for (var i = 0; i < paths.length; i++) {
      var d = paths[i].getAttribute('d') || '';
      if (d.length > 2) pathData.push(d.substring(0, 80));
    }
    console.log('Frame ' + frame + ': paths=' + pathData.length + ' first=' + (pathData[0] || 'none'));
  });
  
  anim.destroy();
  process.exit(0);
});
