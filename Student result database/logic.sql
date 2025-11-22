-- Logic for Student Result Processing System (Enterprise Edition)
-- Contains Functions and Triggers for automated Grading and CGPA calculation

-- ==========================================
-- 1. Helper Function: Calculate Grade from Score
-- ==========================================
-- Converts a numerical score (0-100) to Grade Points and Letter Grade
CREATE OR REPLACE FUNCTION get_grade_details(p_score NUMERIC, OUT p_grade_points NUMERIC, OUT p_grade_letter VARCHAR)
AS $$
BEGIN
    IF p_score >= 93 THEN
        p_grade_points := 4.00; p_grade_letter := 'A';
    ELSIF p_score >= 90 THEN
        p_grade_points := 3.70; p_grade_letter := 'A-';
    ELSIF p_score >= 87 THEN
        p_grade_points := 3.30; p_grade_letter := 'B+';
    ELSIF p_score >= 83 THEN
        p_grade_points := 3.00; p_grade_letter := 'B';
    ELSIF p_score >= 80 THEN
        p_grade_points := 2.70; p_grade_letter := 'B-';
    ELSIF p_score >= 77 THEN
        p_grade_points := 2.30; p_grade_letter := 'C+';
    ELSIF p_score >= 73 THEN
        p_grade_points := 2.00; p_grade_letter := 'C';
    ELSIF p_score >= 70 THEN
        p_grade_points := 1.70; p_grade_letter := 'C-';
    ELSIF p_score >= 60 THEN
        p_grade_points := 1.00; p_grade_letter := 'D';
    ELSE
        p_grade_points := 0.00; p_grade_letter := 'F';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- 2. Trigger: Calculate Enrollment Score
-- ==========================================
-- Trigger on Student_Scores
-- When a score is added/modified, recalculate the total score for the enrollment
CREATE OR REPLACE FUNCTION update_enrollment_score_func()
RETURNS TRIGGER AS $$
DECLARE
    v_enrollment_id INT;
    v_total_weighted_score NUMERIC := 0;
    v_grade_points NUMERIC;
    v_grade_letter VARCHAR;
BEGIN
    -- Determine enrollment_id
    IF (TG_OP = 'DELETE') THEN
        v_enrollment_id := OLD.enrollment_id;
    ELSE
        v_enrollment_id := NEW.enrollment_id;
    END IF;

    -- Calculate total weighted score
    -- Sum of (ScoreObtained / TotalMarks) * Weightage
    SELECT
        COALESCE(SUM((s.score_obtained / a.total_marks) * a.weightage_percent), 0)
    INTO
        v_total_weighted_score
    FROM
        Student_Scores s
    JOIN
        Assessments a ON s.assessment_id = a.assessment_id
    WHERE
        s.enrollment_id = v_enrollment_id;

    -- Get Grade Points and Letter
    SELECT * FROM get_grade_details(v_total_weighted_score) INTO v_grade_points, v_grade_letter;

    -- Update Enrollment
    UPDATE Enrollments
    SET
        total_score = v_total_weighted_score,
        grade_points = v_grade_points,
        grade_letter = v_grade_letter
    WHERE
        enrollment_id = v_enrollment_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_enrollment_score_trigger
AFTER INSERT OR UPDATE OR DELETE ON Student_Scores
FOR EACH ROW
EXECUTE FUNCTION update_enrollment_score_func();

-- ==========================================
-- 3. Trigger: Update CGPA (Cascading)
-- ==========================================
-- Trigger on Enrollments (Fires when grade_points is updated by the trigger above)
-- Calculates the CGPA for a given student
CREATE OR REPLACE FUNCTION calculate_cgpa(p_student_id INT)
RETURNS NUMERIC AS $$
DECLARE
    total_points NUMERIC := 0;
    total_credits INT := 0;
    new_cgpa NUMERIC := 0.00;
BEGIN
    SELECT
        COALESCE(SUM(e.grade_points * c.credits), 0),
        COALESCE(SUM(c.credits), 0)
    INTO
        total_points,
        total_credits
    FROM
        Enrollments e
    JOIN
        Courses c ON e.course_id = c.course_id
    WHERE
        e.student_id = p_student_id
        AND e.grade_points IS NOT NULL;

    IF total_credits > 0 THEN
        new_cgpa := ROUND(total_points / total_credits, 2);
    ELSE
        new_cgpa := 0.00;
    END IF;

    RETURN new_cgpa;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_cgpa_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    affected_student_id INT;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        affected_student_id := OLD.student_id;
    ELSE
        affected_student_id := NEW.student_id;
    END IF;

    UPDATE Students
    SET current_cgpa = calculate_cgpa(affected_student_id)
    WHERE student_id = affected_student_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_cgpa_after_grade_change
AFTER INSERT OR UPDATE OR DELETE ON Enrollments
FOR EACH ROW
EXECUTE FUNCTION update_cgpa_trigger_func();
