"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault").default;
Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _isNonNullable = _interopRequireDefault(require("./isNonNullable"));
const toList = (val, config = {}) => {
  if (!(0, _isNonNullable.default)(val) && config?.skipEmpty) {
    return [];
  }
  return Array.isArray(val) ? val : [val];
};
var _default = exports.default = toList;