const fs = require('fs');
const path = require('path');

const samplesDir = path.join(__dirname, '../samples');
const outputDir = path.join(__dirname, '../demo');
const outputFile = path.join(outputDir, 'list.json');

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

try {
    const files = fs.readdirSync(samplesDir)
        .filter(file => file.endsWith('.json'))
        .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }))
        .map(file => ({
            file: file,
            label: path.basename(file, '.json')
        }));

    fs.writeFileSync(outputFile, JSON.stringify(files, null, 2));
    console.log(`Successfully generated ${outputFile} with ${files.length} samples.`);
} catch (err) {
    console.error('Error scanning samples directory:', err.message);
    process.exit(1);
}
