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

// Test trim path: comp_0 layer with st=21, trimpath at t=21→0%, t=28→100%
var animData = {
  "v":"5.5.0","fr":30,"ip":0,"op":30,"w":100,"h":100,
  "layers":[{
    "ty":4,"ind":1,"nm":"sl7","ip":21,"op":30,"st":21,
    "ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"k":[0,0]}},
    "shapes":[
      {"ty":"gr","nm":"g1","it":[
        {"ty":"sh","nm":"path1","ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[-50,0],[50,0]],"c":false}}},
        {"ty":"st","c":{"k":[1,0,0]},"o":{"k":100},"w":{"k":5},"lc":2,"lj":1,"ml":4},
        {"ty":"tr","p":{"k":[0,0]},"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}
      ]},
      {"ty":"tm","s":{"a":1,"k":[{"i":{"x":[0.833],"y":[0.833]},"o":{"x":[0.167],"y":[0.167]},"t":23,"s":[0]},{"t":30,"s":[100]}],"ix":1},"e":{"a":1,"k":[{"i":{"x":[0.833],"y":[0.833]},"o":{"x":[0.167],"y":[0.167]},"t":21,"s":[0]},{"t":28,"s":[100]}],"ix":2},"o":{"a":0,"k":0,"ix":3},"m":1}
    ]
  }]
};

var container = document.createElement('div');
document.body.appendChild(container);
var anim = lottie.loadAnimation({ container: container, renderer: 'svg', loop: false, autoplay: false, animationData: animData });
anim.addEventListener('DOMLoaded', function() {
  [21, 22, 24, 25, 26, 28, 29].forEach(function(frame) {
    anim.goToAndStop(frame, true);
    var svg = container.querySelector('svg');
    var html = svg ? svg.innerHTML : 'none';
    // Find all paths
    var strokes = svg ? svg.querySelectorAll('[stroke]') : [];
    console.log('Frame ' + frame + ': #stroke=' + strokes.length);
    for (var i = 0; i < strokes.length; i++) {
      var d = strokes[i].getAttribute('d') || '';
      if (d && d !== 'M0 0') {
        console.log('  d: ' + d.substring(0, 100));
      }
    }
  });
  anim.destroy();
  process.exit(0);
});
