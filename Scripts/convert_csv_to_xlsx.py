#!/usr/bin/env python3
"""
Convert CSV sample files to XLSX format for Excel import testing.
"""

import csv
import sys
from pathlib import Path

try:
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Alignment
except ImportError:
    print("Error: openpyxl is not installed.")
    print("Please install it with: pip3 install openpyxl")
    sys.exit(1)


def convert_csv_to_xlsx(csv_path: Path, xlsx_path: Path):
    """Convert a CSV file to XLSX format with formatting."""
    
    # Create a new workbook
    wb = Workbook()
    ws = wb.active
    ws.title = "Sheet1"
    
    # Read CSV and write to Excel
    with open(csv_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        
        for row_idx, row in enumerate(reader, start=1):
            for col_idx, value in enumerate(row, start=1):
                cell = ws.cell(row=row_idx, column=col_idx, value=value)
                
                # Format header row
                if row_idx == 1:
                    cell.font = Font(bold=True, size=11)
                    cell.fill = PatternFill(start_color="D3D3D3", end_color="D3D3D3", fill_type="solid")
                    cell.alignment = Alignment(horizontal="left", vertical="center")
    
    # Auto-adjust column widths
    for column in ws.columns:
        max_length = 0
        column_letter = column[0].column_letter
        
        for cell in column:
            try:
                if cell.value:
                    max_length = max(max_length, len(str(cell.value)))
            except:
                pass
        
        adjusted_width = min(max_length + 2, 50)  # Cap at 50 characters
        ws.column_dimensions[column_letter].width = adjusted_width
    
    # Save the workbook
    wb.save(xlsx_path)
    print(f"✅ Created: {xlsx_path.name}")


def main():
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    resources_dir = project_root / "I Do Blueprint" / "Resources"
    
    # Define file paths
    guest_csv = resources_dir / "SampleGuestList.csv"
    guest_xlsx = resources_dir / "SampleGuestList.xlsx"
    
    vendor_csv = resources_dir / "SampleVendorList.csv"
    vendor_xlsx = resources_dir / "SampleVendorList.xlsx"
    
    # Check if CSV files exist
    if not guest_csv.exists():
        print(f"❌ Error: {guest_csv} not found")
        sys.exit(1)
    
    if not vendor_csv.exists():
        print(f"❌ Error: {vendor_csv} not found")
        sys.exit(1)
    
    print("Converting CSV files to XLSX format...\n")
    
    # Convert guest list
    convert_csv_to_xlsx(guest_csv, guest_xlsx)
    
    # Convert vendor list
    convert_csv_to_xlsx(vendor_csv, vendor_xlsx)
    
    print("\n✅ Conversion complete!")
    print(f"\nCreated files:")
    print(f"  - {guest_xlsx}")
    print(f"  - {vendor_xlsx}")


if __name__ == "__main__":
    main()
