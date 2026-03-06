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

var animData = {
  "v":"5.5.0","fr":30,"ip":0,"op":50,"w":200,"h":200,
  "layers":[{
    "ty":4,"ind":1,"nm":"test-layer","ip":10,"op":30,"st":10,
    "ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"k":[0,0]}},
    "shapes":[
      {"ty":"rc","s":{"k":[20,20]},"p":{"a":1,"k":[{"t":10,"s":[0,0]},{"t":30,"s":[100,0]}]},"r":{"k":0}},
      {"ty":"fl","c":{"k":[1,0,0]},"o":{"k":100}}
    ]
  }]
};

var container = document.createElement('div');
document.body.appendChild(container);
var anim = lottie.loadAnimation({ container: container, renderer: 'svg', loop: false, autoplay: false, animationData: animData });
anim.addEventListener('DOMLoaded', function() {
  // Test at frame 10
  anim.goToAndStop(10, true);
  var svg = container.querySelector('svg');
  var paths = svg ? svg.querySelectorAll('path') : [];
  console.log('=== Frame 10 ===');
  for (var i=0; i < paths.length; i++) {
    var d = paths[i].getAttribute('d') || '';
    if (d.length > 2) console.log('  path d:', d.substring(0, 120));
  }
  
  // Test at frame 20
  anim.goToAndStop(20, true);
  svg = container.querySelector('svg');
  paths = svg ? svg.querySelectorAll('path') : [];
  console.log('=== Frame 20 ===');
  for (var i=0; i < paths.length; i++) {
    var d = paths[i].getAttribute('d') || '';
    if (d.length > 2) console.log('  path d:', d.substring(0, 120));
  }
  
  anim.destroy();
  process.exit(0);
});
