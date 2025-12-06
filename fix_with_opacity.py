#!/usr/bin/env python3
"""
Script to automatically fix deprecated withOpacity() calls in Dart files.
Replaces: .withOpacity(value) with .withValues(alpha: value)
"""

import re
import os
from pathlib import Path

def fix_with_opacity_in_file(filepath):
    """Fix withOpacity deprecations in a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Pattern to match .withOpacity(number)
        pattern = r'\.withOpacity\((\d+(?:\.\d+)?)\)'
        replacement = r'.withValues(alpha: \1)'
        
        new_content = re.sub(pattern, replacement, content)
        
        if content != new_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    # Directory to process
    lib_dir = Path('e:/projet_services/frontend/lib')
    
    # Find all Dart files
    dart_files = list(lib_dir.rglob('*.dart'))
    
    fixed_count = 0
    total_count = len(dart_files)
    
    print(f"Found {total_count} Dart files to process...")
    
    for dart_file in dart_files:
        if fix_with_opacity_in_file(dart_file):
            fixed_count += 1
            print(f"Fixed: {dart_file.relative_to(lib_dir)}")
    
    print(f"\nCompleted! Fixed {fixed_count} files out of {total_count}")

if __name__ == '__main__':
    main()
