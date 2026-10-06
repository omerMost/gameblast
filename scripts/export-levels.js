// Evaluate only the prototype's level declarations against a recording builder.
// No game, browser, physics, or external packages are required.
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('prototype/index.html', 'utf8');
const declarations = source.slice(source.indexOf('const SH='), source.indexOf('/* ---------------- STATE'));
const scope = {};
vm.runInNewContext(declarations + ';globalThis.levels=LEVELS', scope);
const levels = scope.levels.map(level => {
  const ops = [], refs = new Map();
  const builder = new Proxy({}, { get(_, name) {
    return (...args) => {
      if (['hang', 'tether', 'balloon'].includes(name)) {
        const bodyIndex = name === 'balloon' ? 2 : 1;
        const localIndex = name === 'balloon' ? 3 : 2;
        const body = args[bodyIndex];
        if (!refs.has(body)) throw new Error('Unrecorded rope load');
        const ref = refs.get(body);
        if (!ref.id) { ref.id = 'body' + refs.size + '_' + ref.index; ref.op.push(ref.id); }
        args[bodyIndex] = ref.id;
        const point = args[localIndex]; args[localIndex] = [point.x, point.y];
      }
      if (name === 'enemy' && args[2]) args[2] = Object.fromEntries(Object.entries(args[2]).map(([k,v]) => [k,Boolean(v)]));
      const op = [name, ...args]; ops.push(op);
      const body = {}; refs.set(body, {op, index:ops.length - 1}); return body;
    };
  }});
  level.build(builder);
  const data = {...level, build:ops};
  if ('alertAt' in data) { data.alert_at=data.alertAt; delete data.alertAt; }
  return data;
});
const text = 'class_name Levels\nextends RefCounted\n## Generated from prototype/index.html by node scripts/export-levels.js.\n## Original order, coordinates, ammo, par and behavior options.\nconst LEVELS := [\n' + levels.map(level => '\t'+JSON.stringify(level)).join(',\n') + '\n]\n';
if (process.argv.includes('--check')) {
  if (fs.readFileSync('godot/levels/levels.gd','utf8') !== text) { console.error('Level data differs from prototype'); process.exit(1); }
  console.log('LEVEL SOURCE: PASS (40 levels)');
} else fs.writeFileSync('godot/levels/levels.gd', text);
