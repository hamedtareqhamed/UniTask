import requests
import csv
import os

PROJECT_ID = "unitask-mmu"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

CSV_DIR = "/home/hamed/PL/unitask/CSV"

# Clean Keyword Mapping: Code -> Word in filename
CODE_TO_FILE_FRAGMENT = {
    'TSW': 'SEMANTIC WEB',
    'TML': 'MACHINE LEARNING',
    'TWT': 'WEB TECHNIQUES',
    'TSE': 'SOFTWARE ENGINE',
    'THI': 'HUMAN COMPUTER',
    'TCG': 'COMPUTER GRAPHICS',
}

def upload(collection, doc_id, fields):
    url = f"{BASE_URL}/{collection}/{doc_id}"
    body = {"fields": fields}
    resp = requests.patch(url, json=body)
    if resp.ok:
        return True
    else:
        print(f"Fail {doc_id}: {resp.text}")
        return False

def run():
    print("--- STARTING ULTIMATE REMEDIATION INJECTION ---")
    try:
        # Load Sections
        with open(os.path.join(CSV_DIR, 'sec.csv'), 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)

        if len(rows) < 2: return

        seen_codes = set()
        course_count = 0
        section_count = 0
        assessment_count = 0

        for i in range(1, len(rows)):
            row = rows[i]
            if len(row) < 10: continue

            class_name = row[0].strip()
            course_code = row[9].strip().split(',')[0].strip() # Handle 'TSW,,,,,'

            print(f"Uploading Section: {class_name} ({course_code})")
            if upload('ready_made_sections', class_name, {
                'courseCode': {'stringValue': course_code},
                'lecTime': {'stringValue': row[1]},
                'labTime': {'stringValue': row[2]},
                'credits': {'integerValue': str(int(row[3])) if row[3].isdigit() else "3"},
                'lecRoom': {'stringValue': row[5]},
                'labRoom': {'stringValue': row[6]},
                'instructor': {'stringValue': row[7]},
                'courseworkWeight': {'doubleValue': float(row[8]) if row[8].replace('.', '', 1).isdigit() else 60.0}
            }):
                section_count += 1

            # Template
            if course_code not in seen_codes:
                frag = CODE_TO_FILE_FRAGMENT.get(course_code)
                if frag:
                    for f_name in os.listdir(CSV_DIR):
                        if frag.upper() in f_name.upper():
                            print(f"--- Adding Course: {course_code} (from {f_name}) ---")
                            c_info = upload_course_full(course_code, f_name)
                            if c_info:
                                course_count += 1
                                assessment_count += c_info
                                seen_codes.add(course_code)
                            break
    
        print(f"\n--- SUCCESS SUMMARY ---")
        print(f"Courses: {course_count}")
        print(f"Sections: {section_count}")
        print(f"Assessments: {assessment_count}")
        print(f"--- REMEDIATION COMPLETE ---")
                                
    except Exception as e:
        print(f"Remediation failed: {e}")

def upload_course_full(code, disk_file_name):
    # Course Doc
    try:
        with open(os.path.join(CSV_DIR, disk_file_name), 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)
        if len(rows) < 4: return 0

        upload('ready_made_courses', code, {
            'name': {'stringValue': rows[0][1]},
            'professor': {'stringValue': rows[1][1]},
            'credits': {'integerValue': str(int(rows[2][1])) if rows[2][1].isdigit() else "3"},
            'courseworkWeight': {'doubleValue': float(rows[3][1].replace('%', '')) if rows[3][1].replace('%', '').replace('.', '', 1).isdigit() else 60.0}
        })
        
        # Assessments
        a_uploaded = 0
        table_start = -1
        for i, row in enumerate(rows):
            if row and 'ID' in row[0]: # "ID" header
                table_start = i + 1
                break
        
        if table_start != -1:
            for i in range(table_start, len(rows)):
                row = rows[i]
                if len(row) < 9: continue
                if upload(f'ready_made_courses/{code}/assessments', str(i), {
                    'title': {'stringValue': row[1]},
                    'type': {'stringValue': row[2]},
                    'category': {'stringValue': row[3]},
                    'maxScore': {'doubleValue': float(row[5]) if row[5].replace('.', '', 1).isdigit() else 10.0},
                    'weight': {'doubleValue': float(row[6]) if row[6].replace('.', '', 1).isdigit() else 10.0},
                    'deadline': {'stringValue': row[7]},
                    'isCompleted': {'booleanValue': row[8].strip().lower().startswith('yes')}
                }):
                    a_uploaded += 1
        return a_uploaded
    except Exception as e:
        print(f"Err {disk_file_name}: {e}")
        return 0

if __name__ == "__main__":
    run()
