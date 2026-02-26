const fs = require('fs');
const path = require('path');

const SAMPLES_DIR = path.join(__dirname, '../samples');
const SNAPSHOTS_DIR = path.join(__dirname, '../test/snapshots');
const OUTPUT_DIR = path.join(__dirname, '../test/regression');

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// 清理旧的生成文件，但不删除手动维护的文件
const oldFiles = fs.readdirSync(OUTPUT_DIR);
oldFiles.forEach(f => {
    if (f.startsWith('case_') && f.endsWith('_test.mbt')) {
        fs.unlinkSync(path.join(OUTPUT_DIR, f));
    }
});

const samples = fs.readdirSync(SAMPLES_DIR).filter(f => f.endsWith('.json'));

function normalizeSvg(svg) {
    // 匹配数字并将其保留 2 位小数，以匹配 MoonBit SvgRenderer 的 fmt()
    return svg.replace(/(\d+\.\d+)/g, (match) => {
        const val = parseFloat(match);
        const factor = 100.0;
        const rounded = Math.round(val * factor) / factor;
        return rounded.toString();
    });
}

/**
 * 将字符串切分为较短的行，并使用 Array[String] 进行存储，最后在运行时合并。
 * 这样做可以绕过 MoonBit 编译器的单行长度限制和字面量限制。
 */
function chunkString(text, varName, limit = 10000) {
    const chunks = [];
    for (let i = 0; i < text.length; i += limit) {
        chunks.push(text.substring(i, i + limit));
    }
    
    let result = `let ${varName}_chunks : Array[String] = [\n`;
    chunks.forEach(chunk => {
        // 使用 #| 语法，但要注意 #| 会自动添加 \n
        // 为了避免添加额外的 \n，我们将每一块都看作一个独立的 String
        result += `  #|${chunk.replace(/\n/g, '\\n')}\n  ,\n`;
    });
    result += `]\n\n`;
    result += `let ${varName} : String = ${varName}_chunks.fold(fn(acc, x) { acc + x }, "")\n\n`;
    return result;
}

// 修正：实际上 MoonBit 的 #| 会包含末尾换行。
// 如果我们要无损合并，应该使用普通的字符串字面量或者特殊处理。
// 考虑到 Lottie 和 SVG 很大，我们用一个更稳妥的办法：
function chunkStringSafe(text, varName, limit = 5000) {
     const chunks = [];
     for (let i = 0; i < text.length; i += limit) {
         chunks.push(text.substring(i, i + limit));
     }
     
     let result = `fn get_${varName}() -> String {\n`;
     result += `  let chunks = [\n`;
     chunks.forEach(chunk => {
         // 使用 JSON.stringify 来安全地转义字符串并包裹引号
         result += `    ${JSON.stringify(chunk)},\n`;
     });
     result += `  ]\n`;
     result += `  let mut res = ""\n`;
     result += `  for c in chunks { res += c }\n`;
     result += `  res\n`;
     result += `}\n\n`;
     return result;
}

samples.forEach(sampleFile => {
    const sampleName = sampleFile.replace('.json', '');
    const jsonContent = fs.readFileSync(path.join(SAMPLES_DIR, sampleFile), 'utf8');
    
    // 找出所有关联的快照文件
    const snapshotFiles = fs.readdirSync(SNAPSHOTS_DIR)
        .filter(f => f.startsWith(sampleName + '_frame_') && f.endsWith('.svg'))
        .sort((a, b) => {
            const frameA = parseInt(a.match(/frame_(\d+)/)[1]);
            const frameB = parseInt(b.match(/frame_(\d+)/)[1]);
            return frameA - frameB;
        });

    if (snapshotFiles.length === 0) return;

    // 生成 MoonBit 代码
    const safeName = sampleName.replace(/[^a-zA-Z0-9]/g, '_');
    let mbtCode = `// Generated from ${sampleFile}\n\n`;
    
    mbtCode += chunkStringSafe(jsonContent, `json_${safeName}`);
    
    const svgVars = [];
    snapshotFiles.forEach(sf => {
        const frameMatch = sf.match(/frame_(\d+)/);
        const frame = frameMatch ? frameMatch[1] : "0";
        const svgVarName = `svg_${safeName}_f${frame}`;
        const svgContent = fs.readFileSync(path.join(SNAPSHOTS_DIR, sf), 'utf8');
        const normalizedSvg = normalizeSvg(svgContent);
        
        mbtCode += chunkStringSafe(normalizedSvg, svgVarName);
        svgVars.push({ frame, varName: svgVarName });
    });

    mbtCode += `test "regression/${sampleName}" {\n`;
    mbtCode += `  let json_data = get_json_${safeName}()\n`;
    mbtCode += `  let snapshots : Array[RegressionSnapshot] = [\n`;
    
    svgVars.forEach(sv => {
        mbtCode += `    { frame: ${parseFloat(sv.frame).toFixed(1)}, svg: get_${sv.varName}() },\n`;
    });
    
    mbtCode += `  ]\n`;
    mbtCode += `  run_regression_test(json_data, snapshots)\n`;
    mbtCode += `}\n`;

    const outputFileName = `case_${safeName}_test.mbt`;
    fs.writeFileSync(path.join(OUTPUT_DIR, outputFileName), mbtCode);
    console.log(`Generated test case for: ${sampleFile} -> ${outputFileName}`);
});
