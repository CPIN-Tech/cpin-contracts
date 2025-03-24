/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-explicit-any */
import fs from 'fs';
import path from 'path';

function processJsonFile(inputFilePath: string, outputFilePath: string) {
  // Validate input file path
  if (!inputFilePath) {
    console.error('Error: Input file path is required');
    return;
  }

  try {
    // Read the JSON file
    console.log(`Reading file: ${inputFilePath}`);
    const data = fs.readFileSync(inputFilePath, 'utf8');

    // Parse the JSON data
    const jsonData = JSON.parse(data);
    console.log('Successfully parsed JSON data');

    // Generate output file path if not provided
    if (!outputFilePath) {
      const parsedPath = path.parse(inputFilePath);
      outputFilePath = path.join(parsedPath.dir, `${parsedPath.name}_solinput${parsedPath.ext}`);
    }

    const solinput = JSON.parse(jsonData.metadata);

    // Write the JSON data to the output file
    fs.writeFileSync(outputFilePath, JSON.stringify(solinput, null, 2));
    console.log(`Successfully saved to: ${outputFilePath}`);
  } catch (error: any) {
    if (error.code === 'ENOENT') {
      console.error(`Error: File not found - ${inputFilePath}`);
    } else if (error instanceof SyntaxError) {
      console.error(`Error: Invalid JSON format in ${inputFilePath}`);
    } else {
      console.error(`Error processing file: ${error.message}`);
    }
  }
}

if (process.argv.length < 3) {
  console.log('Usage: yarn solinput <inputFilePath> [outputFilePath]');
} else {
  const inputFilePath = process.argv[2];
  const outputFilePath = process.argv[3]; // Optional
  processJsonFile(inputFilePath, outputFilePath);
}
