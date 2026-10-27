// Vercel 入口：加载 nest build 产物（dist/src/main-vercel.js）
// 注意：Vercel 构建顺序为 npm install → vercel-build（nest build）→ 本函数构建
module.exports = require('../dist/src/main-vercel.js').default;
