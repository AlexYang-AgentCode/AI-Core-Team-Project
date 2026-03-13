/**
 * Resource Converter POC
 * 将Android资源文件(XML)转换为HarmonyOS资源文件(JSON)
 * 
 * Android资源目录: res/values/
 *   - strings.xml
 *   - colors.xml
 *   - styles.xml
 *   - dimens.xml
 * 
 * HarmonyOS资源目录: resources/base/element/
 *   - string.json
 *   - color.json
 *   - float.json (for dimens)
 */

const fs = require('fs');
const path = require('path');

// ============================================
// Android XML解析器 (简化版)
// ============================================

class AndroidXmlParser {
  /**
   * 解析简单的Android values XML
   * 支持格式: <type name="key">value</type>
   */
  static parse(xmlContent) {
    const results = [];
    
    // 移除注释和空白
    const cleaned = xmlContent
      .replace(/<!--[\s\S]*?-->/g, '')
      .replace(/^\s*[\r\n]/gm, '');
    
    // 匹配 <tag name="key">value</tag>
    const regex = /<([\w-]+)\s+name="([^"]+)"(?:\s+type="([^"]+)")?\s*>([^<]*)<\/\1>/g;
    let match;
    
    while ((match = regex.exec(cleaned)) !== null) {
      const [, tag, name, type, value] = match;
      results.push({
        name,
        value: value.trim(),
        type: type || tag
      });
    }
    
    return results;
  }
}

// ============================================
// HarmonyOS JSON生成器
// ============================================

class HarmonyOSJsonGenerator {
  /**
   * 生成string.json
   */
  static generateStringJson(items) {
    const json = {
      string: items.map(item => ({
        name: item.name,
        value: item.value
      }))
    };
    return JSON.stringify(json, null, 2);
  }
  
  /**
   * 生成color.json
   */
  static generateColorJson(items) {
    const json = {
      color: items.map(item => ({
        name: item.name,
        value: item.value
      }))
    };
    return JSON.stringify(json, null, 2);
  }
  
  /**
   * 生成float.json (用于dimens)
   */
  static generateFloatJson(items) {
    const json = {
      float: items.map(item => {
        // 解析尺寸单位 (dp, sp, px)
        const match = item.value.match(/^([\d.]+)(dp|sp|px)?$/);
        if (match) {
          const [, num, unit] = match;
          return {
            name: item.name,
            value: `${num}${unit || 'px'}`
          };
        }
        return {
          name: item.name,
          value: item.value
        };
      })
    };
    return JSON.stringify(json, null, 2);
  }
}

// ============================================
// ResourceConverter主类
// ============================================

class ResourceConverter {
  constructor(inputDir, outputDir) {
    this.inputDir = inputDir;
    this.outputDir = outputDir;
  }
  
  /**
   * 转换所有资源文件
   */
  convert() {
    console.log(`转换资源文件:\n  输入: ${this.inputDir}\n  输出: ${this.outputDir}\n`);
    
    // 确保输出目录存在
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }
    
    // 转换strings.xml
    this.convertStrings();
    
    // 转换colors.xml
    this.convertColors();
    
    // 转换dimens.xml (如果存在)
    this.convertDimens();
    
    console.log('\n资源转换完成!');
  }
  
  /**
   * 转换strings.xml → string.json
   */
  convertStrings() {
    const inputFile = path.join(this.inputDir, 'strings.xml');
    const outputFile = path.join(this.outputDir, 'string.json');
    
    if (!fs.existsSync(inputFile)) {
      console.log('⚠ strings.xml 不存在, 跳过');
      return;
    }
    
    console.log('转换 strings.xml → string.json');
    
    const xmlContent = fs.readFileSync(inputFile, 'utf-8');
    const items = AndroidXmlParser.parse(xmlContent);
    
    const jsonContent = HarmonyOSJsonGenerator.generateStringJson(items);
    fs.writeFileSync(outputFile, jsonContent);
    
    console.log(`  ✓ 转换完成: ${items.length} 个字符串`);
  }
  
  /**
   * 转换colors.xml → color.json
   */
  convertColors() {
    const inputFile = path.join(this.inputDir, 'colors.xml');
    const outputFile = path.join(this.outputDir, 'color.json');
    
    if (!fs.existsSync(inputFile)) {
      console.log('⚠ colors.xml 不存在, 跳过');
      return;
    }
    
    console.log('转换 colors.xml → color.json');
    
    const xmlContent = fs.readFileSync(inputFile, 'utf-8');
    const items = AndroidXmlParser.parse(xmlContent);
    
    const jsonContent = HarmonyOSJsonGenerator.generateColorJson(items);
    fs.writeFileSync(outputFile, jsonContent);
    
    console.log(`  ✓ 转换完成: ${items.length} 个颜色`);
  }
  
  /**
   * 转换dimens.xml → float.json
   */
  convertDimens() {
    const inputFile = path.join(this.inputDir, 'dimens.xml');
    const outputFile = path.join(this.outputDir, 'float.json');
    
    if (!fs.existsSync(inputFile)) {
      console.log('⚠ dimens.xml 不存在, 跳过');
      return;
    }
    
    console.log('转换 dimens.xml → float.json');
    
    const xmlContent = fs.readFileSync(inputFile, 'utf-8');
    const items = AndroidXmlParser.parse(xmlContent);
    
    const jsonContent = HarmonyOSJsonGenerator.generateFloatJson(items);
    fs.writeFileSync(outputFile, jsonContent);
    
    console.log(`  ✓ 转换完成: ${items.length} 个尺寸`);
  }
}

