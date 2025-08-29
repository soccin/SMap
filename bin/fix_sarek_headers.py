#!/usr/bin/env python3
"""
Sarek SAM Header Fixer

Applies specific fixes for Sarek-generated SAM headers:
1. Removes duplicate @PG records with identical CL tags
2. Swaps SM and LB tags in @RG records
"""

import sys
from sam_header_editor import SAMHeaderEditor


def swap_rg_sm_lb(editor: SAMHeaderEditor) -> int:
    """Swap SM and LB tags in @RG records. Returns count of swapped records."""
    count = 0
    
    for record in editor.header_records:
        if record.get('RECORD') == 'RG':
            sm_value = record.get('SM')
            lb_value = record.get('LB')
            
            if sm_value is not None or lb_value is not None:
                # Swap the values (handle cases where one might be missing)
                if sm_value is not None:
                    record['LB'] = sm_value
                elif 'LB' in record:
                    del record['LB']
                
                if lb_value is not None:
                    record['SM'] = lb_value
                elif 'SM' in record:
                    del record['SM']
                
                count += 1
    
    return count


def main():
    if len(sys.argv) != 2:
        print("Usage: fix_sarek_headers.py input.sam")
        print("Fixes Sarek SAM headers by:")
        print("  1. Removing duplicate @PG records with identical CL tags")
        print("  2. Swapping SM and LB tags in @RG records")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Generate output filename
    if input_file.endswith('.sam'):
        output_file = input_file[:-4] + '.headfix.sam'
    else:
        output_file = input_file + '.headfix.sam'
    
    # Load and process the header
    editor = SAMHeaderEditor()
    editor.read_header(input_file)
    
    print(f"Loaded {len(editor.header_records)} header records from {input_file}")
    
    # Apply fixes
    pg_removed = editor.dedup_pg_by_cl()
    print(f"Removed {pg_removed} duplicate @PG records with identical CL tags")
    
    rg_swapped = swap_rg_sm_lb(editor)
    print(f"Swapped SM/LB tags in {rg_swapped} @RG records")
    
    # Write the fixed header
    editor.write_header(output_file)
    print(f"Fixed header written to {output_file}")


if __name__ == "__main__":
    main()