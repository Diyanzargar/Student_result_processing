-- Queries and Analysis for Student Result Processing System (Enterprise Edition)

-- 1. Student Transcript with Assessment Breakdown
-- Shows detailed scores for a specific student in a specific course
SELECT
    s.first_name,
    s.last_name,
    c.course_code,
    c.course_name,
    a.assessment_name,
    a.total_marks,
    a.weightage_percent,
    ss.score_obtained,
    ROUND((ss.score_obtained / a.total_marks) * a.weightage_percent, 2) AS weighted_score
FROM
    Student_Scores ss
JOIN
    Assessments a ON ss.assessment_id = a.assessment_id
JOIN
    Enrollments e ON ss.enrollment_id = e.enrollment_id
JOIN
    Students s ON e.student_id = s.student_id
JOIN
    Courses c ON e.course_id = c.course_id
WHERE
    s.student_id = 1 -- Example Student
    AND c.course_code = 'CS101';

-- 2. Course Performance Summary (Faculty View)
-- Shows average scores per assessment for a course taught by a faculty member
SELECT
    f.last_name AS faculty_name,
    c.course_code,
    sem.semester_name,
    a.assessment_name,
    ROUND(AVG(ss.score_obtained), 2) AS avg_score,
    MIN(ss.score_obtained) AS min_score,
    MAX(ss.score_obtained) AS max_score
FROM
    Course_Assignments ca
JOIN
    Faculty f ON ca.faculty_id = f.faculty_id
JOIN
    Courses c ON ca.course_id = c.course_id
JOIN
    Semesters sem ON ca.semester_id = sem.semester_id
JOIN
    Assessments a ON c.course_id = a.course_id AND sem.semester_id = a.semester_id
JOIN
    Student_Scores ss ON a.assessment_id = ss.assessment_id
GROUP BY
    f.last_name, c.course_code, sem.semester_name, a.assessment_name
ORDER BY
    c.course_code, a.assessment_name;

-- 3. Department Toppers (Rank List)
-- Uses DENSE_RANK to find the top student in each department based on CGPA
SELECT * FROM (
    SELECT
        s.student_id,
        s.first_name,
        s.last_name,
        d.department_name,
        s.current_cgpa,
        DENSE_RANK() OVER (PARTITION BY s.department_id ORDER BY s.current_cgpa DESC) AS dept_rank
    FROM
        Students s
    JOIN
        Departments d ON s.department_id = d.department_id
) ranked
WHERE dept_rank <= 3; -- Top 3 per department

-- 4. Semester Result Summary View
CREATE OR REPLACE VIEW v_semester_result_summary AS
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    d.department_code,
    sem.semester_name,
    COUNT(e.course_id) AS courses_taken,
    SUM(c.credits) AS total_credits,
    ROUND(SUM(e.grade_points * c.credits) / SUM(c.credits), 2) AS sgpa,
    s.current_cgpa
FROM
    Enrollments e
JOIN
    Students s ON e.student_id = s.student_id
JOIN
    Courses c ON e.course_id = c.course_id
JOIN
    Semesters sem ON e.semester_id = sem.semester_id
JOIN
    Departments d ON s.department_id = d.department_id
GROUP BY
    s.student_id, s.first_name, s.last_name, d.department_code, sem.semester_id, sem.semester_name, s.current_cgpa;
