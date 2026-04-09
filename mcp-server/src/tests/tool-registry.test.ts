import { describe, it, expect } from 'vitest';
import { allTools, toolExists } from '../tools/index.js';

describe('Tool registry', () => {
  it('exports a non-empty list of tools', () => {
    expect(allTools.length).toBeGreaterThan(0);
  });

  it('every tool has name, description, and inputSchema', () => {
    for (const tool of allTools) {
      expect(typeof tool.name).toBe('string');
      expect(tool.name.length).toBeGreaterThan(0);
      expect(typeof tool.description).toBe('string');
      expect(tool.description.length).toBeGreaterThan(0);
      expect(tool.inputSchema.type).toBe('object');
      expect(tool.inputSchema.properties).toBeDefined();
    }
  });

  it('tool names are unique', () => {
    const names = allTools.map((t) => t.name);
    expect(new Set(names).size).toBe(names.length);
  });

  it('toolExists returns true for known tools', () => {
    const firstTool = allTools[0].name;
    expect(toolExists(firstTool)).toBe(true);
  });

  it('toolExists returns false for unknown tools', () => {
    expect(toolExists('definitely_not_a_tool_xyz')).toBe(false);
  });
});
