-- Schema for Student Result Processing System (Enterprise Edition)
-- Dialect: PostgreSQL

-- ==========================================
-- 1. Core Tables (Departments, Semesters)
-- ==========================================

CREATE TABLE Departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_code VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE Semesters (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(50) NOT NULL, -- e.g., "Fall 2023"
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT FALSE
);

-- ==========================================
-- 2. People (Students, Faculty)
-- ==========================================

CREATE TABLE Students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    date_of_birth DATE,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    department_id INT REFERENCES Departments(department_id),
    current_cgpa NUMERIC(3, 2) DEFAULT 0.00,
    CONSTRAINT chk_cgpa CHECK (current_cgpa >= 0.00 AND current_cgpa <= 4.00)
);

CREATE TABLE Faculty (
    faculty_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department_id INT REFERENCES Departments(department_id),
    hire_date DATE DEFAULT CURRENT_DATE
);

-- ==========================================
-- 3. Academic Structure (Courses, Assignments)
-- ==========================================

CREATE TABLE Courses (
    course_id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    course_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL CHECK (credits > 0),
    department_id INT REFERENCES Departments(department_id)
);

-- Links Faculty to Courses for a specific Semester
CREATE TABLE Course_Assignments (
    assignment_id SERIAL PRIMARY KEY,
    faculty_id INT REFERENCES Faculty(faculty_id),
    course_id INT REFERENCES Courses(course_id),
    semester_id INT REFERENCES Semesters(semester_id),
    UNIQUE(faculty_id, course_id, semester_id)
);

-- ==========================================
-- 4. Enrollment & Grading
-- ==========================================

CREATE TABLE Enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES Students(student_id) ON DELETE CASCADE,
    course_id INT REFERENCES Courses(course_id),
    semester_id INT REFERENCES Semesters(semester_id),
    total_score NUMERIC(5, 2) DEFAULT 0.00, -- Calculated from assessments (0-100)
    grade_points NUMERIC(3, 2), -- Derived from total_score (0-4.0)
    grade_letter VARCHAR(2),    -- Derived from total_score (A, B, etc.)
    CONSTRAINT chk_grade_points CHECK (grade_points >= 0.00 AND grade_points <= 4.00),
    UNIQUE(student_id, course_id, semester_id)
);

-- ==========================================
-- 5. Assessment System
-- ==========================================

CREATE TABLE Assessment_Types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE -- e.g., 'Quiz', 'Midterm', 'Final', 'Assignment'
);

-- Defines specific assessments for a course in a semester
CREATE TABLE Assessments (
    assessment_id SERIAL PRIMARY KEY,
    course_id INT REFERENCES Courses(course_id),
    semester_id INT REFERENCES Semesters(semester_id),
    type_id INT REFERENCES Assessment_Types(type_id),
    assessment_name VARCHAR(100), -- e.g., "Midterm Exam", "Quiz 1"
    total_marks NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
    weightage_percent NUMERIC(5, 2) NOT NULL CHECK (weightage_percent > 0 AND weightage_percent <= 100),
    UNIQUE(course_id, semester_id, assessment_name)
);

-- Stores the actual marks obtained by a student for an assessment
CREATE TABLE Student_Scores (
    score_id SERIAL PRIMARY KEY,
    enrollment_id INT REFERENCES Enrollments(enrollment_id) ON DELETE CASCADE,
    assessment_id INT REFERENCES Assessments(assessment_id),
    score_obtained NUMERIC(5, 2) DEFAULT 0.00,
    CONSTRAINT chk_score CHECK (score_obtained >= 0),
    UNIQUE(enrollment_id, assessment_id)
);

-- ==========================================
-- 6. Indexes
-- ==========================================

CREATE INDEX idx_students_dept ON Students(department_id);
CREATE INDEX idx_courses_dept ON Courses(department_id);
CREATE INDEX idx_enrollments_student ON Enrollments(student_id);
CREATE INDEX idx_enrollments_course ON Enrollments(course_id);
CREATE INDEX idx_scores_enrollment ON Student_Scores(enrollment_id);
CREATE INDEX idx_assessments_course_sem ON Assessments(course_id, semester_id);
