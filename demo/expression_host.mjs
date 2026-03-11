// Re-export the expression host as an explicit ES module (.mjs) so Node.js
// test tooling can dynamically import it without a top-level package.json
// "type": "module" declaration.
export {
    setExpressionHost,
    getExpressionHost,
    createDefaultExpressionHost,
    createExpressionModule,
} from './expression_host.js';
