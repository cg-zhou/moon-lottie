import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const currentDir = path.dirname(fileURLToPath(import.meta.url));

function getSource(filename) {
    if (filename.startsWith("1_")) return "LottieFiles";
    if (filename.startsWith("2_")) return "Lottie-Web Standard";
    if (filename.startsWith("3_")) return "Lottie-Web Expressions";
    if (filename.startsWith("4_")) return "Lottie-iOS Samples";
    return "Unknown";
}

function extractTags(lottie) {
    const tags = new Set();

    const hasExpression = (obj) => {
        if (!obj || typeof obj !== "object") return false;
        if (obj.x) return true;
        for (const key in obj) {
            if (hasExpression(obj[key])) return true;
        }
        return false;
    };
    if (hasExpression(lottie)) tags.add("expression");

    const hasMasks = (obj) => {
        if (!obj || typeof obj !== "object") return false;
        if (Array.isArray(obj.masks) && obj.masks.length > 0) return true;
        for (const key in obj) {
            if (hasMasks(obj[key])) return true;
        }
        return false;
    };
    if (hasMasks(lottie)) tags.add("mask");

    const hasMatte = (obj) => {
        if (!obj || typeof obj !== "object") return false;
        if (obj.tt !== undefined && obj.tt !== 0) return true;
        for (const key in obj) {
            if (hasMatte(obj[key])) return true;
        }
        return false;
    };
    if (hasMatte(lottie)) tags.add("matte");

    if (Array.isArray(lottie.assets) && lottie.assets.some((asset) => asset.p)) {
        tags.add("images");
    }

    return Array.from(tags);
}

export function generateSampleIndex({
    samplesDir = path.join(currentDir, "..", "samples"),
    outputDir = path.join(currentDir, "..", "demo", "public"),
} = {}) {
    const outputFile = path.join(outputDir, "sample_index.json");

    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    const files = fs.readdirSync(samplesDir)
        .filter((file) => file.endsWith(".json"))
        .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: "base" }))
        .map((file) => {
            const filePath = path.join(samplesDir, file);
            let tags = [];
            try {
                const content = JSON.parse(fs.readFileSync(filePath, "utf8"));
                tags = extractTags(content);
            } catch {
                console.warn(`Warning: Could not parse ${file} to extract tags.`);
            }

            return {
                file,
                label: path.basename(file, ".json"),
                source: getSource(file),
                tags,
            };
        });

    fs.writeFileSync(outputFile, JSON.stringify(files, null, 2));
    return { outputFile, count: files.length };
}

const isDirectExecution = process.argv[1]
    ? pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url
    : false;

if (isDirectExecution) {
    try {
        const { outputFile, count } = generateSampleIndex();
        console.log(`Successfully generated ${outputFile} with ${count} samples.`);
    } catch (error) {
        console.error("Error scanning samples directory:", error.message);
        process.exit(1);
    }
}
