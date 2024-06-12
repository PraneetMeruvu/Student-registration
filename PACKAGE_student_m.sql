CREATE OR REPLACE PACKAGE student_mngt
IS
    PROCEDURE ListStudentsInClass(classid_param IN CHAR);
    PROCEDURE GetPrerequisites(dept_code_param IN VARCHAR2, course#_param IN NUMBER);
    PROCEDURE GetIndirectPrerequisites(ipre_dept_code IN VARCHAR2, ipre_course# IN NUMBER);
    PROCEDURE EnrollStudentIntoClass(g_B#_param IN CHAR, classid_param IN CHAR);
    PROCEDURE DropStudentFromClass(g_B#_param IN CHAR,classid_param IN CHAR); 
    PROCEDURE DeleteStudent(B#_param IN CHAR);
END student_mngt;
/

CREATE OR REPLACE PROCEDURE SHOW_STUDENTS
IS
    CURSOR student_cursor IS
        SELECT B#, first_name, last_name, st_level, gpa, email, bdate
        FROM students;
    student_record student_cursor%ROWTYPE;
BEGIN
  
    OPEN student_cursor;

    LOOP
        FETCH student_cursor INTO student_record;
        EXIT WHEN student_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Student ID: ' || student_record.B#);
        DBMS_OUTPUT.PUT_LINE('First Name: ' || student_record.first_name);
        DBMS_OUTPUT.PUT_LINE('Last Name: ' || student_record.last_name);
        DBMS_OUTPUT.PUT_LINE('Student Level: ' || student_record.st_level);
        DBMS_OUTPUT.PUT_LINE('GPA: ' || student_record.gpa);
        DBMS_OUTPUT.PUT_LINE('Email: ' || student_record.email);
        DBMS_OUTPUT.PUT_LINE('Birth Date: ' || student_record.bdate);
        DBMS_OUTPUT.PUT_LINE('----------------------------');
    END LOOP;

    CLOSE student_cursor;
END;
/

CREATE OR REPLACE PROCEDURE ListStudentsInClass(classid_param IN CHAR) IS
  v_class_exists NUMBER;
BEGIN
  -- if classid exists
  SELECT COUNT(*) INTO v_class_exists
  FROM classes
  WHERE classid = classid_param;
  
  IF v_class_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('The classid is invalid.');
  ELSE

    FOR student_record IN (
      SELECT s.B#, s.first_name, s.last_name
      FROM students s
      JOIN g_enrollments g ON s.B# = g.g_B#
      WHERE g.classid = classid_param
    )
    LOOP
      DBMS_OUTPUT.PUT_LINE('Student ID: ' || student_record.B#);
      DBMS_OUTPUT.PUT_LINE('First Name: ' || student_record.first_name);
      DBMS_OUTPUT.PUT_LINE('Last Name: ' || student_record.last_name);
      DBMS_OUTPUT.PUT_LINE('----------------------------');
    END LOOP;
  END IF;
END ListStudentsInClass;
/


CREATE OR REPLACE PROCEDURE ListStudentsInClass(classid_param IN CHAR) IS
  v_class_exists NUMBER;
BEGIN
  -- if classid exists
  SELECT COUNT(*) INTO v_class_exists
  FROM classes
  WHERE classid = classid_param;
  
  IF v_class_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('The classid is invalid.');
  ELSE

    FOR student_record IN (
      SELECT s.B#, s.first_name, s.last_name
      FROM students s
      JOIN g_enrollments g ON s.B# = g.g_B#
      WHERE g.classid = classid_param
    )
    LOOP
      DBMS_OUTPUT.PUT_LINE('Student ID: ' || student_record.B#);
      DBMS_OUTPUT.PUT_LINE('First Name: ' || student_record.first_name);
      DBMS_OUTPUT.PUT_LINE('Last Name: ' || student_record.last_name);
      DBMS_OUTPUT.PUT_LINE('----------------------------');
    END LOOP;
  END IF;
END ListStudentsInClass;
/



CREATE OR REPLACE PROCEDURE GetPrerequisites(
  dept_code_param IN VARCHAR2,
  course#_param IN NUMBER
) IS
  v_course_exists NUMBER;
  
 
  CURSOR DirectPrerequisitesCursor IS
    SELECT pre_dept_code, pre_course#
    FROM prerequisites
    WHERE dept_code = dept_code_param
    AND course# = course#_param;


  CURSOR IndirectPrerequisitesCursor(
    ipre_dept_code VARCHAR2,
    ipre_course# NUMBER
  ) IS
    SELECT pre_dept_code, pre_course#
    FROM prerequisites
    WHERE dept_code = ipre_dept_code
    AND course# = ipre_course#;


  v_depth NUMBER := 0;
  

  PROCEDURE GetIndirectPrerequisites(
    ipre_dept_code IN VARCHAR2,
    ipre_course# IN NUMBER
  ) IS
  BEGIN

    v_depth := v_depth + 1;
    

    FOR indirect_prereq IN (
      SELECT pre_dept_code, pre_course#
      FROM prerequisites
      WHERE dept_code = ipre_dept_code
      AND course# = ipre_course#
    )
    LOOP
      
      DBMS_OUTPUT.PUT_LINE(RPAD(' ', v_depth*2, ' ') || indirect_prereq.pre_dept_code || indirect_prereq.pre_course#);
      
      GetIndirectPrerequisites(indirect_prereq.pre_dept_code, indirect_prereq.pre_course#);
    END LOOP;
    
 
    v_depth := v_depth - 1;
  END GetIndirectPrerequisites;

BEGIN

  SELECT COUNT(*) INTO v_course_exists
  FROM courses
  WHERE dept_code = dept_code_param
  AND course# = course#_param;
  
  IF v_course_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE(dept_code_param || course#_param || ' does not exist.');
  ELSE
    -- Display direct prerequisites
    DBMS_OUTPUT.PUT_LINE('Direct Prerequisites:');
    FOR direct_prereq IN DirectPrerequisitesCursor LOOP
      DBMS_OUTPUT.PUT_LINE(direct_prereq.pre_dept_code || direct_prereq.pre_course#);
      
      -- Call GetIndirectPrerequisites for indirect prerequisites
      GetIndirectPrerequisites(direct_prereq.pre_dept_code, direct_prereq.pre_course#);
    END LOOP;
  END IF;
END GetPrerequisites;
/


CREATE OR REPLACE PROCEDURE EnrollStudentIntoClass(
    g_B#_param IN CHAR,
    classid_param IN CHAR
) IS
    v_student_exists NUMBER;
    v_is_grad_student VARCHAR2(10);
    v_class_exists NUMBER;
    v_class_semester VARCHAR2(20);
    v_class_size NUMBER;
    v_class_limit NUMBER;
    v_student_enrollments NUMBER;
    v_student_semester_classes NUMBER;
BEGIN
    SELECT COUNT(*), st_level
    INTO v_student_exists, v_is_grad_student
    FROM students
    WHERE B# = g_B#_param
      AND st_level IN ('master', 'PhD')
    GROUP BY st_level;

    IF v_student_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid B#: The student does not exist or is not a graduate student.');
    END IF;

    IF v_is_grad_student IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Not a Graduate Student: This student is not a graduate student.');
    END IF;

    SELECT COUNT(*), semester, limit, class_size
    INTO v_class_exists, v_class_semester, v_class_limit, v_class_size
    FROM classes
    WHERE classid = classid_param
    GROUP BY semester, limit, class_size;

    IF v_class_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid Class ID: The specified class does not exist.');
    END IF;

    IF v_class_size >= v_class_limit THEN
        RAISE_APPLICATION_ERROR(-20005, 'Class Full: The class is already full.');
    END IF;

    SELECT COUNT(*)
    INTO v_student_enrollments
    FROM g_enrollments
    WHERE g_B# = g_B#_param
      AND classid = classid_param;

    IF v_student_enrollments > 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Already Enrolled: The student is already enrolled in this class.');
    END IF;

    SELECT COUNT(*)
    INTO v_student_semester_classes
    FROM g_enrollments ge
    JOIN classes c ON ge.classid = c.classid
    WHERE ge.g_B# = g_B#_param
      -- Remove the 'Spring 2021' semester condition
      AND c.year = EXTRACT(YEAR FROM SYSDATE)
    GROUP BY ge.g_B#;

    IF v_student_semester_classes >= 5 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Exceeded Limit: Students cannot be enrolled in more than five classes in a semester.');
    END IF;

    -- If all checks pass, proceed with enrollment
    INSERT INTO g_enrollments (g_B#, classid)
    VALUES (g_B#_param, classid_param);

    DBMS_OUTPUT.PUT_LINE('Enrollment successful.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END EnrollStudentIntoClass;
/

CREATE OR REPLACE PROCEDURE DropStudentFromClass(
    g_B#_param IN CHAR,
    classid_param IN CHAR
) IS
    v_student_exists NUMBER;
    v_is_grad_student VARCHAR2(10);
    v_class_exists NUMBER;
    v_student_enrolled NUMBER;
    v_other_classes NUMBER;
BEGIN
    -- Check if the student exists and is a graduate student
    SELECT COUNT(*), st_level
    INTO v_student_exists, v_is_grad_student
    FROM students
    WHERE B# = g_B#_param
      AND st_level IN ('master', 'PhD')
    GROUP BY st_level;

    IF v_student_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid B#: The student does not exist or is not a graduate student.');
        RETURN;
    END IF;

    IF v_is_grad_student IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Not a Graduate Student: This student is not a graduate student.');
        RETURN;
    END IF;

    -- Check if the class exists
    SELECT COUNT(*)
    INTO v_class_exists
    FROM classes
    WHERE classid = classid_param;

    IF v_class_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid Class ID: The specified class does not exist.');
        RETURN;
    END IF;

    -- Check if the student is enrolled in the class
    SELECT COUNT(*)
    INTO v_student_enrolled
    FROM g_enrollments
    WHERE g_B# = g_B#_param
      AND classid = classid_param;

    IF v_student_enrolled = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Not Enrolled: The student is not enrolled in this class.');
        RETURN;
    END IF;

    -- Check if the student is enrolled in other classes for the current semester
    SELECT COUNT(*)
    INTO v_other_classes
    FROM g_enrollments ge
    WHERE ge.g_B# = g_B#_param
      AND ge.classid <> classid_param;

    IF v_other_classes = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Cannot Drop: This is the only class for this student in the current semester.');
        RETURN;
    END IF;

    -- Remove the student from the class
    DELETE FROM g_enrollments
    WHERE g_B# = g_B#_param
      AND classid = classid_param;

    DBMS_OUTPUT.PUT_LINE('Student dropped from the class successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred while dropping the student from the class.');
END DropStudentFromClass;
/


CREATE OR REPLACE PROCEDURE DeleteStudent(
    B#_param IN CHAR
) IS
BEGIN
    
    DELETE FROM students
    WHERE B# = B#_param;

    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('The B# is invalid.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Student deleted successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END DeleteStudent;
/
CREATE OR REPLACE TRIGGER DeleteEnrollmentsOnStudentDelete
BEFORE DELETE ON students
FOR EACH ROW
BEGIN
    DELETE FROM g_enrollments
    WHERE g_B# = :OLD.B#;
END;
/


CREATE OR REPLACE TRIGGER LogStudentDeletion
AFTER DELETE ON students
FOR EACH ROW
BEGIN
    INSERT INTO logs (log#, user_name, op_time, table_name, operation, tuple_keyvalue)
    VALUES (
        log_sequence.NEXTVAL, USER, SYSDATE, 'Students', 'DELETE', :OLD.B#
    );
END;
/



CREATE OR REPLACE TRIGGER LogEnrollment
AFTER INSERT ON g_enrollments
FOR EACH ROW
BEGIN
    INSERT INTO logs (log#, user_name, op_time, table_name, operation, tuple_keyvalue)
    VALUES (
        log_sequence.NEXTVAL, USER, SYSDATE, 'G_Enrollments', 'INSERT', :NEW.g_B# || ',' || :NEW.classid
    );
END;
/


CREATE OR REPLACE TRIGGER LogDrop
AFTER DELETE ON g_enrollments
FOR EACH ROW
BEGIN
    INSERT INTO logs (log#, user_name, op_time, table_name, operation, tuple_keyvalue)
    VALUES (
        log_sequence.NEXTVAL, USER, SYSDATE, 'G_Enrollments', 'DELETE', :OLD.g_B# || ',' || :OLD.classid
    );
END;
/