// ============================================
// POC测试
// ============================================

console.log("=== Resource Converter POC测试 ===\n");

// 模拟Android资源文件
const sampleStringsXml = `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Simple Calculator</string>
    <string name="action_settings">Settings</string>
    <string name="hello_world">Hello World!</string>
</resources>`;

const sampleColorsXml = `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="colorPrimary">#3F51B5</color>
    <color name="colorPrimaryDark">#303F9F</color>
    <color name="colorAccent">#FF4081</color>
    <color name="textColorPrimary">#212121</color>
</resources>`;

const sampleDimensXml = `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <dimen name="activity_horizontal_margin">16dp</dimen>
    <dimen name="activity_vertical_margin">16dp</dimen>
    <dimen name="button_text_size">20sp</dimen>
</resources>`;

// 创建临时测试目录
const testInputDir = './test-resources/android/values';
const testOutputDir = './test-resources/harmony/element';

console.log("创建测试资源文件...\n");

// 创建目录
if (!fs.existsSync(testInputDir)) {
  fs.mkdirSync(testInputDir, { recursive: true });
}

// 写入测试文件
fs.writeFileSync(path.join(testInputDir, 'strings.xml'), sampleStringsXml);
fs.writeFileSync(path.join(testInputDir, 'colors.xml'), sampleColorsXml);
fs.writeFileSync(path.join(testInputDir, 'dimens.xml'), sampleDimensXml);

console.log("测试文件已创建:");
console.log(`  - ${testInputDir}/strings.xml`);
console.log(`  - ${testInputDir}/colors.xml`);
console.log(`  - ${testInputDir}/dimens.xml\n`);

// 执行转换
const converter = new ResourceConverter(testInputDir, testOutputDir);
converter.convert();

// 显示转换结果
console.log("\n转换结果:");

const stringJsonPath = path.join(testOutputDir, 'string.json');
if (fs.existsSync(stringJsonPath)) {
  console.log(`\n--- string.json ---`);
  console.log(fs.readFileSync(stringJsonPath, 'utf-8'));
}

const colorJsonPath = path.join(testOutputDir, 'color.json');
if (fs.existsSync(colorJsonPath)) {
  console.log(`\n--- color.json ---`);
  console.log(fs.readFileSync(colorJsonPath, 'utf-8'));
}

const floatJsonPath = path.join(testOutputDir, 'float.json');
if (fs.existsSync(floatJsonPath)) {
  console.log(`\n--- float.json ---`);
  console.log(fs.readFileSync(floatJsonPath, 'utf-8'));
}

// 清理测试文件
console.log("\n清理测试文件...");
try {
  fs.rmSync('./test-resources', { recursive: true });
  console.log("✓ 测试完成");
} catch (e) {
  console.log("⚠ 清理失败 (不影响测试结果)");
}

console.log("\n=== POC测试完成 ===");

/**
 * 在鸿蒙项目中的使用方式:
 * 
 * 1. 编译时运行转换:
 *    node resource-converter.js \
 *      --input ./android/app/src/main/res/values \
 *      --output ./harmony/entry/src/main/resources/base/element
 * 
 * 2. 在ArkTS代码中使用转换后的资源:
 *    // Android: getString(R.string.app_name)
 *    // HarmonyOS:
 *    $r('app.string.app_name')
 */
