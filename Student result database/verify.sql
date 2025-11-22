-- Verification Script (Enterprise Edition)

-- 1. Verify Data Counts
SELECT 'Students' as table, COUNT(*) FROM Students UNION ALL
SELECT 'Faculty', COUNT(*) FROM Faculty UNION ALL
SELECT 'Courses', COUNT(*) FROM Courses UNION ALL
SELECT 'Enrollments', COUNT(*) FROM Enrollments UNION ALL
SELECT 'Student_Scores', COUNT(*) FROM Student_Scores;

-- 2. Verify Grading Logic (The "Magic" Test)
-- Pick a random enrollment
SELECT * FROM Enrollments LIMIT 1;
-- Let's say enrollment_id = 1. Check its current score.

-- Insert a new score for this enrollment (e.g., a Bonus Assignment)
-- First, create a dummy assessment for this course if needed, or just pick an existing one.
-- For verification, let's just update an existing score and see if Grade changes.

SELECT e.enrollment_id, e.total_score, e.grade_letter, s.current_cgpa
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
WHERE e.enrollment_id = 1;

-- Update a score (Give them 100 on an assessment)
UPDATE Student_Scores
SET score_obtained = 100
WHERE enrollment_id = 1
AND score_id = (SELECT score_id FROM Student_Scores WHERE enrollment_id = 1 LIMIT 1);

-- Check if Enrollment Total Score and Grade updated automatically
SELECT e.enrollment_id, e.total_score, e.grade_letter, s.current_cgpa
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
WHERE e.enrollment_id = 1;

-- 3. Verify Faculty Assignments
SELECT f.last_name, c.course_code, sem.semester_name
FROM Course_Assignments ca
JOIN Faculty f ON ca.faculty_id = f.faculty_id
JOIN Courses c ON ca.course_id = c.course_id
JOIN Semesters sem ON ca.semester_id = sem.semester_id
LIMIT 5;
