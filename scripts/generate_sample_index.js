const fs = require('fs');
const path = require('path');

const samplesDir = path.join(__dirname, '../samples');
const outputDir = path.join(__dirname, '../demo/public');
const outputFile = path.join(outputDir, 'sample_index.json');

/**
 * 根据文件名判断来源并分组
 * @param {string} filename 
 * @returns {string}
 */
function getSource(filename) {
    if (filename.startsWith('1_')) return 'LottieFiles';
    if (filename.startsWith('2_')) return 'Lottie-Web Standard';
    if (filename.startsWith('3_')) return 'Lottie-Web Expressions';
    if (filename.startsWith('4_')) return 'Lottie-iOS Samples';
    return 'Unknown';
}

/**
 * 提取 Lottie JSON 的特性标签
 * @param {Object} lottie 
 * @returns {string[]}
 */
function extractTags(lottie) {
    const tags = new Set();
    
    // 检查表达式
    const hasExpression = (obj) => {
        if (!obj || typeof obj !== 'object') return false;
        if (obj.x) return true;
        for (const key in obj) {
            if (hasExpression(obj[key])) return true;
        }
        return false;
    };
    if (hasExpression(lottie)) tags.add('expression');

    // 检查遮罩 (Masks)
    const hasMasks = (obj) => {
        if (!obj || typeof obj !== 'object') return false;
        if (Array.isArray(obj.masks) && obj.masks.length > 0) return true;
        for (const key in obj) {
            if (hasMasks(obj[key])) return true;
        }
        return false;
    };
    if (hasMasks(lottie)) tags.add('mask');

    // 检查遮罩层 (Matte)
    const hasMatte = (obj) => {
        if (!obj || typeof obj !== 'object') return false;
        if (obj.tt !== undefined && obj.tt !== 0) return true;
        for (const key in obj) {
            if (hasMatte(obj[key])) return true;
        }
        return false;
    };
    if (hasMatte(lottie)) tags.add('matte');

    // 检查图片资源 (Images)
    if (Array.isArray(lottie.assets) && lottie.assets.some(a => a.p)) {
        tags.add('images');
    }

    return Array.from(tags);
}

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

try {
    const files = fs.readdirSync(samplesDir)
        .filter(file => file.endsWith('.json'))
        .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }))
        .map(file => {
            const filePath = path.join(samplesDir, file);
            let tags = [];
            try {
                const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                tags = extractTags(content);
            } catch (e) {
                console.warn(`Warning: Could not parse ${file} to extract tags.`);
            }
            
            return {
                file: file,
                label: path.basename(file, '.json'),
                source: getSource(file),
                tags: tags
            };
        });

    fs.writeFileSync(outputFile, JSON.stringify(files, null, 2));
    console.log(`Successfully generated ${outputFile} with ${files.length} samples.`);
} catch (err) {
    console.error('Error scanning samples directory:', err.message);
    process.exit(1);
}
