#!/usr/bin/env python3
"""
SAM Header Editor Module

Contains the SAMHeaderEditor class for reading, editing, and writing SAM file headers.
"""

import sys
import re
from typing import List, Dict, Optional


class SAMHeaderEditor:
    def __init__(self):
        self.header_records = []
    
    def read_header(self, filename: str) -> None:
        """Read SAM header from file"""
        try:
            with open(filename, 'r') as f:
                self.header_records = []
                for line in f:
                    line = line.strip()
                    if line.startswith('@'):
                        self.header_records.append(self._parse_header_line(line))
        except FileNotFoundError:
            print(f"Error: {filename} not found")
            sys.exit(1)
    
    def _parse_header_line(self, line: str) -> Dict[str, str]:
        """Parse a SAM header line into a dictionary"""
        fields = line.split('\t')
        record = {"RECORD": fields[0][1:]}  # Remove @ prefix
        
        for field in fields[1:]:
            if ':' in field:
                tag, value = field.split(':', 1)  # Split on first colon only
                record[tag] = value
        
        return record
    
    def _format_header_line(self, record: Dict[str, str]) -> str:
        """Format a dictionary back into a SAM header line"""
        line_parts = [f"@{record['RECORD']}"]
        
        for key, value in record.items():
            if key != 'RECORD':
                line_parts.append(f"{key}:{value}")
        
        return '\t'.join(line_parts)
    
    def write_header(self, filename: str) -> None:
        """Write edited SAM header to file"""
        with open(filename, 'w') as f:
            for record in self.header_records:
                f.write(self._format_header_line(record) + '\n')
    
    def add_header_line(self, line: str) -> None:
        """Add a new header line"""
        if not line.startswith('@'):
            line = '@' + line
        self.header_records.append(self._parse_header_line(line))
    
    def remove_header_line(self, pattern: str) -> int:
        """Remove header lines matching pattern. Returns count of removed lines."""
        original_count = len(self.header_records)
        self.header_records = [record for record in self.header_records 
                              if not re.search(pattern, self._format_header_line(record))]
        return original_count - len(self.header_records)
    
    def replace_in_header(self, pattern: str, replacement: str) -> int:
        """Replace text in header lines. Returns count of modifications."""
        count = 0
        for i, record in enumerate(self.header_records):
            line = self._format_header_line(record)
            new_line = re.sub(pattern, replacement, line)
            if new_line != line:
                self.header_records[i] = self._parse_header_line(new_line)
                count += 1
        return count
    
    def update_field(self, record_type: str, tag: str, new_value: str) -> int:
        """Update specific field in header records. Returns count of modifications."""
        count = 0
        
        for record in self.header_records:
            if record.get('RECORD') == record_type:
                record[tag] = new_value
                count += 1
        
        return count
    
    def get_header_summary(self) -> Dict[str, int]:
        """Get summary of header record types"""
        summary = {}
        for record in self.header_records:
            record_type = record.get('RECORD', '')
            if record_type:
                summary[record_type] = summary.get(record_type, 0) + 1
        return summary
    
    def get_field_values(self, record_type: str, tag: str) -> List[str]:
        """Get all values for a specific tag in records of given type. Returns list of values."""
        values = []
        
        for record in self.header_records:
            if record.get('RECORD') == record_type and tag in record:
                values.append(record[tag])
        
        return values
    
    def dedup_pg_by_cl(self) -> int:
        """Remove duplicate @PG records with identical CL tags. Returns count of removed duplicates."""
        pg_records = []
        other_records = []
        seen_cl_tags = set()
        removed_count = 0
        
        for record in self.header_records:
            if record.get('RECORD') == 'PG':
                cl_value = record.get('CL', '')
                if cl_value and cl_value in seen_cl_tags:
                    removed_count += 1
                else:
                    if cl_value:
                        seen_cl_tags.add(cl_value)
                    pg_records.append(record)
            else:
                other_records.append(record)
        
        self.header_records = other_records + pg_records
        return removed_count
    
    def print_header(self) -> None:
        """Print current header to stdout"""
        for record in self.header_records:
            print(self._format_header_line(record))